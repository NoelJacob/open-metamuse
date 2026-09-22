import 'package:flutter_test/flutter_test.dart';

import 'package:openmetamuse/main.dart';

void main() {
  testWidgets('Landing renders phone entry', (WidgetTester tester) async {
    await tester.pumpWidget(const MuseApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Muse'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
