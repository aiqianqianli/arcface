package com.arcsoft.arcsoft;

import android.Manifest;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.imageutil.ArcSoftImageFormat;
import com.arcsoft.imageutil.ArcSoftImageUtil;
import com.arcsoft.imageutil.ArcSoftImageUtilError;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

/** ArcsoftPlugin */
public class ArcsoftPlugin implements FlutterPlugin, MethodCallHandler {

  private static final String channelName = "com.arcsoft.face";
  private MethodChannel channel;
  // context
  private Context context;
  private static final String TAG = "ArcSoftFace";
  // 人脸检测引擎
  private FaceEngine faceEngine;
  private int code = -1;

  //
  private static final String[] need = new String[]{
          Manifest.permission.CAMERA,
          Manifest.permission.READ_PHONE_STATE,
          Manifest.permission.WRITE_EXTERNAL_STORAGE,
          Manifest.permission.READ_EXTERNAL_STORAGE,
  };

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), channelName);
    this.context = flutterPluginBinding.getApplicationContext();
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case  MethodConstants.GetPlatformVersion:
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case MethodConstants.Init:
        activeOnline(call, result);
        break;
      case MethodConstants.Collect:
        collect(call.arguments, result);
        break;
      case MethodConstants.Compare:
        compare(call,result);
        break;
      case MethodConstants.UnInit:
        unInit(result);
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  /// 在线激活SDK
  private void activeOnline(MethodCall call, final Result result) {
    String appId = call.argument("appId");
    String sdkKey = call.argument("sdkKey");
    int code = FaceEngine.activeOnline(this.context,appId,sdkKey);
    if (code == ErrorInfo.MOK || code == ErrorInfo.MERR_ASF_ALREADY_ACTIVATED){
      init(call,result);
    } else {
      result.error("" + code,"激活失败,错误码" + code,null);
    }
  }

  // 初始化
  private void init(MethodCall call, final Result result) {
    int initMask = FaceEngine.ASF_FACE_DETECT | FaceEngine.ASF_FACE_RECOGNITION  | FaceEngine.ASF_LIVENESS | FaceEngine.ASF_AGE | FaceEngine.ASF_FACE3DANGLE | FaceEngine.ASF_GENDER | FaceEngine.ASF_FACE3DANGLE;
    faceEngine = new FaceEngine();
    code = faceEngine.init(this.context, DetectMode.ASF_DETECT_MODE_IMAGE, DetectFaceOrientPriority.ASF_OP_ALL_OUT, 16, 5, initMask);
    if (code != ErrorInfo.MOK) {
      result.success(false);
    } else {
      result.success(true);
    }
  }

  /// 采集
  private void collect(Object arguments, final Result result) {
    List<FaceInfo> faceInfoList = new ArrayList<>();
//    int code = faceEngine.detectFaces(nv21,);
  }

  /// 人脸比对
  private void compare(MethodCall call, final Result result) {

    FaceFeature faceFeature1 = this.changeBytesWithPath(Base64.decode(call.argument("facePath").toString(), 0));
    FaceFeature faceFeature2 = this.changeBytesWithPath(Base64.decode(call.argument("netWorkPath").toString(), 0));

    FaceSimilar faceSimilar = new FaceSimilar();
    int compareCode = faceEngine.compareFaceFeature(faceFeature1,faceFeature2,faceSimilar);
    if (compareCode == ErrorInfo.MOK){
      //两个人脸的相似度
      float score = faceSimilar.getScore();
      Log.i(TAG, String.valueOf(score));
      result.success(score);
    }else{
      Log.i(TAG, "compare failed, code is : " + compareCode);
    }
  }

  // 获取到图片之后转换
  private FaceFeature changeBytesWithPath(byte[] data) {
    // 原始图像
    Bitmap originalBitmap = BitmapFactory.decodeByteArray(data,0,data.length);
    Bitmap bitmap = ImageUtil.alignBitmapForNv21(originalBitmap);
// 为图像数据分配内存
    final byte[] nv21 = ImageUtil.bitmapToNv21(bitmap,bitmap.getWidth(), bitmap.getHeight());
    List<FaceInfo> faceInfoList = new ArrayList<>();
    int code = faceEngine.detectFaces(nv21, bitmap.getWidth(), bitmap.getHeight(), FaceEngine.CP_PAF_NV21, faceInfoList);
    FaceFeature faceFeature = new FaceFeature();
    if (code == ErrorInfo.MOK && faceInfoList.size() > 0) {
      Log.i(TAG, "detectFaces, face num is : "+ faceInfoList.size());
      int extracCode = faceEngine.extractFaceFeature(nv21,bitmap.getWidth(), bitmap.getHeight(),FaceEngine.CP_PAF_NV21, faceInfoList.get(0), faceFeature);
      if (extracCode == ErrorInfo.MOK){
        Log.i(TAG, "extract face feature success");
      }else{
        Log.i(TAG, "extract face feature failed, code is : " + extracCode);
      }
    } else {
      Log.i(TAG, "no face detected, code is : " + code);
    }

    return faceFeature;
  }

  /// SDK 释放
  private void unInit(final Result result) {

  }

  /// 检查权限
  protected boolean checkPermission(String[] neededPermissions) {
    if (neededPermissions == null || neededPermissions.length == 0) {
      return true;
    }
    boolean granted = true;
    for (String need : neededPermissions){
      granted &= ContextCompat.checkSelfPermission(this.context,need) == PackageManager.PERMISSION_GRANTED;
    }
    return granted;
  }

}
