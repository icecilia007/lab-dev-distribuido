class User {
  final int id;
  final String name;
  final String email;
  final String type;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['nome'],
      email: json['email'],
      type: json['tipo'],
    );
  }
}
