class User {
  final int id;
  final String name;
  final String email;
  final String type;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.phone,
  });

  factory User.fromJson(Map json) {
    return User(
      id: json['id'],
      name: json['nome'],
      email: json['email'],
      type: json['tipo'],
      phone: json['telefone'],
    );
  }
}