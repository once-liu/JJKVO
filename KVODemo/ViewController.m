//
//  ViewController.m
//  KVODemo
//
//  Created by LZC on 2020/10/21.
//

#import "ViewController.h"
#import "Person.h"
#import "Student.h"

#import <objc/runtime.h>
#import "NSObject+JJKVO.h"

@interface ViewController ()

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) Student *stu;

@end

@implementation ViewController

static void *PersonContext = &PersonContext;
static void *StudentContext = &StudentContext;

- (void)dealloc {
    [self jj_removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self customKVOImp];
    
}

- (void)customKVOImp {
    Person *person = [[Person alloc] init];
    person.name = @"Mike";
    self.person = person;
    
    [self printClasses:[Person class]];
    [self printMethods:[self.person class]];
    
    [person jj_addObserver:self
                forKeyPath:@"name"
                   options:(JJKVOChangeOptionNew)
                   context:NULL
         completionHandler:^(NSDictionary * _Nonnull change, void * _Nonnull context) {
        NSLog(@" - change: %@", change);
    }];
    
    
    [self printClasses:[Person class]];
    [self printMethods:NSClassFromString(@"JJKVOClass_Person")];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSArray *names = @[@"Jake", @"Rose", @"Michel", @"Tom"];
    
    static NSInteger index = 0;
    self.person.name = names[index];
    index++;
    
    if (index >= names.count) index = 0;
}

- (void)printClasses:(Class)cls {
    int count = objc_getClassList(NULL, 0);
    NSMutableArray *results = [NSMutableArray arrayWithObject:cls];
    Class *classes = (Class *)malloc(sizeof(Class) * count);
    
    objc_getClassList(classes, count);
    
    for (int i = 0; i < count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [results addObject:classes[i]];
        }
    }
    NSLog(@"classes: %@", results);
    free(classes);
}

- (void)printMethods:(Class)cls {
    NSLog(@"Method: {");
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(cls, &count);
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        SEL sel = method_getName(method);
        IMP imp = method_getImplementation(method);
        NSLog(@"    %s - %p", NSStringFromSelector(sel).UTF8String, imp);
    }
    free(methodList);
    NSLog(@"}\n");
}


/**
- (void)systmeKVOImp {
    Person *person = [[Person alloc] init];
    person.name = @"Milk";
    self.person = person;
    
    Student *stu = [[Student alloc] init];
    stu.name = @"xiao hong";
    self.stu = stu;
    
    person.totalBytes = 10000;
    
    
    [person addObserver:self forKeyPath:@"progress" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:PersonContext];
//    [stu addObserver:self forKeyPath:@"name" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:StudentContext];
    
    
    person.completedBytes = 1500;
    person.completedBytes = 5000;
    person.completedBytes = 7000;
    
    person.name = @"Jack";
    stu.name = @"xiao lan";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    if ([keyPath isEqualToString:@"name"]) {
//        NSLog(@" change : %@", change);
//    }
    if (object == self.person) {
        NSLog(@" per change : %@\n, object: %@", change, object);
    }
    if (context == StudentContext) {
        NSLog(@" stu change : %@\n, object: %@", change, object);
    }
}
 */



@end
