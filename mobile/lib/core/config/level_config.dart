class LevelConfig {
  static String getDescription(int level) {
    switch (level) {
      case 1: return 'Early Stage';
      case 2: return 'Moderate Stage';
      case 3: return 'Severe Stage';
      default: return 'Unknown';
    }
  }
  
  static bool showFamilyGrid(int level) => level <= 2;
  static bool showPhotoFeed(int level) => level <= 2;
  static double fontSizeMultiplier(int level) => level == 3 ? 1.3 : 1.0;
}
