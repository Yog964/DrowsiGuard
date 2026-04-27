// Basic widget test for DrowsiGuard app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drowsiness_detection/main.dart';

void main() {
  testWidgets('App launches with login page', (WidgetTester tester) async {
    await tester.pumpWidget(const DrowsiGuardApp());
    // Verify the login page is displayed
    expect(find.text('DrowsiGuard'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
