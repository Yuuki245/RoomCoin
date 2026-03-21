import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../expense/screens/expense_calendar_screen.dart';
import '../../expense/screens/add_expense_screen.dart';
import '../../room/screens/room_settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với từng tab
  final List<Widget> _screens = [
    const ExpenseCalendarScreen(), // Tab 1: Lịch (Trang chủ)
    const Center(
      child: Text('Báo cáo', style: TextStyle(fontSize: 24)),
    ), // Tab 2: Báo cáo
    const Center(
      child: Text('AI Chat', style: TextStyle(fontSize: 24)),
    ), // Tab 3: AI Chat
    const RoomSettingsScreen(), // Tab 4: Cài đặt phòng
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddExpenseScreen());
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
