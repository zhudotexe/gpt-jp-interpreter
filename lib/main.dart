import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kanpai_mobile/openai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

const int EN = 0;
const int JP = 1;

enum WorkState { idle, recording, busy }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Voice Transcription',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: VoicePage(),
    );
  }
}

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});

  @override
  _VoicePageState createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  WorkState state = WorkState.idle;
  List<String> transcriptions = List<String>.filled(2, '');
  int _recordingLanguage = EN;
  final AudioRecorder _record = AudioRecorder();
  final OpenAI _openai = OpenAI();

  // ==== audio ====
  Future<String> get _voicePath async {
    final Directory tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/voice.m4a';
  }

  // Future<void> setup() async {
  //   bool isRecording = await _record.isRecording();
  //   if (isRecording) {
  //     await _record.stop();
  //   }
  //   // Start recording to file
  //   await _record.start(const RecordConfig(), path: await _voicePath);
  //   await _record.pause();
  // }

  Future<void> startRecording(int lang) async {
    if (state != WorkState.idle) return;
    // set up recording
    bool isRecording = await _record.isRecording();
    // if (!isRecording) await setup();
    if (isRecording) await _record.stop();
    // disable inputs
    setState(() {
      state = WorkState.recording;
    });
    // start
    _recordingLanguage = lang;
    await _record.start(const RecordConfig(), path: await _voicePath);
  }

  Future<void> stopRecording() async {
    bool isRecording = await _record.isRecording();
    if (!isRecording) return;
    // save audio file
    final path = await _record.stop();
    // setup(); // async ensure we are ready to record again
    if (path == null) {
      setState(() {
        state = WorkState.idle;
      });
      return;
    }

    // set loading state
    setState(() {
      state = WorkState.busy;
    });

    // send file to whisper API
    final text = await _openai.createTranscription(path,
        language: _recordingLanguage == EN ? 'en' : 'ja');
    // update the transcription of whatever language we just recorded
    // and clear the other
    setState(() {
      transcriptions[_recordingLanguage] = text;
      transcriptions[1 - _recordingLanguage] = '';
    });

    if (text.trim().isEmpty) {
      setState(() {
        state = WorkState.idle;
      });
      return;
    }

    // send text to gpt4
    final translation = await _openai.gpt4(text);

    // update the transcription of the other language
    setState(() {
      transcriptions[1 - _recordingLanguage] = translation;
    });

    // reenable
    setState(() {
      state = WorkState.idle;
    });
  }

  // ==== flutter ====
  Widget buildLanguage(int lang) {
    switch (state) {
      case WorkState.idle:
        return GestureDetector(
          onTapDown: (_) => startRecording(EN),
          onTapUp: (_) => stopRecording(),
          child: const Icon(CupertinoIcons.mic_fill, size: 48),
        );
      case WorkState.recording:
        return const Icon(CupertinoIcons.mic_fill, size: 48);
      case WorkState.busy:
        return const CupertinoActivityIndicator();
    }
  }

  @override
  void initState() {
    super.initState();
    _record.hasPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // --- japanese ---
          Transform.flip(
            flipY: true,
            child: Column(children: [
              Text(transcriptions[JP]),
              buildLanguage(JP),
            ]),
          ),
          const Divider(),
          // --- english ---
          Column(
            children: [
              Text(transcriptions[EN]),
              buildLanguage(EN),
            ],
          ),
        ],
      ),
    );
  }
}
