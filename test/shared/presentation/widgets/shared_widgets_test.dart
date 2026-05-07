import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/shared/presentation/widgets/empty_state.dart';
import 'package:komando/shared/presentation/widgets/error_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Belum ada data',
              message: 'Data akan muncul di sini.',
            ),
          ),
        ),
      );

      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('Data akan muncul di sini.'), findsOneWidget);
    });
  });

  group('ErrorState', () {
    testWidgets('renders message and retry button', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Gagal memuat data',
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Gagal memuat data'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      expect(retryCalled, true);
    });
  });
}
