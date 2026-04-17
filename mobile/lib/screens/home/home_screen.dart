import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/photo_provider.dart';
import 'package:mobile/core/widgets/saathi_card.dart';
import 'package:mobile/core/widgets/sos_button.dart';
import 'package:mobile/core/widgets/medication_card.dart';
import 'package:mobile/core/widgets/photo_feed_card.dart';
import 'package:mobile/core/widgets/watch_status.dart';
import 'package:mobile/core/widgets/vitals_chip.dart';
import 'package:mobile/core/widgets/vitals_chart_card.dart';
import '../../core/widgets/motions.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/location_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final vitalsState = ref.watch(vitalsProvider);
    final isTracking = ref.watch(locationControllerProvider);
    final medicationState = ref.watch(medicationProvider);
    final photoState = ref.watch(photoProvider);
    
    final preferredName = patientState.patient?.preferredName ?? 'Friend';
    final now = DateTime.now();
    final dateStr = "${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Section
            SlideUp(
              staggerIndex: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning, $preferredName!', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dateStr, style: const TextStyle(fontSize: 22, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 2. Saathi Card
                  SlideUp(
                    staggerIndex: 1,
                    child: ScaleTap(
                      onTap: () => context.push(conversationRoute),
                      child: SAATHICard(onTap: () => context.push(conversationRoute)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 3. Live Vitals Section
                  SlideUp(
                    staggerIndex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Vitals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const VitalsChartCard(),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              VitalsChip(
                                icon: '💧', 
                                label: 'SpO2', 
                                value: vitalsState.spo2 > 0 ? vitalsState.spo2.toString() : '--', 
                                unit: '%',
                              ),
                              const SizedBox(width: 12),
                              VitalsChip(
                                icon: '👣', 
                                label: 'Steps', 
                                value: vitalsState.steps.toString(), 
                                unit: 'steps',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. Location Status Card
                  SlideUp(
                    staggerIndex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location Status', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: WatchStatus(isConnected: isTracking),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Family Photos
                  SlideUp(
                    staggerIndex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Family Photos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => context.push(familyRoute),
                          child: const Text('See all photos →', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (photoState.photos.isNotEmpty)
                    ...photoState.photos.take(3).indexed.map((entry) => SlideUp(
                        staggerIndex: 5,
                        child: ScaleTap(
                          onTap: () => context.push(photoCollectionRoute, extra: {'name': entry.$2.senderName}),
                          child: PhotoFeedCard(photo: entry.$2, onTap: () {}),
                        ),
                      ))
                  else
                    const SlideUp(
                      staggerIndex: 5,
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No photos yet', style: TextStyle(fontSize: 22, color: Colors.grey)),
                      )),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Today's Medicines
                  SlideUp(
                    staggerIndex: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's Medicines", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => context.push(medicineRoute),
                          child: const Text('All medicines →', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (medicationState.medications.isNotEmpty)
                    ...medicationState.medications.take(2).indexed.map((entry) => SlideUp(
                        staggerIndex: 7,
                        child: ScaleTap(
                          child: MedicationCard(
                            medication: entry.$2,
                            onConfirmTaken: () => ref.read(medicationProvider.notifier).confirmTaken(entry.$2.id),
                          ),
                        ),
                      ))
                  else
                    const SlideUp(
                      staggerIndex: 7,
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No medicines due ✓', style: TextStyle(fontSize: 22, color: Colors.green)),
                      )),
                    ),
                    
                  const SizedBox(height: 80), // Space for SOS button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeIn(
                delay: const Duration(milliseconds: 600), // Enforce delay until structure builds
                child: const SOSButton(),
              ),
              const SizedBox(height: 12),
              const Text('Hold 3 seconds for emergency', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
