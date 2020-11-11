//
//  NSObject+JJKVOIMP.h
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import <Foundation/Foundation.h>
#import "NSObject+JJKVO.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JJKVOIMP)

/// 根据 keyPath 获取 setter 方法名
- (NSString *)setterNameForKeyPath:(NSString *)keyPath;

/// 根据 setter 方法名获取 keyPath
- (NSString *)keyPathForSetterName:(NSString *)setter;

/// 方法是否存在
- (BOOL)isMethodExist:(NSString *)selName;

/// 创建 KVO 子类
- (void)createKVOSubclass;

/// isa-swizzling
- (void)makeIsaSwizzling;

/// 重写 -class、-dealloc、-isKVO 方法
- (void)addCommonKVOMethods;

/// 重写 setter
- (void)overrideSetterForKeyPath:(NSString *)keyPath;

/// 保存观察者信息
- (void)saveObserver:(id)observer forKeyPath:(NSString *)keyPath options:(JJKVOChangeOptions)options context:(void *)context handler:(JJKVOChangeHandler)handler;

- (void)removeKVOObserver:(id)observer forKeyPath:(NSString *)keyPath context:(void *)content;


@end

NS_ASSUME_NONNULL_END
