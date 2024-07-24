//
//  RELEASEBIRDViewController.m
//  relasebird-ios-sdk
//
//  Created by czillmann on 07/01/2024.
//  Copyright (c) 2024 czillmann. All rights reserved.
//

#import "RELEASEBIRDViewController.h"
#import "RELEASEBIRDViewController.h"
#import "Releasebird.h"

@interface RELEASEBIRDViewController ()

@end

@implementation RELEASEBIRDViewController

- (void)viewDidLoad
{
    //[[Releasebird sharedInstance] hello];
    // [[Releasebird sharedInstance] showButton];
    [super viewDidLoad];
    [[Releasebird sharedInstance] showButton:[NSString stringWithFormat:@"1cad2c1b6d7842fd937469ce3ac42ba2"]];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
   
    // Dispose of any resources that can be recreated.
}


@end
