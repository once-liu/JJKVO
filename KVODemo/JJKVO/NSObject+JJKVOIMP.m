//
//  NSObject+JJKVOIMP.m
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import "NSObject+JJKVOIMP.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (JJKVOIMP)

/// 根据 keyPath 获取 setter 方法名
- (NSString *)setterNameForKeyPath:(NSString *)keyPath {
    // setKeyPath / _setKeyPath / setIsKeyPath
    unsigned int count = 0;
    Method *methodList = class_copyMethodList([self class], &count);
    NSArray *possibleSetters = [self possibleSettersForKeyPath:keyPath];
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        SEL methodSEL = method_getName(method);
        NSString *setter = NSStringFromSelector(methodSEL);
        if ([possibleSetters containsObject:setter]) {
            free(methodList);
            NSLog(@" %s -- setterName: %@", __func__, setter);
            return  setter;
        }
    }
    return nil;
}

/// 根据 setter 方法名获取 keyPath
- (NSString *)keyPathForSetterName:(NSString *)setter {
    
    return nil;
}

/// 方法是否存在
- (BOOL)isMethodExist:(NSString *)selName {
    
    return NO;
}

/// 创建 KVO 子类
- (void)createKVOSubclass {
    
}

/// isa-swizzling
- (void)makeIsaSwizzling {
    
}

/// 重写 -class、-dealloc、-isKVO 方法
- (void)addCommonKVOMethods {
    
}

/// 重写 setter
- (void)overrideSetterForKeyPath:(NSString *)keyPath {
    
}

/// 保存观察者信息
- (void)saveObserver:(id)observer forKeyPath:(NSString *)keyPath options:(JJKVOChangeOptions)options context:(void *)context handler:(JJKVOChangeHandler)handler {
    
}

- (void)removeKVOObserver:(id)observer forKeyPath:(NSString *)keyPath context:(void *)content {
    
}

// MARK: Private

- (NSArray <NSString *> *)setterPrefixes {
    static NSArray *_setterPrefixes = nil;
    if (_setterPrefixes == nil) {
        _setterPrefixes = @[@"set", @"_set", @"setIs"];
    }
    return  _setterPrefixes;
}

- (NSArray *)possibleSettersForKeyPath:(NSString *)keyPath {
    NSArray *prefixes = [self setterPrefixes];
    NSMutableArray *setters = [NSMutableArray arrayWithCapacity:prefixes.count];
    
    NSString *firstLetter = [keyPath substringToIndex:1];
    NSString *tailLetters = [keyPath substringFromIndex:1];
    NSString *suffix = [[[firstLetter uppercaseString] stringByAppendingString:tailLetters] stringByAppendingString:@":"];
    for (NSString *tempPre in prefixes) {
        NSString *setter = [tempPre stringByAppendingString:suffix];
        [setters addObject:setter];
    }
    
    return setters;
}

@end
