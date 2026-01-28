// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fayoum_doctors_list/main.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    // Test the FayoumDoctorsApp widget directly
    await tester.pumpWidget(const FayoumDoctorsApp());
    
    // Pump once to build the widget tree
    await tester.pump();

    // Verify that the app is a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // التحقق من أن الصفحة الرئيسية موجودة
    expect(find.byType(Scaffold), findsWidgets);
  });
}
