//
//  QWReceipt.h
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWInAppPurchase.h"

@interface QWReceipt : NSObject

@property (nonatomic, strong, readonly, nonnull) NSString   *bundle_id;
@property (nonatomic, strong, readonly, nonnull) NSString   *application_version;
@property (nonatomic, strong, readonly, nonnull) NSData     *opaqueValue;
@property (nonatomic, strong, readonly, nonnull) NSData     *sha1hash;
@property (nonatomic, strong, readonly, nonnull) NSString   *original_application_version;
@property (nonatomic, strong, readonly, nonnull) NSDate     *receipt_creation_date;
@property (nonatomic, strong, readonly, nullable) NSDate    *expiration_date;
@property (nonatomic, strong, readonly, nonnull) NSArray<QWInAppPurchase *> *in_app;

//This is needed for hash generation
@property (nonatomic, strong, readonly, nonnull) NSData     *bundleIdentifierData;


- (QWReceipt *)initWithReceiptURL:(NSURL *)receiptURL;

- (NSDictionary *)fullDescription;

@end
