// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String url = "https://owlbot.info/api/v4/dictionary/";
  String token = "216248e4477495a8f6d0009e4376b1e4ea59fb83";

  TextEditingController textEditingController = TextEditingController();

  // Stream for loading the text as soon as it is typed
  StreamController? streamController;
  Stream? _stream;
  bool _isListening = false;

  Timer? _debounce;
  late stt.SpeechToText _speech;
  String _text = 'Press the button and start speaking';
  String _newtext = "cat";

  // search function
  searchText() async {
    if (textEditingController.text.isEmpty) {
      streamController!.add(null);
      return;
    }
    streamController!.add("waiting");

    Response response =
        await get(Uri.parse(url + textEditingController.text.trim()),
            // do provide spacing after Token
            headers: {"Authorization": "Token " + token});

    var data = json.decode(response.body);
    print(data);
    streamController!.add(json.decode(response.body));
  }

  _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            _newtext = _text;
            print(_newtext);
          }),
        );
        if (_newtext.isEmpty) {
          streamController!.add(null);
          return;
        }
        streamController!.add("waiting");
        Response response = await get(Uri.parse(url + _newtext.trim()),
            // do provide spacing after Token
            headers: {"Authorization": "Token " + token});
        var data = json.decode(response.body);
        print(data);
        streamController!.add(json.decode(response.body));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    streamController = StreamController();
    _stream = streamController!.stream;
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "Dictionary",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12, bottom: 11.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      color: Colors.white),
                  child: TextFormField(
                    onChanged: (String text) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 1000), () {
                        searchText();
                      });
                    },
                    controller: textEditingController,
                    decoration: const InputDecoration(
                      hintText: "Search for a word",
                      contentPadding: EdgeInsets.only(left: 24.0),

                      // removing the input border
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  searchText();
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.red,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 1000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        child: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: Text("Enter a search word"),
              );
            }
            if (snapshot.data == "waiting") {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // output
            return ListView.builder(
              itemCount: snapshot.data["definitions"].length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data["definitions"].length;
                print(data);
                return ListBody(
                  children: [
                    Container(
                      color: Colors.grey[300],
                      child: ListTile(
                        leading: snapshot.data["definitions"][index]
                                    ["image_url"] ==
                                null
                            ? null
                            : CircleAvatar(
                                backgroundImage: NetworkImage(snapshot
                                    .data["definitions"][index]["image_url"]),
                              ),
                        title: Text(textEditingController.text.trim() +
                            "(" +
                            snapshot.data["definitions"][index]["type"] +
                            ")"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          snapshot.data["definitions"][index]["definition"]),
                    )
                  ],
                );
              },
            );
          },
          stream: _stream,
        ),
      ),
    );
  }
}
