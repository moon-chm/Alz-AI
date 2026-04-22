import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_photo.freezed.dart';
part 'family_photo.g.dart';

@freezed
abstract class FamilyPhoto with _$FamilyPhoto {
  const factory FamilyPhoto({
    required String photoUrl,
    required String senderName,
    required String relationship,
    required DateTime sentAt,
    String? narrationText,
  }) = _FamilyPhoto;

  factory FamilyPhoto.fromJson(Map<String, dynamic> json) => _$FamilyPhotoFromJson(json);
}
