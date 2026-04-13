import 'package:flutter/material.dart';
import 'package:pr/ui/pages/profil.dart';
import 'package:pr/ui/pages/courses_page.dart';
import 'package:pr/ui/pages/exams_page.dart';
import 'package:pr/ui/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const Color _navColor = AppColors.primary;

  final List<Widget> _pages = const [CoursesPage(), ExamsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 105,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.12),
              width: 1,
          ),

        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.selected,
              unselectedItemColor: AppColors.primary,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: 'Kurslar',
                  tooltip: 'Kurslar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.quiz),
                  label: 'Imtihonlar',
                  tooltip: 'Imtihonlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
                  tooltip: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
