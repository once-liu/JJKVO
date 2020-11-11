//
//  NSObject+JJKVO.m
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import "NSObject+JJKVO.h"
#import "NSObject+JJKVOIMP.h"

@implementation NSObject (JJKVO)

- (void)jj_addObserver:(NSObject *)observer
         forKeyPath:(NSString *)keyPath
            options:(JJKVOChangeOptions)options
            context:(nullable void *)context
     completionHandler:(JJKVOChangeHandler)handler {
    // 入参检查
    if (observer == nil || keyPath == nil || keyPath.length == 0 || options == 0 || handler == nil) {
        return;
    }
    
    // 检查是否有 setter
    NSString *setter = [self setterNameForKeyPath:keyPath];
    if ([self isMethodExist:setter] == NO) {
        return;
    }
    
    // 动态创建 KVOClass_xxx 类
    [self createKVOSubclass];
    
    // isa-swizzling
    [self makeIsaSwizzling];
    
    // 重写 -class、-dealloc、-isKVO 方法
    [self addCommonKVOMethods];
    
    // 重写 setter 方法
    [self overrideSetterForKeyPath:keyPath];
    
    // 保存观察者信息
    [self saveObserver:observer forKeyPath:keyPath options:options context:context handler:handler];
    
}

- (void)jj_removeObserver:(id)observer {
    [self jj_removeObserver:observer forKeyPath:nil];
}

- (void)jj_removeObserver:(id)observer forKeyPath:(NSString *)keyPath {
    [self jj_removeObserver:observer forKeyPath:keyPath context:nil];
}

- (void)jj_removeObserver:(id)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0)) {
    [self removeKVOObserver:observer forKeyPath:keyPath context:context];
}


@end
