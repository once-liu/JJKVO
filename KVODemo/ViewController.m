//
//  ViewController.m
//  KVODemo
//
//  Created by LZC on 2020/10/21.
//

#import "ViewController.h"
#import "Person.h"
#import "Student.h"

@interface ViewController ()

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) Student *stu;

@end

@implementation ViewController

static void *PersonContext = &PersonContext;
static void *StudentContext = &StudentContext;

- (void)dealloc {
    [self.person removeObserver:self forKeyPath:@"name"];
    [self.stu removeObserver:self forKeyPath:@"name"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.person removeObserver:self forKeyPath:@"name"];
    [self.stu removeObserver:self forKeyPath:@"name"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
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



@end
