//
//  SGBViewController.m
//  XCFormat
//
//  Created by Steven Mok on 16/10/13.
//  Copyright © 2016年 ZAKER. All rights reserved.
//

#import "SGBViewController.h"

@implementation SGBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)editConfig:(id)sender
{
    NSString *plugInsPath = [NSBundle mainBundle].builtInPlugInsPath;
    if (plugInsPath && [[NSFileManager defaultManager] fileExistsAtPath:plugInsPath]) {
        NSBundle *plugInsBundle = [NSBundle bundleWithPath:plugInsPath];
        NSString *exPath = [plugInsBundle pathForResource:@"SourceExtension" ofType:@"appex"];
        if (exPath) {
            NSBundle *exbundle = [NSBundle bundleWithPath:exPath];
            NSString *cfgPath = [exbundle pathForResource:@"uncrustify" ofType:@"cfg"];
            if (cfgPath) {
                [[NSWorkspace sharedWorkspace] selectFile:cfgPath inFileViewerRootedAtPath:@""];
            }
        }
    }
}


- (IBAction)quit:(id)sender
{
    [NSApp terminate:nil];
}



@end
