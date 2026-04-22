import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/providers/level_provider.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/features/patient/home/screens/patient_home_screen.dart';
import 'package:alz_ai/features/patient/medicines/screens/medicines_screen.dart';
import 'package:alz_ai/features/patient/vitals/screens/vitals_screen.dart';
import 'package:alz_ai/features/patient/family/screens/family_screen.dart';
import 'package:alz_ai/features/patient/help/screens/help_screen.dart';
import 'dart:async';
import 'package:alz_ai/core/services/background_service.dart';
import 'package:alz_ai/core/services/vitals_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TabNavigationShell extends ConsumerStatefulWidget {
  const TabNavigationShell({super.key});

  @override
  ConsumerState<TabNavigationShell> createState() => _TabNavigationShellState();
}

class _TabNavigationShellState extends ConsumerState<TabNavigationShell> {
  int _selectedIndex = 0;
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _handleLevelAwarePermissions();
  }

  Future<void> _handleLevelAwarePermissions() async {
    if (_permissionsChecked) return;
    
    final level = ref.read(patientLevelProvider);
    if (level == 3) {
      await _requestInitialPermissions();
    }
    setState(() => _permissionsChecked = true);
  }

  Future<void> _requestInitialPermissions() async {
    final vitals = VitalsService();
    final hasHealth = await vitals.hasPermissions();
    final statusLocation = await Permission.location.status;

    await BackgroundServiceInstance.initialize(
      hasHealthPermissions: hasHealth,
      hasLocationPermissions: statusLocation.isGranted,
    );
  }

  void _onItemTapped(int index, int vitalsIndex) async {
    if (index == vitalsIndex) {
      final vitals = VitalsService();
      final authorized = await vitals.requestPermissions();
      if (authorized) {
        final status = await Permission.location.request();
        await BackgroundServiceInstance.initialize(
          hasHealthPermissions: true,
          hasLocationPermissions: status.isGranted,
        );
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(patientLevelProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': {'home': 'Home', 'meds': 'Meds', 'vitals': 'Vitals', 'family': 'Family', 'help': 'Help'},
      'hi': {'home': 'होम', 'meds': 'दवाई', 'vitals': 'सेहत', 'family': 'परिवार', 'help': 'मदद'},
      'mr': {'home': 'होम', 'meds': 'औषधे', 'vitals': 'प्रकृती', 'family': 'कुटुंब', 'help': 'मदत'},
    }[lang] ?? {'home': 'Home', 'meds': 'Meds', 'vitals': 'Vitals', 'family': 'Family', 'help': 'Help'};

    final List<Widget> screens = [
      const PatientHomeScreen(),
      const MedicinesScreen(),
      const VitalsScreen(),
      if (level < 3) const FamilyScreen(),
      const HelpScreen(),
    ];

    final vitalsIndex = 2; // Fixed index for vitals tab

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => _onItemTapped(index, vitalsIndex),
          items: [
            _buildNavItem(Icons.home, labels['home']!, 0),
            _buildNavItem(Icons.medication, labels['meds']!, 1),
            _buildNavItem(Icons.monitor_heart_outlined, labels['vitals']!, 2),
            if (level < 3) _buildNavItem(Icons.people, labels['family']!, 3),
            _buildNavItem(Icons.help_outline, labels['help']!, level < 3 ? 4 : 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Semantics(
        label: label,
        selected: _selectedIndex == index,
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
