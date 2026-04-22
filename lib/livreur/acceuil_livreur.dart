import 'package:flutter/material.dart';
import '../model/user_model.dart';

class LivreurScreen extends StatelessWidget {
  final User user;
  const LivreurScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Livreur Dashboard')),
      body: Center(
        child: Text(
          'Bonjour Livreur ${user.email}!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
