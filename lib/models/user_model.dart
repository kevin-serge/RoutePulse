class User {
  int? id;
  String username;
  String password;
  bool isAdmin;

  User({
    this.id,
    required this.username,
    required this.password,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'isAdmin': isAdmin ? 1 : 0,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    username: map['username'],
    password: map['password'],
    isAdmin: map['isAdmin'] == 1,
  );
}
//c#