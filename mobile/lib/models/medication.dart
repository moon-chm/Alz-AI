import 'package:isar/isar.dart';

part 'medication.g.dart';

@Collection()
class Medication {
  Medication();

  Id isarId = Isar.autoIncrement;
  late String id;
  late String name;
  late String dosage;
  late List<String> scheduledTimes;
  String? tabletPhotoUrl;
  late bool isActive;
  late String patientId;
  late bool isTaken;
  
  bool isDueNow() {
    final now = DateTime.now();
    for (var timeStr in scheduledTimes) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final scheduledHour = int.tryParse(parts[0]) ?? 0;
        final scheduledMin = int.tryParse(parts[1]) ?? 0;
        final diff = (now.hour * 60 + now.minute) - (scheduledHour * 60 + scheduledMin);
        if (diff.abs() <= 30) {
          return true;
        }
      }
    }
    return false;
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication()
      ..id = json['id'] ?? ''
      ..name = json['name'] ?? ''
      ..dosage = json['dosage'] ?? ''
      ..scheduledTimes = List<String>.from(json['scheduled_times'] ?? [])
      ..tabletPhotoUrl = json['tablet_photo_url']
      ..isActive = json['is_active'] ?? true
      ..patientId = json['patient_id'] ?? ''
      ..isTaken = false;
  }
}

class MedicationComplianceDay {
  final String date;
  final bool taken;
  final bool scheduled;

  MedicationComplianceDay({
    required this.date,
    required this.taken,
    required this.scheduled,
  });

  factory MedicationComplianceDay.fromJson(Map<String, dynamic> json) {
    return MedicationComplianceDay(
      date: json['date'] ?? '',
      taken: json['taken'] ?? false,
      scheduled: json['scheduled'] ?? false,
    );
  }
}
