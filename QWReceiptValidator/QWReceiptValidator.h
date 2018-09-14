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

- (void)validateReceiptWithBundleIdentifier:( NSString * _Nonnull)bundleIdentifier bundleVersion:(NSString * _Nonnull)bundleVersion tryAgain:(BOOL)tryAgain success:(Success _Nullable)successBlock failure:(Failure _Nullable)failureBlock;

@end
