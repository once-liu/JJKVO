//
//  NSObject+JJKVOIMP.m
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import "NSObject+JJKVOIMP.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JJKVOInfoModel.h"


NSString *const JJKVO_CLASS_PREFIX = @"JJKVOClass_";
const char *JJKVO_ASSOCIATION_KEY = "JJKVO_ASSOCIATION_KEY";

@implementation NSObject (JJKVOIMP)

/// 根据 keyPath 获取 setter 方法名
- (NSString *)setterNameForKeyPath:(NSString *)keyPath {
    // setKeyPath: / _setKeyPath: / setIsKeyPath:
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
    if (![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSString *prefix = nil;
    for (NSString *temp in [self setterPrefixes]) {
        if ([setter hasPrefix:temp]) {
            prefix = temp;
            break;
        }
    }
    
    if (!prefix) {
        return prefix;
    }
    
    NSRange range = NSMakeRange(prefix.length, setter.length - prefix.length);
    NSString *keyPath = [setter substringWithRange:range];
    NSString *firstLetter = [[keyPath substringToIndex:1] lowercaseString];
    NSString *tailLetters = [keyPath substringFromIndex:1];
    keyPath = [NSString stringWithFormat:@"%@%@", firstLetter, tailLetters];
    NSLog(@" %s -- keyPath: %@", __func__, keyPath);
    
    return keyPath;
}

/// 方法是否存在
- (BOOL)isMethodExist:(NSString *)selName {
    unsigned int count = 0;
    Class cls = object_getClass(self);
    Method *methodList = class_copyMethodList(cls, &count);
    for (NSInteger i = 0; i < count; i++) {
        Method method = methodList[i];
        if ([selName isEqualToString:NSStringFromSelector(method_getName(method))]) {
            return YES;
        }
    }
    
    return NO;
}

/// 创建 KVO 子类
- (void)createKVOSubclass {
    NSString *kvoClsName = [self KVOClassName];
    Class cls = NSClassFromString(kvoClsName);
    if (!cls) {
        Class cls = objc_allocateClassPair([self class], kvoClsName.UTF8String, 0);
        objc_registerClassPair(cls);
        NSLog(@"register cls: %@", cls);
    } else {
        NSLog(@"kvo class is already exist");
    }
}

/// isa-swizzling
- (void)makeIsaSwizzling {
    NSString *kvoClsName = [self KVOClassName];
    object_setClass(self, NSClassFromString(kvoClsName));
}

/// 重写 -class、-dealloc、-isKVO 方法
- (void)addCommonKVOMethods {
    Class kvoCls = NSClassFromString([self KVOClassName]);
    
    // - class
    NSString *clsMethodName = @"class";
    if (![self isMethodExist:clsMethodName]) {
        SEL selName = NSSelectorFromString(clsMethodName);
        Method method = class_getInstanceMethod([NSObject class], selName);
        BOOL result = class_addMethod(kvoCls, selName, (IMP)jj_class, method_getTypeEncoding(method));
        NSLog(@"add class method %@", result ? @"success": @"failed");
    } else {
        NSLog(@"class method already exist");
    }
}

/// 重写 setter
- (void)overrideSetterForKeyPath:(NSString *)keyPath {
    NSString *setterName = [self setterNameForKeyPath:keyPath];
    if ([self isMethodExist:setterName]) {
        NSLog(@"%@, is already exist", setterName);
        return;
    }
    
    SEL selName = NSSelectorFromString(setterName);
    Method method = class_getInstanceMethod([self class], selName);
    Class cls = NSClassFromString([self KVOClassName]);
    class_addMethod(cls, selName, (IMP)jj_class, method_getTypeEncoding(method));
}

/// 保存观察者信息
- (void)saveObserver:(id)observer forKeyPath:(NSString *)keyPath options:(JJKVOChangeOptions)options context:(void *)context handler:(JJKVOChangeHandler)handler {
    JJKVOInfoModel *info = [[JJKVOInfoModel alloc] init];
    info.observer = observer;
    info.option = options;
    info.context = context;
    info.handler = handler;
    
    NSMutableArray *array = [self savedObserverInfosForKeyPath:keyPath];
    for (JJKVOInfoModel *tempModel in array) {
        if ([tempModel.observer isEqual:observer] && tempModel.context == context) {
            NSLog(@"Already has the same observer");
            return;
        }
    }
    [array addObject:info];
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

- (NSString *)KVOClassName {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName hasPrefix:JJKVO_CLASS_PREFIX]) {
        return clsName;
    }
    
    NSString *kvoClsName = [NSString stringWithFormat:@"%@%@", JJKVO_CLASS_PREFIX, clsName];
    return kvoClsName;
}

- (NSMutableDictionary *)savedObserverInfo {
    NSMutableDictionary *infoDic = objc_getAssociatedObject(self, JJKVO_ASSOCIATION_KEY);
    if (!infoDic) {
        infoDic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, JJKVO_ASSOCIATION_KEY, infoDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return infoDic;
}

- (NSMutableArray *)savedObserverInfosForKeyPath:(NSString *)keyPath {
    NSMutableDictionary *infoDic = [self savedObserverInfo];
    NSMutableArray *array = infoDic[keyPath];
    if (!array) {
        array = [NSMutableArray array];
        infoDic[keyPath] = array;
    }
    return array;
}

Class jj_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

@end
