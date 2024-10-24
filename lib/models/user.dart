class User {
  final int id;
  final String name;
  final String email;
  final String password;

  User({required this.id, required this.name, required this.email, required this.password});

  // Создание объекта User из Map
  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
      );

  // Конвертация объекта User в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
      };
}
