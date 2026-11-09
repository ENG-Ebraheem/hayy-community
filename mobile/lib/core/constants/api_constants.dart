class ApiConstants {
  static const String configuredBaseUrl = String.fromEnvironment('HAYY_API_BASE_URL');
  static const String androidBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';

  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    return defaultBaseUrl;
  }

  static const String tasks = '/tasks';
  static const String ratings = '/ratings';
  
  static String taskDetails(int id) => '/tasks/$id';
  static String volunteerTask(int id) => '/tasks/$id/volunteer';
  static String acceptVolunteer(int id) => '/tasks/$id/accept-volunteer';
  static String updateTaskStatus(int id) => '/tasks/$id/status';
  static String userRatings(String uid) => '/users/$uid/ratings';
}
