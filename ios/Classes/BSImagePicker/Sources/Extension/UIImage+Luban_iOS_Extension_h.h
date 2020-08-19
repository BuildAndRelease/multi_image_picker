//
//  UIImage+Luban_iOS_Extension_h.h
//  Luban-iOS
//
//  Created by guo on 2017/7/20.
//  Copyright © 2017年 guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIImage (Luban_iOS_Extension_h)

+ (NSData *)lubanOriginImage:(UIImage *)image;
+ (NSData *)lubanCompressImage:(UIImage *)image;
+ (NSData *)lubanCompressImage:(UIImage *)image withMask:(NSString *)maskName;
+ (NSData *)lubanCompressImage:(UIImage *)image withCustomImage:(NSString *)imageName;
+ (UIImage *)compressImage:(UIImage *)sourceImage toTargetWidth:(CGFloat)targetWidth toTargetWidth:(CGFloat)targetHeight;

@end
