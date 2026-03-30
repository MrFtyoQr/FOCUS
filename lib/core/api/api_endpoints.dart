class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login          = '/auth/login/';
  static const refresh        = '/auth/refresh/';
  static const logout         = '/auth/logout/';
  static const me             = '/auth/me/';
  static const inviteSend     = '/auth/invitations/send/';
  static const inviteAccept   = '/auth/invitations/accept/';
  static String inviteValidate(String token)  => '/auth/invitations/$token/';
  static String inviteRegenerate(int id)      => '/auth/invitations/$id/regenerate/';

  // Users
  static const users            = '/users/';
  static const inviteUser       = '/users/invite/';
  static String userDetail(int id) => '/users/$id/';

  // Areas
  static const areas               = '/areas/';
  static String areaDetail(int id) => '/areas/$id/';
  static String areaMembers(int id) => '/areas/$id/members/';

  // Activities
  static const activities                         = '/activities/';
  static String activityDetail(int id)            => '/activities/$id/';
  static String activityMove(int id)              => '/activities/$id/move/';
  static String activityComplete(int id)          => '/activities/$id/complete/';
  static String activityAssign(int id)            => '/activities/$id/assign/';
  static String activityLog(int id)               => '/activities/$id/log/';
  static String attachments(int id)               => '/activities/$id/attachments/';
  static String attachmentDelete(int actId, int attId) =>
      '/activities/$actId/attachments/$attId/';

  // Projects
  static const projects            = '/projects/';
  static String projectDetail(int id) => '/projects/$id/';

  // Stats
  static const statsMe             = '/stats/me/';
  static const statsArea           = '/stats/area/';
  static String statsAreaDetail(int id) => '/stats/area/$id/';
}
