//
//  ArcFaceUtil.m
//  arcsoft
//
//  Created by nanjiuchao on 2022/4/29.
//

#import "ArcFaceUtil.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/amcomdef.h>
#import <ArcSoftFaceEngine/merror.h>
#import "ColorFormatUtil.h"

static ArcSoftFaceEngine *engine;
static BOOL faceInit;

@interface ArcFaceUtil(){
}

@property (nonatomic, strong)UIImage* compareImage1;
@property (nonatomic, strong)UIImage* compareImage2;

@end

@implementation ArcFaceUtil

+ (instancetype)shareInstance{
    static ArcFaceUtil *obj = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

-(BOOL)activeCode:(NSString *)appId withSdkKey:(NSString *)sdkKey{
    BOOL faceRes = NO;
    NSString *appid = appId;
    NSString *sdkkey = sdkKey;
    engine = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [engine activeWithAppId:appid SDKKey:sdkkey];
    NSLog(@"activeCode active1：%ld", mr);
    if (mr == ASF_MOK || mr == MERR_ASF_ALREADY_ACTIVATED) {//SDK激活成功,SDK已激活
        mr = [engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                                   orientPriority:ASF_OP_ALL_OUT
                                            scale:16
                                       maxFaceNum:10
                                     combinedMask:ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE];
        NSLog(@"activeCode结果为：%ld", mr);
        faceRes = YES;
        faceInit = YES;
    } else {//SDK激活失败
        faceRes = NO;
    }
    return faceRes;
}
/**

 @param imgPath1 base64 本地选择图片
 @param imgPath2 base64 网络图片
 */

-(void)compareImage:(NSString*)imgPath1 withImg:(NSString*)imgPath2 complation:(void(^)(float res))complation{
    __weak typeof(self) weakSelf= self;
    
    [[ArcFaceUtil shareInstance] getCurrentImg:imgPath1 complation:^(UIImage *img) {
        weakSelf.compareImage1 = img;
        [weakSelf compareImages:complation];
    }];
    [[ArcFaceUtil shareInstance] getCurrentImg:imgPath2 complation:^(UIImage *img) {
        weakSelf.compareImage2 = img;
        [weakSelf compareImages:complation];
    }];
}

-(void)compareImages:(void(^)(float res))complation{
    if (self.compareImage1 != nil && self.compareImage2 != nil) {
        float mr = [[ArcFaceUtil shareInstance] faceCompare:self.compareImage1 withPath:self.compareImage2];
        NSLog(@"compareImage结果为：%f", mr);
        complation(mr);
    }
}

/**
 比较两张头像图片

 @param selectImage1 头像图片1
 @param selectImage2 头像图片2
 @return 对比结果
 */
-(MFloat)faceCompare:(UIImage*)selectImage1 withPath:(UIImage*)selectImage2{
    NSLog(@"faceCompare");
    MRESULT mr = 0;
    LPASF_FaceFeature copyFeature1 = (LPASF_FaceFeature)malloc(sizeof(ASF_FaceFeature));
    ASF_FaceFeature feature1 = [self faceFeature:selectImage1];
    
    copyFeature1->featureSize = feature1.featureSize;
    copyFeature1->feature = (MByte*)malloc(feature1.featureSize);
    memcpy(copyFeature1->feature, feature1.feature, copyFeature1->featureSize);
    
    ASF_FaceFeature feature2 = [self faceFeature:selectImage2];
    
    if (copyFeature1->featureSize > 0 && feature2.featureSize > 0) {
        //FM
        MFloat confidence = 0.0;
        mr = [engine compareFaceWithFeature:copyFeature1
                                   feature2:&feature2
                            confidenceLevel:&confidence];
        if (mr == ASF_MOK) {
            NSLog(@"FM比对结果为：%f", confidence);
            return confidence;
        }
    }
    return 0;
}

/**
 给定的base64字符串转图片
 @param selectImage1 头像图片1
 @param selectImage2 头像图片2
 @return 对比结果
 */
-(void)getCurrentImg:(NSString*)imageStr complation:(void(^)(UIImage *img))complation{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:imageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage* selectImage =[[UIImage alloc] initWithData:data];
    complation(selectImage);
}


/**
 获取给定图片中头像的特征

 @param selectImage 给定的头像图片
 @return 头像特征
 */
-(ASF_FaceFeature)faceFeature:(UIImage*)selectImage{
    ASF_FaceFeature feature = {0};
    MRESULT mr = 0;
    
    unsigned char* pRGBA = [ColorFormatUtil bitmapFromImage:selectImage];
    MInt32 dataWidth = selectImage.size.width;
    MInt32 dataHeight = selectImage.size.height;
    MUInt32 format = ASVL_PAF_NV12;
    MInt32 pitch0 = dataWidth;
    MInt32 pitch1 = dataWidth;
    MUInt8* plane0 = (MUInt8*)malloc(dataHeight * dataWidth * 3/2);
    MUInt8* plane1 = plane0 + dataWidth * dataHeight;
    unsigned char* pBGR = (unsigned char*)malloc(dataHeight * LINE_BYTES(dataWidth, 24));
    RGBA8888ToBGR(pRGBA, dataWidth, dataHeight, dataWidth * 4, pBGR);
    BGRToNV12(pBGR, dataWidth, dataHeight, plane0, pitch0, plane1, pitch1);
    
    ASF_MultiFaceInfo* fdResult = (ASF_MultiFaceInfo*)malloc(sizeof(ASF_MultiFaceInfo));
    fdResult->faceRect = (MRECT*)malloc(sizeof(fdResult->faceRect));
    fdResult->faceOrient = (MInt32*)malloc(sizeof(fdResult->faceOrient));
    
    //FD
    mr = [engine detectFacesWithWidth:dataWidth
                               height:dataHeight
                                 data:plane0
                               format:format
                              faceRes:fdResult];
    NSLog(@"faceFeature-----FD----结果为：%ld", mr);
    if (mr == ASF_MOK) {
        mr = [engine processWithWidth:dataWidth
                               height:dataHeight
                                 data:plane0
                               format:format
                              faceRes:fdResult
                                 mask:ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE];
        NSLog(@"faceFeature-----process----结果为：%ld", mr);
        if (mr == ASF_MOK) {
            
            //FR
            ASF_SingleFaceInfo frInputFace = {0};
            frInputFace.rcFace.left = fdResult->faceRect[0].left;
            frInputFace.rcFace.top = fdResult->faceRect[0].top;
            frInputFace.rcFace.right = fdResult->faceRect[0].right;
            frInputFace.rcFace.bottom = fdResult->faceRect[0].bottom;
            frInputFace.orient = fdResult->faceOrient[0];
            
            mr = [engine extractFaceFeatureWithWidth:dataWidth
                                              height:dataHeight
                                                data:plane0
                                              format:format
                                            faceInfo:&frInputFace
                                             feature:&feature];
            NSLog(@"faceFeature-----FR----结果为：%ld", mr);
        }
    }
    SafeArrayFree(pBGR);
    SafeArrayFree(pRGBA);
    return feature;
}


@end
