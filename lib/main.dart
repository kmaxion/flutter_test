import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasSpeech = false;
  bool _stressTest = false;
  double level = 0.0;
  int _stressLoops = 0;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  bool _bigger = false;
  Color _color = Colors.amber;

  @override
  void initState() {
    super.initState();
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  @override
  Widget build(BuildContext context) {
    initSpeechState();

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Container(
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      DropdownButton(
                        onChanged: (selectedVal) => _switchLang(selectedVal),
                        value: _currentLocaleId,
                        items: _localeNames
                            .map(
                              (localeName) => DropdownMenuItem(
                                value: localeName.localeId,
                                child: Text(localeName.name),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Text(lastWords)
            )
          ]),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(height: 50.0,),
        ),
        floatingActionButton: GestureDetector(
          onTapDown: (TapDownDetails d) {
            if (_hasSpeech && !speech.isListening) {
              startListening();
            }
            setState(() {
              _bigger = true;
              _color = Colors.red;
            });
          },
          onTapUp: (TapUpDetails d) {
            if (speech.isListening) {
              stopListening();
            }
            setState(() {
              _bigger = false;
              _color = Colors.teal;
            });
          },
          child: FloatingActionButton(
            onPressed: () => setState(() {
            }),
            tooltip: 'Start',
            child: Icon(Icons.mic),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void stressTest() {
    if (_stressTest) {
      return;
    }
    _stressLoops = 0;
    _stressTest = true;
    print("Starting stress test...");
    startListening();
  }

  void changeStatusForStress(String status) {
    if (!_stressTest) {
      return;
    }
    if (speech.isListening) {
      stopListening();
    } else {
      if (_stressLoops >= 100) {
        _stressTest = false;
        print("Stress test complete.");
        return;
      }
      print("Stress loop: $_stressLoops");
      ++_stressLoops;
      startListening();
    }
  }

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = "${result.recognizedWords} - ${result.finalResult}";
    });
  }

  void soundLevelListener(double level) {
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    changeStatusForStress(status);
    setState(() {
      lastStatus = "$status";
    });
  }

  _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }
}