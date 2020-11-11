//
//  Person.m
//  KVODemo
//
//  Created by LZC on 2020/10/21.
//

#import "Person.h"

@interface Person ()



@end

@implementation Person

//+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
//    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
//    if ([key isEqualToString:@"progress"]) {
//        NSArray *dependKeys = @[@"totalBytes", @"completedBytes"];
//        keyPaths = [keyPaths setByAddingObjectsFromArray:dependKeys];
//    }
//    return keyPaths;
//}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingProgress
{
    return [NSSet setWithObjects:@"totalBytes", @"completedBytes", nil];
}

- (NSString *)progress {
    if (0 == self.totalBytes || 0 == self.completedBytes) {
        return @"0";
    }
    
    double progress = (double)self.completedBytes / self.totalBytes * 100;
    if (progress > 100)
        progress = 100.;
    
    return [NSString stringWithFormat:@"%d%%", (int)ceil(progress)];
}

@end
