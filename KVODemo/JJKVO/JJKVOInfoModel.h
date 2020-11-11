//
//  JJKVOInfoModel.h
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import <Foundation/Foundation.h>
#import "NSObject+JJKVO.h"

NS_ASSUME_NONNULL_BEGIN

@interface JJKVOInfoModel : NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic, assign) JJKVOChangeOptions option;

@property (nonatomic, copy) JJKVOChangeHandler handler;

@property (nonatomic) void *context;

@end

NS_ASSUME_NONNULL_END
