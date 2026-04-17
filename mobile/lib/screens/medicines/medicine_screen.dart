import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/medication_provider.dart';
import 'package:mobile/core/widgets/medication_card.dart';

class MedicineScreen extends ConsumerWidget {
  const MedicineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Medicines', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(medicationProvider.notifier).fetchMedications(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              "${now.day}/${now.month}/${now.year}", 
              style: const TextStyle(fontSize: 24, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.medications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No medicines scheduled for today ✓', 
                    style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...state.medications.map((m) => MedicationCard(
                medication: m,
                onConfirmTaken: () => ref.read(medicationProvider.notifier).confirmTaken(m.id),
              )),
          ],
        ),
      ),
    );
  }
}
