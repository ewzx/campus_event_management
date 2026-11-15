import 'package:flutter/material.dart';
import 'staff_check_in_page.dart';

class CheckinDashboardPage extends StatefulWidget {
  const CheckinDashboardPage({super.key});

  @override
  State<CheckinDashboardPage> createState() => _CheckinDashboardPageState();
}

class _CheckinDashboardPageState extends State<CheckinDashboardPage> {
  int _currentIndex = 0;

  // Hardcoded event ID for now. In the future, pass this from the previous screen.
  final String currentEventId = "abPuMLrLE1qZa6CHOzPk";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Staff Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 1: Scan Mode
          StaffCheckInPage(eventId: currentEventId, isScanMode: true),
          // Tab 2: Search / List Mode
          StaffCheckInPage(eventId: currentEventId, isScanMode: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search List'),
        ],
      ),
    );
  }
}