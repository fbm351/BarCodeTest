//
//  FMProduct.h
//  BarCodeTest
//
//  Created by Fredrick Myers on 5/15/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMProduct : NSObject

@property (strong, nonatomic) NSString *UPC;
@property (strong, nonatomic) NSString *name;

- (instancetype)initWithUPC:(NSString *)upc;

@end
