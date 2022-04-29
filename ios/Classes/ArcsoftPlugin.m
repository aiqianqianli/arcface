#import "ArcsoftPlugin.h"
#import "MethodConstants.h"
#import "ArcFaceUtil.h"

@implementation ArcsoftPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.arcsoft.face"
            binaryMessenger:[registrar messenger]];
  ArcsoftPlugin* instance = [[ArcsoftPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:GetPlatformVersion]) {
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([call.method isEqualToString:Init]) {
        NSDictionary *dic = call.arguments;
        BOOL res = [[ArcFaceUtil shareInstance] activeCode:dic[@"appId"] withSdkKey:dic[@"sdkKey"]];
        NSLog(@"%@", dic[@"appId"]);
        NSLog(@"%@", dic[@"sdkKey"]);
        result([NSNumber  numberWithBool:res]);
    }else if ([call.method isEqualToString:Compare]) {
        NSDictionary *dic = call.arguments;
        [[ArcFaceUtil shareInstance] compareImage:dic[@"facePath"] withImg:dic[@"netWorkPath"] complation:^(float res) {
            result([NSNumber numberWithFloat:res]);
        }];
    }else {
      result(FlutterMethodNotImplemented);
    }
}

@end
