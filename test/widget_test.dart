import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psx_portfolio_tracker/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PsxPortfolioApp()),
    );
    await tester.pump();
    expect(find.text('Portfolio Value'), findsOneWidget);
  });
}
