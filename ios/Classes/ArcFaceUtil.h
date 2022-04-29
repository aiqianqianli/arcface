//
//  ArcFaceUtil.h
//  arcsoft
//
//  Created by nanjiuchao on 2022/4/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcFaceUtil : NSObject

+ (instancetype)shareInstance;

-(BOOL)activeCode:(NSString *)appId withSdkKey:(NSString *)sdkKey;

-(void)compareImage:(NSString*)imgPath1 withImg:(NSString*)imgPath2 complation:(void(^)(float res))complation;

@end

NS_ASSUME_NONNULL_END
