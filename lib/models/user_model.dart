class User {
  int? id;
  String email;
  String password;
  bool isAdmin;

  User({
    this.id,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'password': password,
    'isAdmin': isAdmin ? 1 : 0,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    email: map['email'],
    password: map['password'],
    isAdmin: map['isAdmin'] == 1,
  );
}
//c#