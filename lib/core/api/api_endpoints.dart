class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login               = '/auth/login/';
  static const logout              = '/auth/logout/';
  static const refresh             = '/auth/refresh/';
  static const me                  = '/auth/me/';
  static const biometricEnable     = '/auth/biometric/enable/';
  static const biometricDisable    = '/auth/biometric/disable/';
  static const biometricLogin      = '/auth/biometric/login/';
  static const onboardingComplete  = '/auth/onboarding/complete/';

  // Users
  static const users       = '/users/';
  static const inviteUser  = '/users/invite/';
  static const acceptInvite = '/users/accept-invite/';
  static String userDetail(String id) => '/users/$id/';

  // Areas
  static const areas                    = '/areas/';
  static String areaDetail(String id)   => '/areas/$id/';
  static String areaMembers(String id)  => '/areas/$id/members/';

  // Activities
  static const activities                                         = '/activities/';
  static String activityDetail(String id)                        => '/activities/$id/';
  static String activityMove(String id)                          => '/activities/$id/move/';
  static String activityComplete(String id)                      => '/activities/$id/complete/';
  static String activityAssign(String id)                        => '/activities/$id/assign/';
  static String activityLogs(String id)                          => '/activities/$id/logs/';
  static String attachments(String id)                           => '/activities/$id/attachments/';
  static String attachmentDelete(String actId, String attId)     =>
      '/activities/$actId/attachments/$attId/';

  // Projects
  static const projects                         = '/projects/';
  static String projectDetail(String id)        => '/projects/$id/';
  static String projectActivities(String id)    => '/projects/$id/activities/';
  static String projectProgress(String id)      => '/projects/$id/progress/';

  // Stats
  static const statsPersonal  = '/stats/personal/';
  static const statsDrilldown = '/stats/drilldown/';
  static String statsArea(String areaId) => '/stats/area/$areaId/';
}
