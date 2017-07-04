//
//  CTImageData.h
//  CoreTextTest
//
//  Created by 郑雪利 on 2017/7/3.
//  Copyright © 2017年 郑雪利. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface CTImageData : NSObject

@property (strong, nonatomic) NSString *imageName;

@property (assign, nonatomic) CGSize imageSize;

@property (assign, nonatomic) NSInteger position;

@end
