import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MathForm(),
    );
  }
}

class MathForm extends StatefulWidget {
  @override
  _MathFormState createState() => _MathFormState();
}

class _MathFormState extends State<MathForm> {
  final _formKey = GlobalKey<FormState>();
  String _login = '';
  String _password = '';
  String _polynomial = '';
  String _derivative = '';

  void _calculateDerivative() {
    final cleanedPolynomial = _polynomial.replaceAll(' ', '');
    final terms = cleanedPolynomial.split(RegExp(r'(?=[+-])'));
    final derivativeTerms = terms
        .map((term) {
          final coefficientMatch =
              RegExp(r'([+-]?\d*\.?\d*)x?(\^(\d+))?').firstMatch(term);
          if (coefficientMatch != null) {
            final coefficientStr = coefficientMatch.group(1);
            final exponentStr = coefficientMatch.group(3);

            final coefficient =
                coefficientStr != null && coefficientStr.isNotEmpty
                    ? double.parse(coefficientStr)
                    : (term.startsWith('-') ? -1.0 : 1.0);
            final exponent = exponentStr != null
                ? int.parse(exponentStr)
                : (term.contains('x') ? 1 : 0);

            if (exponent == 0) {
              return '';
            } else {
              final newCoefficient = coefficient * exponent;
              final newExponent = exponent - 1;

              final newCoefficientStr =
                  newCoefficient == 1 ? '' : newCoefficient.toString();
              final newExponentStr = newExponent == 0
                  ? ''
                  : (newExponent == 1 ? 'x' : 'x^$newExponent');

              return '$newCoefficientStr$newExponentStr';
            }
          } else {
            throw FormatException('Invalid polynomial term');
          }
        })
        .where((term) => term.isNotEmpty)
        .toList();

    _derivative = derivativeTerms.join(' + ').replaceAll('+ -', '- ');
  }

  Future<void> _saveData() async {
    CollectionReference users =
        FirebaseFirestore.instance.collection('MathUsers');
    return users
        .add({
          'login': _login,
          'password': _password,
          'polynomial': _polynomial,
          'derivative': _derivative,
        })
        .then((value) => print('User added'))
        .catchError((error) => print('Failed to add user: $error'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Math Form'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Login'),
              onSaved: (value) {
                _login = value!;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSaved: (value) {
                _password = value!;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Polynomial'),
              onSaved: (value) {
                _polynomial = value!;
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _calculateDerivative();
                  await _saveData();
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
