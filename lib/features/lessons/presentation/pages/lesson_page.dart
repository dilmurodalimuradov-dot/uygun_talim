import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/legacy/lesson_service_bridge.dart';
import '../../../../shared/legacy/module_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:video_player/video_player.dart';

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

  /// Event handler va async metodlar uchun — listen: false
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

      final modules = await _moduleService.fetchModules(
        token,
        courseId: widget.courseId,
      );

      final lessonsMap = <String, List<Lesson>>{};
      for (final module in modules) {
        try {
          final lessons =
          await _lessonService.fetchLessons(token, moduleId: module.id);
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
        if (mounted) setState(() {});
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
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
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
                          padding:
                          const EdgeInsets.symmetric(horizontal: 18),
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
                                  color:
                                  Colors.black.withValues(alpha: 0.25),
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(16)),
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
                  onTap: () =>
                      _seekRelative(const Duration(seconds: -10)),
                ),
                const Spacer(),
                _buildIconControl(
                  _volume <= 0.01
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  onTap: () =>
                      _setVolume(_volume <= 0.01 ? 0.88 : 0),
                ),
                const SizedBox(width: 8),
                _buildVolumeSlider(
                    width: 120, value: _volume, onChanged: _setVolume),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
                  child:
                  CircularProgressIndicator(strokeWidth: 2.4),
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
    final lessons = _lessonsByModule[module.id] ?? const <Lesson>[];
    final isExpanded = _expandedModuleIds.contains(module.id);
    final order = _modules.indexOf(module) + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('module-${module.id}'),
          initiallyExpanded: isExpanded,
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding:
          const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
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
            else
              ...lessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                return _buildLessonTile(lesson,
                    fallbackOrder: index + 1);
              }),
          ],
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
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE3F6E9)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC3ECD0)
                : const Color(0xFFEAF0F4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFF7A8794),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title.trim().isNotEmpty
                    ? lesson.title.trim()
                    : '$fallbackOrder-dars',
                style: TextStyle(
                  color: const Color(0xFF10233E),
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 18,
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
          overlayColor:
          const Color(0xFF74E1B2).withValues(alpha: 0.14),
          thumbShape:
          const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape:
          const RoundSliderOverlayShape(overlayRadius: 12),
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
    final color = isError
        ? const Color(0xFFD14343)
        : const Color(0xFF2C5B88);
    final bg = isError
        ? const Color(0xFFFFF3F3)
        : const Color(0xFFF4F8FB);
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
// Fullscreen page
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
  State<_LessonFullscreenPage> createState() =>
      _LessonFullscreenPageState();
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
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
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

            if (controller.value.isInitialized &&
                controller.value.isPlaying) {
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
                          shadows: [
                            Shadow(
                                color: Colors.black54, blurRadius: 8),
                          ],
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
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                        Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      _FsIconButton(
                        icon: Icons.replay_10_rounded,
                        onTap: () => _seekRelative(
                            const Duration(seconds: -10)),
                      ),
                      const SizedBox(width: 8),
                      _FsIconButton(
                        icon: _volume <= 0.01
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: () =>
                            _setVolume(_volume <= 0.01 ? 0.88 : 0),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            inactiveTrackColor:
                            const Color(0xFF374151),
                            activeTrackColor:
                            const Color(0xFF74E1B2),
                            thumbColor: const Color(0xFF74E1B2),
                            overlayColor: const Color(0xFF74E1B2)
                                .withValues(alpha: 0.14),
                            thumbShape:
                            const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape:
                            const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _volume,
                            min: 0,
                            max: 1,
                            onChanged: _setVolume,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _FsIconButton(
                        icon: Icons.fullscreen_exit_rounded,
                        onTap: () => Navigator.of(context).pop(),
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