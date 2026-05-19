class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login               = '/api/auth/login/';
  static const logout              = '/api/auth/logout/';
  static const refresh             = '/api/auth/refresh/';
  static const me                  = '/api/auth/me/';
  static const biometricEnable     = '/api/auth/biometric/enable/';
  static const biometricDisable    = '/api/auth/biometric/disable/';
  static const biometricLogin      = '/api/auth/biometric/login/';
  static const onboardingComplete  = '/api/auth/onboarding/complete/';

  // Users
  static const users         = '/api/users/';
  static const inviteUser    = '/api/users/invite/';
  static const verifyInvite  = '/api/users/invite/verify/';
  static const acceptInvite  = '/api/users/accept-invite/';
  static String userDetail(String id) => '/api/users/$id/';

  // Areas
  static const areas                    = '/api/areas/';
  static String areaDetail(String id)   => '/api/areas/$id/';
  static String areaMembers(String id)  => '/api/areas/$id/members/';

  // Activities
  static const activities                                         = '/api/activities/';
  static String activityDetail(String id)                        => '/api/activities/$id/';
  static String activityMove(String id)                          => '/api/activities/$id/move/';
  static String activityComplete(String id)                      => '/api/activities/$id/complete/';
  static String activityAssign(String id)                        => '/api/activities/$id/assign/';
  static String activityLogs(String id)                          => '/api/activities/$id/logs/';
  static String attachments(String id)                           => '/api/activities/$id/attachments/';
  static String attachmentDelete(String actId, String attId)     =>
      '/api/activities/$actId/attachments/$attId/';

  // Projects
  static const projects                         = '/api/projects/';
  static String projectDetail(String id)        => '/api/projects/$id/';
  static String projectActivities(String id)    => '/api/projects/$id/activities/';
  static String projectProgress(String id)      => '/api/projects/$id/progress/';

  // Stats
  static const statsPersonal  = '/api/stats/personal/';
  static const statsGlobal    = '/api/stats/global/';
  static const statsWorkers   = '/api/stats/workers/';
  static const statsDrilldown = '/api/stats/drilldown/';
  static String statsArea(String areaId) => '/api/stats/area/$areaId/';
}
