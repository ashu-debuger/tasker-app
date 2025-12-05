import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Combines a date and optional time into a single DateTime.
///
/// If [time] is null, defaults to end of day (23:59:59).
/// Returns null if [date] is null.
DateTime? combineDateAndTime(DateTime? date, TimeOfDay? time) {
  if (date == null) return null;
  if (time == null) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Formats a DateTime for display, including time if present.
///
/// Examples:
/// - "Nov 16, 2025" (no time or midnight)
/// - "Nov 16, 2025 · 2:30 PM" (with time)
String formatDueDateTime(DateTime date) {
  final datePart = DateFormat('MMM d, yyyy').format(date);
  final hasTime = date.hour != 0 || date.minute != 0 || date.second != 0;
  if (!hasTime) return datePart;
  final timePart = DateFormat.jm().format(date);
  return '$datePart · $timePart';
}

/// Validates that a DateTime is in the future.
///
/// Returns null if valid, or an error message if not.
String? validateFutureDateTime(DateTime? dateTime) {
  if (dateTime == null) return null;
  if (dateTime.isBefore(DateTime.now())) {
    return 'Due date must be in the future.';
  }
  return null;
}
