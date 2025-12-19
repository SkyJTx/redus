import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import 'screens/todo_screen.dart';
import 'services/todo_store.dart';

void main() {
  // Register dependencies
  register<TodoStore>(TodoStore());

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Redus Todo Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: TodoScreen(),
    );
  }
}
