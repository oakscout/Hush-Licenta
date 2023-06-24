import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health/health.dart';

import 'home_page.dart';
import 'utils.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    Provider.of<TextProvider>(context, listen: false).loadSavedText();
    _checkAuthorizationStatus();
  }

  Future<void> _checkAuthorizationStatus() async {
    setState(() {
      _isLoading = true;
    });

    HealthFactory health = HealthFactory();

    List<HealthDataType> types = [
      HealthDataType.HEART_RATE,
    ];

    bool accessWasGranted = await health.requestAuthorization(types);

    setState(() {
      _isLoading = false;
      _isAuthorized = accessWasGranted;
    });

    if (!_isAuthorized) {
      print("Nu sunteți autorizat pentru a folosi aplicația");
    }
  }

  void _handleAuthorization() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          backgroundColor: Color(0xFFE6E9F0),
          title: Text(
            'Introduceți-vă numele',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.0,
              fontFamily: "Fjord",
            ),
          ),
          content: TextField(
            controller: _textEditingController,
            style: TextStyle(
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'ex. Andreea',
              hintStyle: TextStyle(
                color: Colors.black45,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF6750A4),
                  fontFamily: "Fjord",
                  fontSize: 18.0,
                ),
              ),
              onPressed: () {
                Provider.of<TextProvider>(context, listen: false).updateText(_textEditingController.text);
                Navigator.pop(context);
                _checkAuthorizationStatus();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return GestureDetector(
        onTap: () {
          _handleAuthorization();
        },
        child: Scaffold(
          backgroundColor: Color(0xFF8EA4CD),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.only(top: 60.0),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.only(top: 50.0, left: 30.0, right: 30.0),
                  child: Text(
                    textAlign: TextAlign.center,
                    "Valorile ridicate de stres vă pot împiedica să gestionați corespunzător situațiile dificile.\nHush este aici pentru a vă ghida în asemenea situații, pentru ca dvs. să puteți aborda orice situație cu o stare de calm.\nDoar conectați-vă cu contul Google și Hush vă va notifica când e timpul să luați inițiativă",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white.withOpacity(1.0),
                      fontFamily: "Fjord",
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.only(top: 70.0),
                  child: Text(
                    textAlign: TextAlign.center,
                    "Apasă oriunde pentru a începe.",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white.withOpacity(1.0),
                      fontFamily: "Fjord",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset('assets/images/iceberg.png'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Future.delayed(Duration(seconds: 3), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DataPage()),
        );
      });
      return Scaffold(
        backgroundColor: Color(0xFF8EA4CD),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.only(top: 200.0),
                child: Text(
                  "Se încarcă..",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white.withOpacity(1.0),
                    fontFamily: "Fjord",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.only(bottom: 300.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
