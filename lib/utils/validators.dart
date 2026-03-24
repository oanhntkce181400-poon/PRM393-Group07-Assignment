bool isValidEmail(String email) {
  final value = email.trim();

  if (value.isEmpty) return false;

  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
}
