//
//  NSObject+JJKVO.h
//  KVODemo
//
//  Created by LZC on 2020/11/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^JJKVOChangeHandler)(NSDictionary *change, void *context);

typedef NS_ENUM(NSUInteger, JJKVOChangeOptions) {
    JJKVOChangeOptionNew = 1 << 0,
    JJKVOChangeOptionOld = 1 << 1,
};

@interface NSObject (JJKVO)

- (void)jj_addObserver:(NSObject *)observer
         forKeyPath:(NSString *)keyPath
            options:(JJKVOChangeOptions)options
            context:(nullable void *)context
  completionHandler:(JJKVOChangeHandler)handler;

- (void)jj_removeObserver:(id)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));

- (void)jj_removeObserver:(id)observer forKeyPath:(NSString *)keyPath;

- (void)jj_removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
