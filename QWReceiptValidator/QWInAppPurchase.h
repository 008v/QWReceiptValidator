//
//  QWInAppPurchase.h
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QWInAppPurchase : NSObject

// The number of items purchased.
@property (nonatomic, strong, readonly, nonnull) NSNumber *quantity;

// The product identifier of the item that was purchased.
@property (nonatomic, strong, readonly, nonnull) NSString *product_id;

// The transaction identifier of the item that was purchased.
@property (nonatomic, strong, readonly, nonnull) NSString *transaction_id;

// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
@property (nonatomic, strong, readonly, nonnull) NSString *original_transaction_id;

// The date and time that the item was purchased.
@property (nonatomic, strong, readonly, nonnull) NSDate *purchase_date;

// For a transaction that restores a previous transaction, the date of the original transaction.
@property (nonatomic, strong, readonly, nonnull) NSDate *original_purchase_date;

// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT.
@property (nonatomic, strong, readonly, nullable) NSDate *expires_date;

// For an auto-renewable subscription, whether or not it is in the introductory price period.
@property (nonatomic, strong, readonly, nullable) NSNumber *is_in_intro_offer_period;

// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
@property (nonatomic, strong, readonly, nullable) NSDate *cancellation_date;

// The primary key for identifying subscription purchases.
// FIXME: web_order_line_item_id get a incorrect value.
@property (nonatomic, strong, readonly, nullable) NSNumber *web_order_line_item_id;


- (QWInAppPurchase * _Nonnull)initWithData:(NSData * _Nonnull)inAppPurchasesData;

- (NSDictionary * _Nonnull)fullDescription;

@end
