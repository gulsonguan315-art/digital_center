import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FocusNode _node = FocusNode();
  bool _offstage = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _node.requestFocus();
                print('Node has focus: ${_node.hasFocus}');
              },
              child: const Text('Request Focus'),
            ),
            Offstage(
              offstage: _offstage,
              child: Focus(
                focusNode: _node,
                child: const Text('Offstage Text'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
