import 'package:flutter/material.dart';
import '../controleur/user_controler.dart';
import '../admin/acceuil_admin.dart';
import '../livreur/acceuil_livreur.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final controller = UserController();

  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: Text('Login')),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = await controller.login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() {
      _loading = false;
    });

    if (user == null) {
      setState(() => _error = 'Email ou mot de passe incorrect');
    } else {
      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(builder: (_) => AccueilAdmin(admin: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LivreurScreen(user: user)),
        );
      }
    }
  }
}
