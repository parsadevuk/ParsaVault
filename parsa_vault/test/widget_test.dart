import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parsa_vault/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ParsaVaultApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
