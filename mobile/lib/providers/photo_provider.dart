import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/photo_service.dart';
import 'package:mobile/models/photo.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class PhotoState {
  final List<FamilyPhoto> photos;
  final bool isLoading;
  final int page;
  final bool hasMore;
  
  const PhotoState({
    this.photos = const [],
    this.isLoading = false,
    this.page = 1,
    this.hasMore = true,
  });
  
  PhotoState copyWith({
    List<FamilyPhoto>? photos,
    bool? isLoading,
    int? page,
    bool? hasMore,
  }) {
    return PhotoState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PhotoNotifier extends StateNotifier<PhotoState> {
  final PhotoService _photoService;
  final String? _patientId;
  
  PhotoNotifier(this._photoService, this._patientId) : super(const PhotoState()) {
    if (_patientId != null) {
      loadInitial();
    }
  }
  
  Future<void> loadInitial() async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true);
    final newPhotos = await _photoService.fetchFamilyPhotos(_patientId, page: 1);
    state = state.copyWith(
      photos: newPhotos,
      page: 1,
      isLoading: false,
      hasMore: newPhotos.length == 12, // Assume page limit 12
    );
  }
  
  Future<void> loadMore() async {
    if (_patientId == null || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final next_page = state.page + 1;
    final newPhotos = await _photoService.fetchFamilyPhotos(_patientId, page: next_page);
    state = state.copyWith(
      photos: [...state.photos, ...newPhotos],
      page: next_page,
      isLoading: false,
      hasMore: newPhotos.isNotEmpty,
    );
  }
  
  void appendPhoto(FamilyPhoto photo) {
    state = state.copyWith(photos: [photo, ...state.photos]);
  }
}

final photoServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return PhotoService(api);
});

final photoProvider = StateNotifierProvider<PhotoNotifier, PhotoState>((ref) {
  final service = ref.watch(photoServiceProvider);
  final patientId = ref.watch(authProvider).identifier;
  return PhotoNotifier(service, patientId ?? '');
});
