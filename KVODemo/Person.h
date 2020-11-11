//
//  Person.h
//  KVODemo
//
//  Created by LZC on 2020/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) unsigned long long totalBytes;
@property (nonatomic, assign) unsigned long long completedBytes;
@property (nonatomic, copy) NSString *progress;

@end

NS_ASSUME_NONNULL_END
