import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_nija_game/main.dart';

void main() {
  testWidgets('Home screen shows brand title', (tester) async {
    await tester.pumpWidget(const FruitNinjaApp());
    // One frame is enough; home has a repeating animation so settle never ends.
    await tester.pump();

    expect(find.text('FRUIT NINJA'), findsOneWidget);
    expect(find.text('TiahM'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
