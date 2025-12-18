/// Formats a DateTime to dd/mm/yyyy hh:mm format.
String formatDate(DateTime date) {
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final year = localDate.year.toString();
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  final second = localDate.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}
