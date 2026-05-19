// Modelos de request/response exclusivos del flujo de autenticación.
// Los modelos de dominio (UserModel, etc.) viven en lib/shared/models/.

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email':    email,
    'password': password,
  };
}

class InviteAcceptRequest {
  final String token;
  final String email;
  final String firstName;
  final String lastName;
  final String password;

  const InviteAcceptRequest({
    required this.token,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'token':      token,
    'email':      email,
    'first_name': firstName,
    'last_name':  lastName,
    'password':   password,
  };
}
