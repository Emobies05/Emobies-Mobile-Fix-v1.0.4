import 'package:flutter_test/flutter_test.dart';
import 'package:emobies/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EmobiesApp());
    expect(find.byType(EmobiesApp), findsOneWidget);
  });
}
