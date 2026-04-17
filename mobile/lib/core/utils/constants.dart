class Constants {
  static const int sosHoldDurationMs = 3000;
  static const int minTapTargetSize = 56;
  static const double baseFontSize = 22.0;

  static const String authTokenKey = 'auth_token';
  static const String patientIdKey = 'patient_id';
  
  static const Map<String, String> defaultMoods = {
    'neutral': '😊',
    'happy': '😃',
    'calm': '😌',
    'concerned': '🥺',
    'alert': '🚨',
  };
}
