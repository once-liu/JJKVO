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

- (void)removeKVOObserver:(id)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    NSMutableDictionary *infoDic = [self savedObserverInfo];
    NSArray *keyArray = [infoDic allKeys];
    
    if (!observer) {
        // 移除当前对象的所有观察者
        for (NSString *tempKey in keyArray) {
            NSMutableArray <JJKVOInfoModel *> *array = infoDic[tempKey];
            [array enumerateObjectsUsingBlock:^(JJKVOInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.handler = nil;
            }];
            [array removeAllObjects];
        }
        return;
    }
    
    if (!keyPath && context == NULL) {
        // 移除当前对象的指定观察者
        for (NSString *tempKey in keyArray) {
            NSMutableArray <JJKVOInfoModel *> *array = infoDic[tempKey];
            for (NSInteger i = 0; i < array.count; i++) {
                JJKVOInfoModel *model = array[i];
                if ([model.observer isEqual:observer]) {
                    model.handler = nil;
                    [array removeObject:model];
                }
            }
        }
        return;
    }
    
    // 移除当前对象的指定观察者，指定 keyPath，指定 context
    if (keyPath) {
        NSMutableArray <JJKVOInfoModel *> *array = infoDic[keyPath];
        for (NSInteger i = 0; i < array.count; i++) {
            JJKVOInfoModel *model = array[i];
            if ([model.observer isEqual:observer]) {
                if (context) {
                    if (model.context == context) {
                        model.handler = nil;
                        [array removeObject:model];
                    }
                } else {
                    model.handler = nil;
                    [array removeObject:model];
                }
            }
        }
    } else if (context) {
        for (NSString *tempKey in keyArray) {
            NSMutableArray <JJKVOInfoModel *> *array = infoDic[keyPath];
            for (NSInteger i = 0; i < array.count; i++) {
                JJKVOInfoModel *model = array[i];
                if ([model.observer isEqual:observer] && context == model.context) {
                    model.handler = nil;
                    [array removeObject:model];
                }
            }
        }
    }
    
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


- (void)jj_dealloc {
    // 1 移除所有观察者；2 销毁关联对象；3 调用系统 dealloc
    Class cls = object_getClass(self);
    NSString *clsName = NSStringFromClass(cls);
    if ([clsName hasPrefix:JJKVO_CLASS_PREFIX]) {
        [self removeObserver:nil forKeyPath:nil];
        
        objc_setAssociatedObject(self, JJKVO_ASSOCIATION_KEY, nil, OBJC_ASSOCIATION_ASSIGN);
        
        // isa 指回父类
        Class superCls = class_getSuperclass(object_getClass(self));
        object_setClass(self, superCls);
    }
    
    // system dealloc
    [self jj_dealloc];
}

static void jj_setter(id self, SEL _cmd, id newValue) {
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *keyPath = [self keyPathForSetterName:setter];
    
    NSMutableDictionary *change = [NSMutableDictionary dictionaryWithCapacity:2];
    id oldValue = [self valueForKey:keyPath];
    if (oldValue) {
        change[NSKeyValueChangeOldKey] = oldValue;
    }
    
    // call super setter
    SEL superSetter = NSSelectorFromString(setter);
    struct objc_super superMsg = {
        .receiver = self,
        .super_class = [self class]
    };
    void (*jj_msgSendSuper)(void *, SEL, id) = (void *)objc_msgSendSuper;
    jj_msgSendSuper(&superMsg, superSetter, newValue);
    
    if (newValue) {
        change[NSKeyValueChangeNewKey] = newValue;
    }
    
    NSArray *array = [self savedObserverInfosForKeyPath:keyPath];
    for (JJKVOInfoModel *model in array) {
        if (model.handler) {
            model.handler(change, model.context);
        }
    }
}


// MARK: Class Method

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self jj_exchangeInstanceIMP:NSSelectorFromString(@"dealloc")
                      newInstanceIMP:@selector(jj_dealloc)];
    });
}

+ (BOOL)jj_exchangeInstanceIMP:(SEL)orgSEL newInstanceIMP:(SEL)swizzledSEL {
    Class cls = self;
    Method orgMethod = class_getInstanceMethod(cls, orgSEL);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSEL);
    
    if (!swizzledMethod) {
        return NO;
    }
    
    if (!orgMethod) {
        class_addMethod(cls, orgSEL, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    }
    
    BOOL didAddMethod = class_addMethod(cls, orgSEL, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSEL, method_getImplementation(orgMethod), method_getTypeEncoding(orgMethod));
    } else {
        method_exchangeImplementations(orgMethod, swizzledMethod);
    }
    
    return YES;
}



@end
