//
//  FMViewController.h
//  BarCodeTest
//
//  Created by Fredrick Myers on 5/14/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FMViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startBarButtonItem;

- (IBAction)startStopReading:(UIBarButtonItem *)sender;

@end
