import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/shared/presentation/widgets/feature_grid_item.dart';

void main() {
  testWidgets('FeatureGridItem renders icon and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeatureGridItem(icon: Icons.badge_outlined, label: 'KTA'),
        ),
      ),
    );

    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.text('KTA'), findsOneWidget);
  });
}
