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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speech to Text Example'),
        ),
        body: Column(children: [
          Center(
            child: Text(
              'Speech recognition available',
              style: TextStyle(fontSize: 22.0),
            ),
          ),
          Container(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Initialize'),
                      onPressed: _hasSpeech ? null : initSpeechState,
                    ),
                  ],
                ),
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
          Expanded(
            flex: 4,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(10),
                        color: Theme.of(context).selectedRowColor,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: lastWords == "" ? 0 : 1,
                            duration: Duration(milliseconds: 200),
                            child: Text(lastWords),
                          ),
                        ),
                      ),
                      Container(
                        child: GestureDetector(
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget> 
                            [
                              AnimatedContainer(
                                height: _bigger ? 150 : 100,
                                width: _bigger ? 150 : 100,
                                duration: Duration(milliseconds: 400),
                                decoration: new BoxDecoration(
                                  color: _color,
                                  shape: BoxShape.circle
                                )
                              )
                            ]
                          )
                        )
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'Error Status',
                    style: TextStyle(fontSize: 22.0),
                  ),
                ),
                Center(
                  child: Text(lastError),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Theme.of(context).backgroundColor,
            child: Center(
              child: speech.isListening
                  ? Text(
                      "I'm listening...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'Not listening',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ]),
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