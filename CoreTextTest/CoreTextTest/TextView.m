//
//  TextView.m
//  CoreTextTest
//
//  Created by 郑雪利 on 2017/7/3.
//  Copyright © 2017年 郑雪利. All rights reserved.
//

#import "TextView.h"
#import <CoreText/CoreText.h>

@implementation TextView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"今天学了CoreText"];
    
    //创建上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
//    改变坐标系，CoreGraphics默认坐标系是数学中的UIGraphics，手机上的原点是左上角
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
//    创建path
    CGMutablePathRef path = CGPathCreateMutable();
//    path绘制的区域
    CGPathAddRect(path, NULL, self.bounds);
    
//    核心：
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrStr);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attrStr.length), path, NULL);
    CTFrameDraw(frame, context);
    
//    c语言中类似copy、create、retain是要手动release的
    CFRelease(frame);
    CFRelease(frameSetter);
    CFRelease(path);
}


@end
