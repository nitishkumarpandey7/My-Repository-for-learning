import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/network/api_client.dart';
import '../../core/sync/sync_queue.dart';
import '../../widgets/glass_card.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController(text: 'demo@lifeosx.local');
  final _password = TextEditingController(text: 'Lifeos@123');
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _localLogin() async {
    await _run(() async {
      final api = ref.read(apiClientProvider);
      final response = await api.postJson('/auth/login', {
        'email': _email.text.trim(),
        'password': _password.text,
        'device': {
          'deviceId': 'android-local',
          'platform': 'android',
          'appVersion': '1.0.0',
        },
      });
      await api.saveTokens(Map<String, dynamic>.from(response['data'] as Map));
      await ref.read(syncQueueProvider).flush();
    });
  }

  Future<void> _guestLogin() async {
    await _run(() async {
      final api = ref.read(apiClientProvider);
      final response = await api.postJson('/auth/guest', {});
      await api.saveTokens(Map<String, dynamic>.from(response['data'] as Map));
      await ref.read(syncQueueProvider).flush();
    });
  }

  Future<void> _googleLogin() async {
    await _run(() async {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final user = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await user.user?.getIdToken();
      if (idToken == null) return;
      final response =
          await ref.read(apiClientProvider).postJson('/auth/firebase', {
        'idToken': idToken,
        'provider': 'google',
      });
      await ref
          .read(apiClientProvider)
          .saveTokens(Map<String, dynamic>.from(response['data'] as Map));
      await ref.read(syncQueueProvider).flush();
    });
  }

  Future<void> _biometricUnlock() async {
    final localAuth = LocalAuthentication();
    final ok = await localAuth.authenticate(
      localizedReason: 'Unlock LifeOS X',
      biometricOnly: true,
    );
    if (ok && mounted) context.go('/dashboard');
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) context.go('/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.22),
              scheme.surface,
              scheme.secondary.withValues(alpha: 0.14)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text('LifeOS X',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                      'Your AI operating system for discipline, money, study, health, and focus.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                            controller: _email,
                            decoration:
                                const InputDecoration(labelText: 'Email')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _password,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password')),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _loading ? null : _localLogin,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.login_rounded),
                          label: const Text('Continue'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                                onPressed: _loading ? null : _googleLogin,
                                icon: const Icon(Icons.g_mobiledata_rounded),
                                label: const Text('Google')),
                            OutlinedButton.icon(
                                onPressed: _loading ? null : _guestLogin,
                                icon: const Icon(Icons.explore_rounded),
                                label: const Text('Guest')),
                            OutlinedButton.icon(
                                onPressed: _loading ? null : _biometricUnlock,
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: const Text('Biometric')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
