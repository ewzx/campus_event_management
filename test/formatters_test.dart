import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/core/formatters.dart';

void main() {
  test('formatDate shows day, month name and year', () {
    expect(formatDate(DateTime(2026, 11, 5)), '5 November 2026');
  });

  test('formatTime uses a 12-hour clock with AM and PM', () {
    expect(formatTime(DateTime(2026, 11, 5, 9, 30)), '9:30 AM');
    expect(formatTime(DateTime(2026, 11, 5, 14, 5)), '2:05 PM');
    expect(formatTime(DateTime(2026, 11, 5, 0, 0)), '12:00 AM');
    expect(formatTime(DateTime(2026, 11, 5, 12, 0)), '12:00 PM');
  });
}