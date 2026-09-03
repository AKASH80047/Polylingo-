import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/models/user_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isSignUp = false;
  final _emailController = TextEditingController(text: 'alex.johnson@polylingo.ai');
  final _passwordController = TextEditingController(text: 'password123');
  final _nameController = TextEditingController(text: 'Alex Johnson');
  bool isLoading = false;

  void _handleLogin() {
    setState(() => isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      ref.read(userProvider.notifier).state = UserModel(
        id: 'usr_10294',
        name: isSignUp ? _nameController.text : 'Alex Johnson',
        email: _emailController.text,
        avatarUrl: null,
        isGuest: false,
        plan: 'Pro Plan',
        translationsThisMonth: 23,
        translationsMonthlyLimit: 50,
        storageUsedGb: 1.2,
        storageTotalGb: 5.0,
      );
      setState(() => isLoading = false);
      widget.onLoginSuccess();
    });
  }

  void _handleGuestMode() {
    ref.read(userProvider.notifier).state = const UserModel(
      id: 'usr_guest',
      name: 'Guest User',
      email: 'guest@polylingo.ai',
      isGuest: true,
      plan: 'Free Guest',
      translationsThisMonth: 3,
      translationsMonthlyLimit: 10,
      storageUsedGb: 0.1,
      storageTotalGb: 0.5,
    );
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLogo(size: 40)),
                const SizedBox(height: 24),
                Text(
                  isSignUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  isSignUp ? 'Start translating text & documents in seconds' : 'Sign in to access your cloud files & history',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 24),
                if (isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isSignUp ? 'Create Account' : 'Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                // Google Sign In
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network('https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg', width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 24)),
                      const SizedBox(width: 10),
                      const Text('Continue with Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _handleGuestMode,
                    child: Text('Continue as Guest', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ', style: const TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () => setState(() => isSignUp = !isSignUp),
                      child: Text(
                        isSignUp ? 'Sign In' : 'Sign Up',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
