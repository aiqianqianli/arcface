// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:arcsoft/arcsoft.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // initArcSoft();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await Arcsoft.instance.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initArcSoft() async {
    bool result = await Arcsoft.instance.init(
        '7vNo7jPkJ7SmGpnk6vgVjtXWoYNfxnntqdNPoPzJoZ26',
        '5k63P82aUyrp49X9JeAmYtnrjkKLvpi8K3qFv3tTfxc1');
    print(result);
  }

  Future<dynamic> getBytes(String url) async {
    Response response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    String base64Str = base64Encode(response.data);
    return base64Str;
  }

  Future<dynamic> arcSoftCompareFace() async {
    var image1 = await getBytes(
        'https://xljc.xltmsw.com:9090/attence/face/zhxl_face_1473891894785216514.jpg');
    var image2 = await getBytes(
        'https://xljc.xltmsw.com:9090/attence/face/zhxl_face_1473891894785216514.jpg');
    dynamic result = await Arcsoft.instance.compare(image1, image2);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: InkWell(
              child: Text('Running on: $_platformVersion\n'),
              onTap: () {
                initArcSoft();
                // this.arcSoftCompareFace();
              }),
        ),
      ),
    );
  }
}
