import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/mock_users_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _submitError = null);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    // Simulated network request. Replace with the real auth call.
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final user = AuthSession.instance.login(_emailController.text.trim(), _passwordController.text);
    if (user == null) {
      setState(() => _submitError = 'Credenciales inválidas. Usa uno de los accesos rápidos o revisa tus datos.');
      return;
    }

    if (!context.mounted) return;
    context.go('/dashboard/board');
  }

  void _fillDemoCredentials(AppRole role) {
    final user = demoUserForRole(role);
    setState(() {
      _submitError = null;
      _emailController.text = user.email;
      _passwordController.text = user.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Brand(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Welcome back', style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Inicia sesión para continuar en Argos Analytics',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _DemoRoleButtons(onSelect: _fillDemoCredentials),
                    const SizedBox(height: AppSpacing.xl),
                    AuthTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: AuthValidators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () {},
                        child: Text('¿Olvidaste tu contraseña?', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_submitError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _SubmitButton(isSubmitting: _isSubmitting, onPressed: _handleSubmit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick-access buttons for the demo: tapping one just prefills the
/// email/password fields with that role's seeded demo account — the
/// person still presses "Iniciar sesión" to actually submit, so the
/// normal validation + loading-simulation flow runs unchanged.
class _DemoRoleButtons extends StatelessWidget {
  const _DemoRoleButtons({required this.onSelect});

  final ValueChanged<AppRole> onSelect;

  static const _roles = [
    (role: AppRole.superAdmin, label: 'Super Admin', icon: Icons.shield_rounded),
    (role: AppRole.admin, label: 'Admin', icon: Icons.admin_panel_settings_rounded),
    (role: AppRole.propietario, label: 'Propietario', icon: Icons.storefront_rounded),
    (role: AppRole.trabajador, label: 'Trabajador', icon: Icons.badge_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acceso rápido de prueba', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in _roles)
              OutlinedButton.icon(
                onPressed: () => onSelect(r.role),
                icon: Icon(r.icon, size: 15),
                label: Text(r.label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.sm)),
          alignment: Alignment.center,
          child: const Icon(Icons.blur_on_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Argos Analytics', style: AppTextStyles.h3),
      ],
    );
  }
}

/// Elevated button that morphs into a spinner while [isSubmitting] is true,
/// simulating a real network request before navigating to the dashboard.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : const Text('Iniciar sesión', key: ValueKey('label')),
        ),
      ),
    );
  }
}
