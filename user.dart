class User {
  String username;
  String email;
  String password;
  String? profileImageUrl;

  User({
    required this.username,
    required this.email,
    required this.password,
    this.profileImageUrl,
  });
}