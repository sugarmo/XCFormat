//
//  ViewController.m
//  SugarBox
//
//  Created by Steven Mok on 16/10/13.
//  Copyright © 2016年 ZAKER. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)openXcode:(id)sender {
    [[NSWorkspace sharedWorkspace] launchApplication:@"Xcode"];
}

@end
