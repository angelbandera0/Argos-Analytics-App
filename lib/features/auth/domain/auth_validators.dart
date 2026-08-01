/// Reusable, framework-agnostic validators for the auth forms.
abstract class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasNumber = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasNumber) return 'Debe incluir letras y números';
    return null;
  }
}
