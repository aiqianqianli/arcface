// ignore_for_file: constant_identifier_names, prefer_const_constructors

import 'dart:async';
import 'package:arcsoft/model.dart';

import 'constants.dart';
import 'package:flutter/services.dart';

class Arcsoft extends _ServiceApi {
  Arcsoft._();
  static Arcsoft instance = Arcsoft._();
}

class _ServiceApi {
  static const String _ChannelName = 'com.arcsoft.face';
  final MethodChannel _channel = MethodChannel(_ChannelName);

  Future<String?> get platformVersion async {
    final String? version =
        await _channel.invokeMethod<String>(MethodConstants.GetPlatformVersion);
    return version;
  }

  // 初始化
  Future<bool> init(String appId, String sdkKey) async {
    final bool result = await _channel
        .invokeMethod(MethodConstants.Init, {"appId": appId, "sdkKey": sdkKey});
    return result;
  }

  // 采集
  Future<CollectResult> collect() async {
    final Map<String, dynamic>? result =
        await _channel.invokeMapMethod(MethodConstants.Collect);
    if (result == null) {
      return CollectResult(error: "取消识别");
    }
    return CollectResult.fromMap(result);
  }

// 人脸比对 传入base64字符串
  Future<double> compare(dynamic facePath, dynamic netWorkPath) async {
    final double result = await _channel.invokeMethod(MethodConstants.compare,
        {"facePath": facePath, "netWorkPath": netWorkPath});
    return result;
  }
}
