
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/main.dart';

void main() {
  testWidgets('Campus Event Management app loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CampusEventApp());

    expect(find.text('Campus Event Management'), findsOneWidget);
  });
}
