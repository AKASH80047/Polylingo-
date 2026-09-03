import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polylingo/main.dart';

void main() {
  testWidgets('PolyLingo App launches cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PolyLingoApp()));
    expect(find.byType(PolyLingoApp), findsOneWidget);
  });
}
