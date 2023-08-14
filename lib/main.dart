import 'package:flutter/material.dart';

import 'fancy_stepper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fancy Stepper',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FancyStepper(
          initStep: 0,
          width: 70,
          height: 70,
          minStep: 0,
          maxStep: 100,
          color: Colors.deepPurple.shade400,
          onChanged: (step) {
            print(step);
          },
        ),
      ),
    );
  }
}
