//
//  FMProduct.m
//  BarCodeTest
//
//  Created by Fredrick Myers on 5/15/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import "FMProduct.h"

@implementation FMProduct

- (instancetype)initWithUPC:(NSString *)upc
{
    self = [super init];
    if (self)
    {
        self.UPC = upc;
        self.name = nil;
    }
    return self;
}

@end
