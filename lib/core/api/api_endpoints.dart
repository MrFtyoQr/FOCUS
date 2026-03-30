class ApiEndpoints {
  ApiEndpoints._();

  static const login        = '/auth/login/';
  static const refresh      = '/auth/refresh/';
  static const logout       = '/auth/logout/';
  static const me           = '/auth/me/';
  static const inviteSend   = '/auth/invitations/send/';
  static const inviteAccept = '/auth/invitations/accept/';
  static String inviteValidate(String token) => '/auth/invitations/$token/';

  static const users              = '/users/';
  static String userDetail(int id) => '/users/$id/';

  static const areas              = '/areas/';
  static String areaMembers(int id) => '/areas/$id/members/';

  static const activities            = '/activities/';
  static String activityDetail(int id)  => '/activities/$id/';
  static String activityMove(int id)    => '/activities/$id/move/';
  static String activityComplete(int id)=> '/activities/$id/complete/';
  static String activityAssign(int id)  => '/activities/$id/assign/';

  static const projects               = '/projects/';
  static String projectDetail(int id)  => '/projects/$id/';

  static const statsMe   = '/stats/me/';
  static const statsArea = '/stats/area/';
  static String statsAreaDetail(int id) => '/stats/area/$id/';
}
