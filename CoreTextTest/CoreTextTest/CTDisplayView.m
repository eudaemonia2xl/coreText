//
//  CTDisplayView.m
//  CoreTextTest
//
//  Created by 郑雪利 on 2017/7/3.
//  Copyright © 2017年 郑雪利. All rights reserved.
//

#import "CTDisplayView.h"
#import <CoreText/CoreText.h>
#import "CTImageData.h"

static NSString *kImagePattern = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";

@interface CTDisplayView ()

@property (strong, nonatomic) NSMutableAttributedString *attStr;

@property (strong, nonatomic) NSArray *ary;

@end

@implementation CTDisplayView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _attStr = [[NSMutableAttributedString alloc] initWithString:@"今天很开心[开心][2B]"];
    
//    通过字符串，使用正则表达式找出字符串中的符合表情的文字
    _ary = [self imageArrayWithAttributedString:_attStr];
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
//    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:@"HelloWorld[开心][2B]"];
    
    //开启上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    //创建path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
//    CGMutablePathRef path = [[CGMutablePathRef alloc] init];
//    [path CGPathAddRect:self.bounds];
    
    
    //创建frameset
    CTFramesetterRef frameset = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attStr);
    
    
    CTFrameRef frame = CTFramesetterCreateFrame(frameset, CFRangeMake(0, _attStr.length), path, NULL);
    
    CTFrameDraw(frame, context);
    
    [self drawImagesWithFrameRef:frame];
    
    CFRelease(frame);
    CFRelease(frameset);
    CFRelease(path);
}

- (void)drawImagesWithFrameRef:(CTFrameRef)frameRef
{
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
//    通过frameRef获取到有多少行
    CFArrayRef lines = CTFrameGetLines(frameRef);
    CFIndex lineCount = CFArrayGetCount(lines);
    NSUInteger numberOfLines = lineCount;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, numberOfLines), lineOrigins);
    
//    遍历找到的每一行
    for (CFIndex idx = 0; idx < numberOfLines; idx++) {
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, idx);
//        通过每一行找到有多少runs
        CFArrayRef runs = CTLineGetGlyphRuns(lineRef);
        CFIndex runCount = CFArrayGetCount(runs);
        CGPoint lineOrigin = lineOrigins[idx];
//        遍历每一个run
        for (CFIndex idx = 0; idx < runCount; idx ++) {
            CTRunRef runRef = CFArrayGetValueAtIndex(runs, idx);
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(runRef);
//            取出kCTRunDelegateAttributeName对应的delegate
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (nil == delegate) continue;
            
            CTImageData *imageData = (CTImageData *)CTRunDelegateGetRefCon(delegate);
            
//            通过模型获取图片的frame
            CGRect imageFrame = CTRunGetTypographicBoundsForImageRect(runRef, lineRef, lineOrigin, imageData);
            
//            绘图：通过imageName找到对应的图片绘图
            CGContextRef context = UIGraphicsGetCurrentContext();
            NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"emotion.bundle/%@.png",imageData.imageName]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            CGContextDrawImage(context, imageFrame, image.CGImage);
        }
    }
}

CGRect CTRunGetTypographicBoundsForImageRect(CTRunRef runRef, CTLineRef lineRef, CGPoint lineOrigin, CTImageData *imageData)
{
    CGRect rect = CTRunGetTypographicBoundsAsRect(runRef, lineRef, lineOrigin);
    return rect;
}


CGRect CTRunGetTypographicBoundsAsRect(CTRunRef runRef, CTLineRef lineRef, CGPoint lineOrigin)
{
    CGFloat ascent;
    CGFloat descent;
    CGFloat width = CTRunGetTypographicBounds(runRef, CFRangeMake(0, 0), &ascent, &descent, NULL);
    CGFloat height = ascent + descent;
    
    CGFloat offsetX = CTLineGetOffsetForStringIndex(lineRef, CTRunGetStringRange(runRef).location, NULL);
    
    return CGRectMake(lineOrigin.x + offsetX, lineOrigin.y - descent, width, height);
}

/**
 * 通过字符串找到含有表情的文字
 */
- (NSArray *)imageArrayWithAttributedString:(NSMutableAttributedString *)attStr
{
    NSMutableArray *arr = [NSMutableArray array];
    
    NSString *strTemp = attStr.string.copy;
    
//    正则表达式
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kImagePattern options:NSRegularExpressionCaseInsensitive error:nil];
    [regex enumerateMatchesInString:strTemp options:NSMatchingReportProgress range:NSMakeRange(0, strTemp.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        
        NSString *resultStr = [strTemp substringWithRange:result.range];
        NSString *imageName;
        if (resultStr.length > 2)
        {
            imageName = [resultStr substringWithRange:NSMakeRange(1, resultStr.length - 2)];
            CTImageData *imageData = [[CTImageData alloc] init];
            imageData.imageName = imageName;
            imageData.imageSize = CGSizeMake(20, 20);
            
            NSAttributedString *spaceAttStr = [self attributedStringWithImageData:imageData];
            NSString *imageStr = [NSString stringWithFormat:@"[%@]", imageData.imageName];
            NSRange range = [attStr.string rangeOfString:imageStr];
            
            imageData.position = range.location;
            
            [attStr replaceCharactersInRange:range withAttributedString:spaceAttStr];
            
            [arr addObject:imageData];
        }
    }];
    
    return arr;
}

/**
 * 通过模型将字符串中的带有表情的文字用特殊符号代替，返回值就是该特殊符号
 */
- (NSAttributedString *)attributedStringWithImageData:(CTImageData *)imageData
{
//    思路上类似tableView的代理方法，返回cell高度
    CTRunDelegateCallbacks callbacks;
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    
//    run初始化代理
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)(imageData));
    
//    objectReplacementChar：使用这个代替[开心]
    unichar objectReplacementChar = 0xFFFC;
    NSString *str = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:str];
//    给run设置delegate
    [attStr addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id _Nonnull)(delegate) range:NSMakeRange(0, 1)];
    
    CFRelease(delegate);
    
    return attStr;
}

//每一个run的代理方法，会自动调用
static CGFloat ascentCallback(void *ref)
{
    CTImageData *imageData = (__bridge CTImageData *)ref;
    return imageData.imageSize.height;
}

static CGFloat descentCallback(void *ref)
{
    return 0;
}

static CGFloat widthCallback(void *ref)
{
    CTImageData *imageData = (__bridge CTImageData *)ref;
    return imageData.imageSize.width;
}


@end
