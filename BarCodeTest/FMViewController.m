//
//  FMViewController.m
//  BarCodeTest
//
//  Created by Fredrick Myers on 5/14/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import "FMViewController.h"
#import "FMProduct.h"

@interface FMViewController ()

@property (nonatomic) BOOL isReading;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSMutableArray *upcs;
@property (weak, nonatomic) IBOutlet UILabel *productNameLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL didLookupUPC;

@end

@implementation FMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.isReading = NO;
    self.captureSession = nil;
    self.productNameLabel.text = @"";
    self.activityIndicator.hidden = YES;
    self.didLookupUPC = NO;
    
    [self playBeepSound];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startStopReading:(UIBarButtonItem *)sender
{
    if (!self.isReading)
    {
        if ([self startReading])
        {
            self.startBarButtonItem.title = @"Stop";
            self.statusLabel.text = @"Scanning for Barcode";
        }
    }
    else
    {
        [self stopReading];
        self.startBarButtonItem.title = @"Start!";
        self.statusLabel.text = @"QR Code Reader is not yet running…";
    }
    
    self.isReading = !self.isReading;
}

- (BOOL)startReading
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input)
    {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeUPCECode]];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.videoPreviewLayer.frame = self.viewPreview.layer.bounds;
    [self.viewPreview.layer addSublayer:self.videoPreviewLayer];
    
    [self.captureSession startRunning];
    
    self.productNameLabel.text = @"";
    
    return YES;
}

- (void)stopReading
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    [self.videoPreviewLayer removeFromSuperlayer];
    
    if (self.didLookupUPC)
    {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
    }
    self.didLookupUPC = NO;
    
}

- (void)playBeepSound
{
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"BallBounce" ofType:@"caf"];
    NSURL *beepURL = [NSURL URLWithString:beepFilePath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error)
    {
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    }
    else
    {
        self.audioPlayer.volume = 1.0;
        [self.audioPlayer prepareToPlay];
    }
}

- (void)lookUpUPC:(NSString *)upc
{

    NSLog(@"Look Up UPC %@", upc);
    NSString *urlString = [NSString stringWithFormat:@"http://www.searchupc.com/handlers/upcsearch.ashx?request_type=3&access_token=6FBA5499-0ABE-4653-ABB2-22B5CDFC38E2&upc=%@", upc];
    NSURL *upcLookupURL = [NSURL URLWithString:urlString];
    NSData *jsonData = [NSData dataWithContentsOfURL:upcLookupURL];
    NSMutableArray *products = [[NSMutableArray alloc] init];
    NSError *error = nil;
    
    NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    NSDictionary *item;
    NSLog(@"%@", dataDictionary);
    
    NSLog(@"Item count %lu", (unsigned long)[dataDictionary count]);
    for (id key in dataDictionary)
    {
        //NSLog(@"Key = %@", key);
        
        item = [dataDictionary objectForKey:key];
        FMProduct *product = [[FMProduct alloc] initWithUPC:upc];
        product.name = [item objectForKey:@"productname"];
        NSLog(@"Product Name: %@", product.name);
        [products addObject:product];
    }
    
    if ([products count] == 1)
    {
        FMProduct *product = [products firstObject];
        if (product.name == nil || [product.name isEqualToString:@" "])
        {
            NSLog(@"Nothing came back");
            [self.productNameLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Nothing Came Back" waitUntilDone:NO];
        }
        else
        {
            NSLog(@"Single Product with name: %@", product.name);
            [self.productNameLabel performSelectorOnMainThread:@selector(setText:) withObject:product.name waitUntilDone:NO];

        }
    }
    else if ([products count] > 1)
    {
        NSLog(@"Multiple products");
        NSLog(@"%@", products);
        [self.productNameLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Multiple Products" waitUntilDone:NO];

    }
    
    [self.activityIndicator performSelectorOnMainThread:@selector(setHidden:) withObject:@"YES" waitUntilDone:NO];
    [self.activityIndicator performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeEAN13Code] || [[metadataObj type] isEqualToString:AVMetadataObjectTypeUPCECode])
        {
            [self.statusLabel performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            //[self performSelectorOnMainThread:@selector(lookUpUPC:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            [self.startBarButtonItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            self.isReading = NO;
            
            if (self.audioPlayer)
            {
                [self.audioPlayer play];
            }
            self.didLookupUPC = YES;
            [self lookUpUPC:[metadataObj stringValue]];
        }
    }
}

@end
