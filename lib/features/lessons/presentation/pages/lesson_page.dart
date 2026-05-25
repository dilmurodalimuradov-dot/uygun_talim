import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../shared/legacy/lesson_service_bridge.dart';
import '../../../../shared/legacy/module_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/legacy/test_service_bridge.dart';
import '../../../../shared/legacy/lesson_progress_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.courseId,
    this.title = 'Darslar',
  });

  final String courseId;
  final String title;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final TokenStorageService _tokenStorageService = TokenStorageService();
  final ModuleService _moduleService = ModuleService();
  final LessonService _lessonService = LessonService();
  final TestService _testService = TestService();
  final LessonProgressService _progressService = LessonProgressService();

  bool _isLoading = true;
  bool _isVideoLoading = false;
  String? _errorMessage;
  String? _videoError;
  String? _accessToken;

  double _volume = 0.88;

  List<Module> _modules = const [];
  final Map<String, List<Lesson>> _lessonsByModule = <String, List<Lesson>>{};
  final Set<String> _expandedModuleIds = <String>{};

  Lesson? _selectedLesson;
  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;

  Timer? _hideTimer;
  bool _showPlayPause = true;
  bool _isPausedByTap = false;

  bool _videoEnded = false;
  DateTime? _lastProgressAt;
  bool _isReportingProgress = false;

  AppStrings get _s => AppStrings.read(context);

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposeVideoController();
    super.dispose();
  }

  void _resetTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showPlayPause = false);
    });
  }

  Future<void> _loadCourseContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception(_s.coursesTokenNotFound);
      }

      _testService.setAccessToken(token);

      final modules = await _moduleService.fetchModules(
        token,
        courseId: widget.courseId,
      );

      final lessonsMap = <String, List<Lesson>>{};
      for (final module in modules) {
        // Qulflangan modul darslari yuklanmaydi
        if (!module.isOpened) {
          lessonsMap[module.id] = const [];
          continue;
        }
        try {
          final lessons = await _lessonService.fetchLessons(token, moduleId: module.id);
          lessonsMap[module.id] = lessons;
        } catch (_) {
          lessonsMap[module.id] = const [];
        }
      }

      Module? firstModuleWithLessons;
      for (final module in modules) {
        if (lessonsMap[module.id]?.isNotEmpty == true) {
          firstModuleWithLessons = module;
          break;
        }
      }
      final firstLesson = firstModuleWithLessons == null
          ? null
          : lessonsMap[firstModuleWithLessons.id]!.first;

      if (!mounted) return;
      setState(() {
        _accessToken = token;
        _modules = modules;
        _lessonsByModule
          ..clear()
          ..addAll(lessonsMap);
        _expandedModuleIds
          ..clear()
          ..addAll(
            modules.isNotEmpty
                ? <String>{(firstModuleWithLessons ?? modules.first).id}
                : const <String>{},
          );
        _errorMessage = null;
        _isLoading = false;
      });

      if (firstLesson != null) {
        await _selectLesson(firstLesson, autoplay: false);
      } else {
        if (!mounted) return;
        setState(() {
          _selectedLesson = null;
          _videoError = _s.lessonNotStarted;
        });
        _disposeVideoController();
      }
    } catch (error) {
      _disposeVideoController();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _modules = const [];
        _lessonsByModule.clear();
        _expandedModuleIds.clear();
      });
    }
  }

  Future<void> _selectLesson(Lesson lesson, {required bool autoplay}) async {
    if (!mounted) return;
    setState(() {
      _selectedLesson = lesson;
      _videoError = null;
      _showPlayPause = true;
      _isPausedByTap = false;
      _videoEnded = lesson.isFullyWatched;
      _lastProgressAt = null;
    });
    _resetTimer();
    await _initializeVideo(lesson, autoplay: autoplay);
  }

  Future<void> _initializeVideo(Lesson lesson, {required bool autoplay}) async {
    final url = lesson.videoSource.trim();
    _disposeVideoController();

    if (url.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isVideoLoading = false;
        _videoError = _s.lessonNotStarted;
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _isVideoLoading = false;
        _videoError = _s.errorTryAgain;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isVideoLoading = true;
        _videoError = null;
      });
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: {
        if (_accessToken != null && _accessToken!.isNotEmpty)
          'Authorization': 'Bearer ${_accessToken!}',
        'X-CSRFTOKEN': _lessonService.csrfToken,
      },
    );

    try {
      await controller.initialize();
      await controller.setVolume(_volume);
      if (autoplay) {
        await controller.play();
        setState(() {
          _isPausedByTap = false;
        });
        _resetTimer();
      }

      _videoListener = () {
        if (!mounted) return;
        setState(() {});

        if (!controller.value.isInitialized) return;
        final duration = controller.value.duration;
        if (duration <= Duration.zero) return;
        final position = controller.value.position;
        final atEnd = position >= duration - const Duration(milliseconds: 500);

        // Video o'ynayotganda har 5 soniyada progress yuborish (skip cheklovini aylanib o'tish)
        if (controller.value.isPlaying) {
          final now = DateTime.now();
          if (_lastProgressAt == null ||
              now.difference(_lastProgressAt!) >= const Duration(seconds: 5)) {
            _lastProgressAt = now;
            _reportProgress(
              position: position.inSeconds,
              duration: duration.inSeconds,
            );
          }
        }

        // Video oxiriga yetdi
        if (atEnd && !controller.value.isPlaying && !_videoEnded) {
          setState(() => _videoEnded = true);
          _reportProgress(
            position: duration.inSeconds,
            duration: duration.inSeconds,
          );
        }
      };
      controller.addListener(_videoListener!);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isVideoLoading = false;
        _videoError = null;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isVideoLoading = false;
        _videoError = _s.errorTryAgain;
      });
    }
  }

  void _disposeVideoController() {
    final controller = _videoController;
    if (controller != null && _videoListener != null) {
      controller.removeListener(_videoListener!);
    }
    _videoListener = null;
    _videoController = null;
    controller?.dispose();
  }

  Future<void> _reportProgress({
    required int position,
    required int duration,
  }) async {
    final lesson = _selectedLesson;
    if (lesson == null || _accessToken == null) return;
    if (lesson.isFullyWatched) return;
    if (duration <= 0) return;
    if (_isReportingProgress) return;
    _isReportingProgress = true;

    try {
      final result = await _progressService.updateLessonProgress(
        lessonId: lesson.id,
        accessToken: _accessToken!,
        position: position,
        duration: duration,
      );

      if (result == null || !mounted) return;
      if (result['is_fully_watched'] != true) return;

      // Server "to'liq ko'rilgan" deb tasdiqladi — lokal holatni yangilash
      setState(() {
        final updatedLesson = Lesson(
          id: lesson.id,
          title: lesson.title,
          order: lesson.order,
          description: lesson.description,
          videoSource: lesson.videoSource,
          testId: lesson.testId,
          hasTest: lesson.hasTest,
          isFullyWatched: true,
          isCompleted: lesson.isCompleted,
          testPassed: lesson.testPassed,
        );
        if (_selectedLesson?.id == lesson.id) {
          _selectedLesson = updatedLesson;
        }
        for (final moduleId in _lessonsByModule.keys) {
          final lessons = _lessonsByModule[moduleId];
          if (lessons != null) {
            final index = lessons.indexWhere((l) => l.id == lesson.id);
            if (index != -1) {
              _lessonsByModule[moduleId]?[index] = updatedLesson;
            }
          }
        }
      });
    } finally {
      _isReportingProgress = false;
    }
  }

  Future<void> _togglePlayPause() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
      setState(() {
        _isPausedByTap = true;
        _showPlayPause = true;
      });
      _resetTimer();
    } else {
      await controller.play();
      setState(() {
        _isPausedByTap = false;
        _showPlayPause = true;
      });
      _resetTimer();
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _showPlayPause = true);
    _resetTimer();

    final current = controller.value.position;
    final duration = controller.value.duration;
    final next = current + delta;
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > duration ? duration : next);
    await controller.seekTo(clamped);
    if (mounted) setState(() {});
  }

  Future<void> _setVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    setState(() => _volume = next);
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(next);
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final lessonTitle = _selectedLesson?.title;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LessonFullscreenPage(
          controller: controller,
          title: (lessonTitle != null && lessonTitle.trim().isNotEmpty)
              ? lessonTitle
              : widget.title,
          initialVolume: _volume,
          onVolumeChanged: _setVolume,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF10233E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCourseContent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            children: [
              _buildPlayerCard(),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildInfoBanner(_errorMessage!, isError: true),
                ),
                const SizedBox(height: 12),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildCourseContentCard(s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    final lesson = _selectedLesson;
    final controller = _videoController;
    final isReady = controller != null && controller.value.isInitialized;
    final isPlaying = isReady && controller.value.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: () {
                  if (_isPausedByTap) {
                    _togglePlayPause();
                  } else {
                    setState(() {
                      _showPlayPause = true;
                      _isPausedByTap = true;
                    });
                    _resetTimer();

                    final ctrl = _videoController;
                    if (ctrl != null &&
                        ctrl.value.isInitialized &&
                        ctrl.value.isPlaying) {
                      ctrl.pause();
                    }
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black),
                    if (isReady)
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio == 0
                              ? 16 / 9
                              : controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    if (lesson != null && _showPlayPause)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 10,
                        child: Text(
                          lesson.title.isNotEmpty
                              ? lesson.title
                              : '${lesson.order > 0 ? lesson.order : 1}-dars',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isVideoLoading)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (!_isVideoLoading && _videoError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            _videoError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!_isVideoLoading &&
                        (isReady || _videoError == null) &&
                        _showPlayPause)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFF101827),
                              size: isPlaying ? 38 : 42,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF0E1732), Color(0xFF111A37)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                _buildControlButton(
                  width: 54,
                  label: '10s',
                  icon: Icons.replay_10_rounded,
                  onTap: () => _seekRelative(const Duration(seconds: -10)),
                ),
                const Spacer(),
                _buildIconControl(
                  _volume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  onTap: () => _setVolume(_volume <= 0.01 ? 0.88 : 0),
                ),
                const SizedBox(width: 8),
                _buildVolumeSlider(width: 120, value: _volume, onChanged: _setVolume),
                const SizedBox(width: 8),
                _buildIconControl(
                  Icons.open_in_full_rounded,
                  onTap: _openFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContentCard(AppStrings s) {
    final totalLessons = _lessonsByModule.values.fold<int>(
      0,
          (sum, items) => sum + items.length,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.lessonTitle,
                  style: const TextStyle(
                    color: Color(0xFF10233E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5EAF0)),
                ),
                child: Text(
                  '${s.coursesProgress}${totalLessons > 0 ? ' ($totalLessons)' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else if (_modules.isEmpty)
            _buildInfoBanner(s.lessonNotStarted, isError: false)
          else
            Column(
              children: _modules.map(_buildModuleTile).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(Module module) {
    final s = AppStrings.of(context);
    final order = _modules.indexOf(module) + 1;

    // Qulflangan modul — ochib bo'lmaydi
    if (!module.isOpened) {
      return _buildLockedModuleTile(order);
    }

    final lessons = _lessonsByModule[module.id] ?? const <Lesson>[];
    final isExpanded = _expandedModuleIds.contains(module.id);
    final allWatched = (lessons.isNotEmpty && lessons.every((l) => l.isFullyWatched)) ||
        module.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allWatched ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFFE8EDF2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('module-${module.id}'),
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedModuleIds.add(module.id);
              } else {
                _expandedModuleIds.remove(module.id);
              }
            });
          },
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: allWatched
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            '$order - modul',
            style: const TextStyle(
              color: Color(0xFF10233E),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: lessons.isNotEmpty
              ? Text(
            '${lessons.length} ${s.examsQuestions}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
              : null,
          children: [
            if (lessons.isEmpty)
              _buildInfoBanner(s.lessonNotStarted, isError: false)
            else ...[
              ...lessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                return _buildLessonTile(lesson, fallbackOrder: index + 1);
              }),
              if (allWatched) _buildModuleTestsButton(module, order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockedModuleTile(int order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFE5EAF0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$order - modul',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Avvalgi modulni tugating',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTestsButton(Module module, int order) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: () {
          if (_accessToken != null) {
            _testService.setAccessToken(_accessToken!);
          }
          final lessons = _lessonsByModule[module.id] ?? const <Lesson>[];
          final allowedTestIds = lessons
              .map((l) => l.testId)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet();
          final testIdToPassed = Map.fromEntries(
            lessons
                .where((l) => l.testId != null && l.testId!.isNotEmpty)
                .map((l) => MapEntry(l.testId!, l.testPassed)),
          );
          final testIdToLessonId = Map.fromEntries(
            lessons
                .where((l) => l.testId != null && l.testId!.isNotEmpty)
                .map((l) => MapEntry(l.testId!, l.id)),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ModuleTestsPage(
                moduleId: module.id,
                moduleTitle: '$order-modul testlari',
                testService: _testService,
                allowedTestIds: allowedTestIds,
                testIdToPassed: testIdToPassed,
                testIdToLessonId: testIdToLessonId,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Modul testlarini boshlash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, {required int fallbackOrder}) {
    final isSelected = _selectedLesson?.id == lesson.id;
    final isPlaying = isSelected &&
        _videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.isPlaying;

    return InkWell(
      onTap: () => _selectLesson(lesson, autoplay: false),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F6E9) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFC3ECD0) : const Color(0xFFEAF0F4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: isSelected ? AppColors.primary : const Color(0xFF7A8794),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title.trim().isNotEmpty ? lesson.title.trim() : '$fallbackOrder-dars',
                style: TextStyle(
                  color: const Color(0xFF10233E),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (lesson.isFullyWatched)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    double width = 58,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: width,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A2336),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 1),
              Icon(icon, size: 12, color: const Color(0xFF4B5563)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconControl(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1A2336), size: 18),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required double width,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 26,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 6,
          inactiveTrackColor: const Color(0xFF2B3556),
          activeTrackColor: const Color(0xFF74E1B2),
          thumbColor: const Color(0xFF74E1B2),
          overlayColor: const Color(0xFF74E1B2).withValues(alpha: 0.14),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: value.clamp(0.0, 1.0).toDouble(),
          min: 0,
          max: 1,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text, {required bool isError}) {
    final color = isError ? const Color(0xFFD14343) : const Color(0xFF2C5B88);
    final bg = isError ? const Color(0xFFFFF3F3) : const Color(0xFFF4F8FB);
    final icon = isError ? Icons.error_outline_rounded : Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Fullscreen Page
// ─────────────────────────────────────────────

class _LessonFullscreenPage extends StatefulWidget {
  const _LessonFullscreenPage({
    required this.controller,
    required this.title,
    required this.initialVolume,
    required this.onVolumeChanged,
  });

  final VideoPlayerController controller;
  final String title;
  final double initialVolume;
  final Future<void> Function(double value) onVolumeChanged;

  @override
  State<_LessonFullscreenPage> createState() => _LessonFullscreenPageState();
}

class _LessonFullscreenPageState extends State<_LessonFullscreenPage> {
  late double _volume;
  late final VoidCallback _listener;
  Timer? _hideTimer;
  bool _showControls = true;
  bool _isPausedByTap = false;

  void _resetTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_listener);
    _resetTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_listener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!widget.controller.value.isInitialized) return;

    if (widget.controller.value.isPlaying) {
      await widget.controller.pause();
      setState(() {
        _isPausedByTap = true;
        _showControls = true;
      });
      _resetTimer();
    } else {
      await widget.controller.play();
      setState(() {
        _isPausedByTap = false;
        _showControls = true;
      });
      _resetTimer();
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekRelative(Duration delta) async {
    if (!widget.controller.value.isInitialized) return;
    setState(() => _showControls = true);
    _resetTimer();
    final current = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final target = current + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    await widget.controller.seekTo(clamped);
    if (mounted) setState(() {});
  }

  Future<void> _setVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    setState(() {
      _volume = next;
      _showControls = true;
    });
    _resetTimer();
    await widget.onVolumeChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isReady = controller.value.isInitialized;
    final isPlaying = isReady && controller.value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_isPausedByTap) {
            _togglePlayPause();
          } else {
            setState(() {
              _showControls = true;
              _isPausedByTap = true;
            });
            _resetTimer();

            if (controller.value.isInitialized && controller.value.isPlaying) {
              controller.pause();
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            if (isReady)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio == 0
                      ? 16 / 9
                      : controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            if (_showControls) ...[
              Positioned(
                top: 18,
                left: 18,
                right: 18,
                child: Row(
                  children: [
                    _FsIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: isPlaying ? 38 : 42,
                      color: const Color(0xFF101827),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _FsIconButton(icon: Icons.replay_10_rounded, onTap: () => _seekRelative(const Duration(seconds: -10))),
                          const SizedBox(width: 8),
                          _FsIconButton(
                            icon: _volume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            onTap: () => _setVolume(_volume <= 0.01 ? 0.88 : 0),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                inactiveTrackColor: const Color(0xFF374151),
                                activeTrackColor: const Color(0xFF74E1B2),
                                thumbColor: const Color(0xFF74E1B2),
                                overlayColor: const Color(0xFF74E1B2).withValues(alpha: 0.14),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(value: _volume, min: 0, max: 1, onChanged: _setVolume),
                            ),
                          ),
                          const Spacer(),
                          _FsIconButton(icon: Icons.fullscreen_exit_rounded, onTap: () => Navigator.of(context).pop()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Module Tests Page
// ═══════════════════════════════════════════════════════════════

class _ModuleTestsPage extends StatefulWidget {
  const _ModuleTestsPage({
    required this.moduleId,
    required this.moduleTitle,
    required this.testService,
    required this.allowedTestIds,
    required this.testIdToPassed,
    required this.testIdToLessonId,
  });

  final String moduleId;
  final String moduleTitle;
  final TestService testService;
  final Set<String> allowedTestIds;
  final Map<String, bool> testIdToPassed;
  final Map<String, String> testIdToLessonId;

  @override
  State<_ModuleTestsPage> createState() => _ModuleTestsPageState();
}

class _ModuleTestsPageState extends State<_ModuleTestsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _tests = [];
  final Set<String> _submittedTestIds = {};

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tests = await widget.testService.fetchModuleTestsRaw(widget.moduleId);
      final filtered = widget.allowedTestIds.isEmpty
          ? tests
          : tests
              .where((t) => widget.allowedTestIds.contains((t['id'] ?? '').toString()))
              .toList();

      // Joriy pass status — refresh'da ham server holatini aks ettiradi.
      final passed = await widget.testService.fetchModulePassedStatus(widget.moduleId);

      final submitted = <String>{};
      for (final t in filtered) {
        final id = (t['id'] ?? '').toString();
        if (id.isEmpty) continue;
        if ((passed[id] ?? widget.testIdToPassed[id]) == true) submitted.add(id);
      }

      if (mounted) {
        setState(() {
          _tests = filtered;
          _submittedTestIds.addAll(submitted); // passed doimiy — tozalanmaydi
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF10233E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.moduleTitle,
          style: const TextStyle(
            color: Color(0xFF10233E),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : _tests.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadTests,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _tests.length,
                          itemBuilder: (_, i) => _buildTestCard(_tests[i], i),
                        ),
                      ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, int index) {
    final id = (test['id'] ?? '').toString();
    final title = (test['title'] ?? 'Test ${index + 1}').toString();
    final questions = test['questions'];
    final count = questions is List ? questions.length : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF10233E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$count ta savol',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_submittedTestIds.contains(id))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'Topshirilgan',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else if (count > 0)
              GestureDetector(
                onTap: () async {
                  final submitted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => _TestQuizPage(
                        testId: id,
                        testTitle: title,
                        testService: widget.testService,
                        preloadedData: test,
                        lessonId: widget.testIdToLessonId[id],
                      ),
                    ),
                  );
                  if (submitted == true && mounted) {
                    setState(() => _submittedTestIds.add(id));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Boshlash',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mavjud emas',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFD14343)),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Testlar topilmadi',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _FsIconButton extends StatelessWidget {
  const _FsIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Test Quiz Page
// ═══════════════════════════════════════════════════════════════

class _TestQuizPage extends StatefulWidget {
  const _TestQuizPage({
    required this.testId,
    required this.testTitle,
    required this.testService,
    this.preloadedData,
    this.lessonId,
  });

  final String testId;
  final String testTitle;
  final TestService testService;
  final Map<String, dynamic>? preloadedData;
  final String? lessonId;

  @override
  State<_TestQuizPage> createState() => _TestQuizPageState();
}

class _TestQuizPageState extends State<_TestQuizPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, String> _selectedAnswers = {};
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;
  String? _attemptId;

  bool get _isPassed =>
      _result?['passed'] == true || _result?['is_passed'] == true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // start: POST /tests/{test_id}/start/ — body'da dars obyekti, javobda attempt_id.
      Map<String, dynamic>? data;
      try {
        if (widget.lessonId != null && widget.lessonId!.isNotEmpty) {
          final lessonBody = await widget.testService.fetchLesson(widget.lessonId!);
          data = await widget.testService.startTestRaw(widget.testId, lessonBody);
        } else {
          data = await widget.testService.startTest(widget.testId);
        }
      } catch (_) {
        try {
          data = await widget.testService.fetchTest(widget.testId);
        } catch (_) {
          data = null;
        }
      }

      final attemptId = data?['attempt_id']?.toString();

      var questions = data != null
          ? _extractQuestions(data)
          : <Map<String, dynamic>>[];

      if (questions.isEmpty && widget.preloadedData != null) {
        questions = _extractQuestions(widget.preloadedData!);
      }

      if (mounted) {
        setState(() {
          _attemptId = attemptId;
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractQuestions(Map<String, dynamic> data) {
    final raw = data['questions'] ?? data['question_list'] ?? data['items'] ?? [];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  String _qId(Map<String, dynamic> q) => (q['id'] ?? q['question_id'] ?? '').toString();
  String _qText(Map<String, dynamic> q, int idx) => (q['text'] ?? q['question'] ?? q['title'] ?? 'Savol ${idx + 1}').toString();
  List<Map<String, dynamic>> _options(Map<String, dynamic> q) {
    final raw = q['options'] ?? q['answers'] ?? q['choices'] ?? [];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }
  String _optId(Map<String, dynamic> opt, int idx) => (opt['id'] ?? opt['option_id'] ?? idx).toString();
  String _optText(Map<String, dynamic> opt, int idx) => (opt['text'] ?? opt['label'] ?? opt['value'] ?? 'Variant ${idx + 1}').toString();

  Future<void> _submit() async {
    if (_selectedAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, barcha savollarga javob bering'), backgroundColor: Color(0xFFD14343)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await widget.testService.submitTest(widget.testId, {
        if (_attemptId != null && _attemptId!.isNotEmpty) 'attempt_id': _attemptId,
        'answers': Map<String, String>.from(_selectedAnswers),
      });
      if (!mounted) return;
      setState(() {
        _result = result;
        _isSubmitting = false;
      });
      // Urinishlar tugasa is_fully_watched reset'ini backend bajaradi.
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD14343),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF10233E)),
          onPressed: () => Navigator.of(context).pop(_isPassed),
        ),
        title: Text(
          widget.testTitle.isNotEmpty ? widget.testTitle : 'Test',
          style: const TextStyle(color: Color(0xFF10233E), fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _result != null
            ? _buildResult()
            : _buildQuiz(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFD14343)),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Savollar topilmadi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
          ],
        ),
      );
    }

    final answered = _selectedAnswers.length;
    final total = _questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$answered / $total ta javob berildi', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${(answered / total * 100).round()}%', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: answered / total,
                backgroundColor: const Color(0xFFE5EAF0),
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 5,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: _questions.length,
            itemBuilder: (_, i) => _buildQuestion(_questions[i], i),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE5EAF0))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Testni yakunlash', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(Map<String, dynamic> q, int idx) {
    final qId = _qId(q);
    final qText = _qText(q, idx);
    final opts = _options(q);
    final selected = _selectedAnswers[qId];
    final isAnswered = selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAnswered ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFE5EAF0),
          width: isAnswered ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isAnswered ? AppColors.primary : const Color(0xFFE5EAF0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAnswered
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(qText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10233E), height: 1.4)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5EAF0)),
          if (opts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Variantlar topilmadi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            )
          else
            ...opts.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              final optId = _optId(opt, i);
              final optText = _optText(opt, i);
              final isSelected = selected == optId;
              final isLast = i == opts.length - 1;

              return InkWell(
                onTap: () {
                  setState(() => _selectedAnswers[qId] = optId);
                },
                borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(14)) : BorderRadius.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
                    border: const Border(top: BorderSide(color: Color(0xFFEFF3F7))),
                    borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(14)) : BorderRadius.zero,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1), width: 2),
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final isPassed = _isPassed;
    final attemptsLeft = int.tryParse(
      (r['attempts_left'] ?? r['attemptsLeft'] ?? '').toString(),
    );
    final noAttemptsLeft =
        !isPassed && attemptsLeft != null && attemptsLeft <= 0;
    final canRetry =
        !isPassed && (attemptsLeft == null || attemptsLeft > 0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isPassed ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
              ),
              child: Icon(
                isPassed
                    ? Icons.emoji_events_rounded
                    : (noAttemptsLeft ? Icons.lock_clock_rounded : Icons.replay_rounded),
                size: 56,
                color: isPassed ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPassed ? 'Tabriklaymiz! 🎉' : 'Qayta urinib ko\'ring',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isPassed ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 10),
            if (isPassed)
              const Text(
                'Test muvaffaqiyatli topshirildi',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              )
            else if (noAttemptsLeft)
              const Text(
                'Urinishlar tugadi. Darsni qaytadan ko\'rib chiqishingiz kerak.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
              )
            else if (attemptsLeft != null)
              Text(
                'Qolgan urinishlar: $attemptsLeft',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(isPassed),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Darsga qaytish'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (canRetry) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _result = null;
                          _attemptId = null;
                          _selectedAnswers.clear();
                        });
                        _loadQuestions();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Qayta boshlash'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}