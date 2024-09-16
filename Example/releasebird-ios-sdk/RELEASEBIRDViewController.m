//
//  RELEASEBIRDViewController.m
//  releasebird-ios-sdk
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

    [[Releasebird sharedInstance] initialize:@"1cad2c1b6d7842fd937469ce3ac42ba2" showButton:true];
    NSDictionary *userDictionary = @{
                @"firstname": @"John",
                @"lastname": @"Doe",
                @"email": @"johndoe@example.com",
                @"external_user_id": @"3456",
                @"company": @{
                    @"externalId": @"1234",
                    @"company_name": @"Example company"
                }
            };
    [[Releasebird sharedInstance] identify:userDictionary];

    // 1. Button erstellen
    UIButton *myButton = [UIButton buttonWithType:UIButtonTypeSystem];

    // 2. Eigenschaften des Buttons festlegen
    [myButton setTitle:@"Open Widget" forState:UIControlStateNormal];
    myButton.backgroundColor = [UIColor lightGrayColor];

    // 3. Position des Buttons festlegen (Rahmen)
    myButton.frame = CGRectMake(100, 100, 150, 50);  // x, y, width, height

    // 4. Button zur View hinzufügen
    [self.view addSubview:myButton];

    // 5. Optionale Aktion für den Button hinzufügen
    [myButton addTarget:self
                 action:@selector(buttonTapped:)
       forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonTapped:(UIButton *)sender {
    [[Releasebird sharedInstance] showWidget];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
   
    // Dispose of any resources that can be recreated.
}


@end
