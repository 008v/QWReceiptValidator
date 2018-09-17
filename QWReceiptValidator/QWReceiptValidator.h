//
//  QWReceiptValidator.h
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

@import Foundation;
@import StoreKit;

#import "QWReceipt.h"

typedef void(^Success)(QWReceipt * _Nonnull receipt);
typedef void(^Failure)(NSError * _Nonnull error);

@interface QWReceiptValidator : NSObject <SKProductsRequestDelegate>

+ (instancetype _Nonnull)sharedInstance;

/**
 Validate the receipt

 @param bundleIdentifier Bundle identifier (must be hard-coded). Use this value to validate if the receipt was indeed generated for your app.
 @param bundleVersion Bundle version (must be hard-coded). default is nil, skip validation.
 @param tryAgain Determine whether refresh receipt from AppStore when the receipt is invalid or validation is failed.
 @param successBlock A block of code that executes when validation is successful.
 @param failureBlock A block of code that executes when validation is failed.
 */
- (void)validateReceiptWithBundleIdentifier:( NSString * _Nonnull)bundleIdentifier bundleVersion:(NSString * _Nullable)bundleVersion tryAgain:(BOOL)tryAgain success:(Success _Nullable)successBlock failure:(Failure _Nullable)failureBlock;

@end
