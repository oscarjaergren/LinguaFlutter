import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/auth_provider.dart';

/// Authentication screen with login/signup tabs
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo/Title
              Icon(
                Icons.school_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'LinguaFlutter',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Learn languages with flashcards',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message
                        if (authProvider.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: authProvider.clearError,
                                  color: theme.colorScheme.onErrorContainer,
                                  iconSize: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: _tabController.index == 0
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        // Confirm password (sign up only)
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (_tabController.index == 0) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_tabController.index == 1) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          height: 56,
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              return ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _submit(authProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        _tabController.index == 0
                                            ? 'Sign In'
                                            : 'Create Account',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot password (sign in only)
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (_tabController.index != 0) {
                              return const SizedBox.shrink();
                            }
                            return TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(authProvider),
                              child: const Text('Forgot Password?'),
                            );
                          },
                        ),

                        // Debug quick login (only in debug mode)
                        if (kDebugMode) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            '🔧 Debug Mode',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _debugQuickLogin(authProvider),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Quick Login (Test User)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_tabController.index == 0) {
      success = await authProvider.signIn(email: email, password: password);
    } else {
      success = await authProvider.signUp(email: email, password: password);
    }

    if (success && mounted) {
      context.go('/'); // Navigate to dashboard
    }
  }

  Future<void> _debugQuickLogin(AuthProvider authProvider) async {
    // Test user credentials from Docker test infrastructure
    const testEmail = 'test@linguaflutter.dev';
    const testPassword = 'testpass123';

    final success = await authProvider.signIn(
      email: testEmail,
      password: testPassword,
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  void _showForgotPasswordDialog(AuthProvider authProvider) {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final success = await authProvider.resetPassword(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
