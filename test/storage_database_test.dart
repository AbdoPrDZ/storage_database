import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_page.dart';

void main() {
  test("test storage database app", () {
    runApp(const TestApp());
  });
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}
