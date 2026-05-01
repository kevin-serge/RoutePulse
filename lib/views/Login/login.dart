import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../viewmodels/user_controler.dart';
import '../../repository/app_repo.dart';
import '../../model/user_model.dart';
import '../../widget/rp_widgets.dart';
import 'package:routepulse/views/admin/acceuil_admin.dart';
import '../livreur/acceuil_livreur.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _controller = UserController();
  final _localAuth = LocalAuthentication();

  static const _storage = FlutterSecureStorage();
  static const _keyEmail = 'bio_email';
  static const _keyPassword = 'bio_password';

  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(minutes: 5);

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isLocked {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  String _lockMsg() {
    final mins = _lockedUntil!.difference(DateTime.now()).inMinutes + 1;
    return 'Trop de tentatives. Réessaie dans $mins min.';
  }

  // ──────────────────────────────────────
  // LOGIN
  // ──────────────────────────────────────
  Future<void> _login() async {
    if (_isLocked) { setState(() => _error = _lockMsg()); return; }
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });

    final user = await _controller.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (user == null) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockedUntil = DateTime.now().add(_lockDuration);
        setState(() => _error = _lockMsg());
      } else {
        setState(() => _error = 'Email ou mot de passe incorrect');
      }
      return;
    }

    _failedAttempts = 0;
    await _storage.write(key: _keyEmail, value: _emailCtrl.text.trim());
    await _storage.write(key: _keyPassword, value: _passwordCtrl.text);
    _navigate(user);
  }

  // ──────────────────────────────────────
  // BIOMÉTRIE
  // ──────────────────────────────────────
  Future<void> _loginBio() async {
    final email = await _storage.read(key: _keyEmail);
    final pwd = await _storage.read(key: _keyPassword);
    if (email == null || pwd == null) {
      showError(context, 'Connecte-toi d\'abord avec ton mot de passe');
      return;
    }
    try {
      if (!await _localAuth.isDeviceSupported()) return;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authentification requise',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!ok || !mounted) return;

      setState(() => _loading = true);
      final user = await _controller.login(email, pwd);
      setState(() => _loading = false);

      if (user == null) {
        await _storage.delete(key: _keyEmail);
        await _storage.delete(key: _keyPassword);
        if (mounted) showError(context, 'Session expirée, reconnecte-toi');
        return;
      }
      _navigate(user);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _navigate(User user) {
    final repo = AppRepo().repo;
    repo.syncAll();
    repo.startRealtimeSync();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.role == 'admin'
            ? AccueilAdmin(admin: user)
            : LivreurScreen(user: user),
      ),
    );
  }

  // ──────────────────────────────────────
  // UI
  // ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RPColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── LOGO
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── FORM
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: RPColors.background,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration:
                              const InputDecoration(labelText: 'Email'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (!User.isValidEmail(v)) return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (v.length < 6) return 'Minimum 6 caractères';
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (_loading || _isLocked) ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Se connecter'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<bool>(
                          future: _localAuth.isDeviceSupported(),
                          builder: (ctx, snap) {
                            if (snap.data != true) {
                              return const SizedBox.shrink();
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loginBio,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Connexion biométrique'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
