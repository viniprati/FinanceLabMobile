/// Credenciais públicas que abrem somente os dados fictícios locais.
abstract final class DemoAccess {
  static const email = 'demo@financelab.local';
  static const password = 'demo123';

  static bool matches(String candidateEmail, String candidatePassword) =>
      candidateEmail.trim().toLowerCase() == email &&
      candidatePassword == password;
}
