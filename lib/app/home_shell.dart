import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timehunter/app/providers.dart';
import 'package:timehunter/features/calendar/calendar_page.dart';
import 'package:timehunter/features/today/today_page.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    TodayPage(),
    CalendarPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '今天',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日曆',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(navIndexProvider.notifier).state = index,
      ),
    );
  }
}
