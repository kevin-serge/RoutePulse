import 'package:flutter/material.dart';
import '../controleur/user_controler.dart';
import '../admin/acceuil_admin.dart';
import '../livreur/acceuil_livreur.dart';
import '../widget/rp_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final controller = UserController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RPColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER BRAND
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.local_shipping,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'RoutePulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestion intelligente des livraisons',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── FORMULAIRE
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: RPColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: RPColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Entrez vos identifiants pour continuer',
                        style: TextStyle(
                            color: RPColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon:
                              Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Email requis' : null,
                      ),
                      const SizedBox(height: 14),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon:
                              const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Mot de passe requis' : null,
                      ),

                      // Erreur
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: RPColors.annulee.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: RPColors.annulee.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: RPColors.annulee, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                    color: RPColors.annulee, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Bouton
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: RPColors.primary))
                            : ElevatedButton(
                                onPressed: _login,
                                child: const Text('Se connecter',
                                    style: TextStyle(fontSize: 15)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (user == null) {
      setState(() => _error = 'Email ou mot de passe incorrect');
    } else if (user.role == 'admin') {
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
