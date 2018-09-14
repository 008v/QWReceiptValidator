//
//  QWInAppPurchase.m
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import "QWInAppPurchase.h"

#import "asn1.h"

typedef NS_ENUM(NSInteger, ASN1FieldTypeIAP)
{
    ASN1FieldTypeIAPQuantity = 1701,
    ASN1FieldTypeIAPProductIdentifier = 1702,
    ASN1FieldTypeIAPTransactionIdentifier = 1703,
    ASN1FieldTypeIAPPurchaseDate = 1704,
    ASN1FieldTypeIAPOriginalTransactionIdentifier = 1705,
    ASN1FieldTypeIAPOriginalPurchaseDate = 1706,
    ASN1FieldTypeIAPSubscriptionExpirationDate = 1708,
    ASN1FieldTypeIAPWebOrderLineItemID = 1711,
    ASN1FieldTypeIAPCancellationDate = 1712,
    ASN1FieldTypeIAPSubscriptionIntroductoryPricePeriod = 1719
};

@interface QWInAppPurchase ()

@property (nonatomic, strong) NSNumber *quantity;
@property (nonatomic, strong) NSString *product_id;
@property (nonatomic, strong) NSString *transaction_id;
@property (nonatomic, strong) NSString *original_transaction_id;
@property (nonatomic, strong) NSDate *purchase_date;
@property (nonatomic, strong) NSDate *original_purchase_date;
@property (nonatomic, strong) NSDate *expires_date;
@property (nonatomic, strong) NSNumber *is_in_intro_offer_period;
@property (nonatomic, strong) NSDate *cancellation_date;
@property (nonatomic, strong) NSNumber *web_order_line_item_id;

@end

@implementation QWInAppPurchase

- (QWInAppPurchase *)initWithData:(NSData *)inAppPurchasesData
{
    int type = 0;
    int xclass = 0;
    long length = 0;
    
    NSUInteger dataLenght = inAppPurchasesData.length;
    const uint8_t *p = inAppPurchasesData.bytes;
    
    const uint8_t *end = p + dataLenght;
    
    QWInAppPurchase *iapReceipt = [[QWInAppPurchase alloc] init];
    
    while (p < end)
    {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
        const uint8_t *set_end = p + length;
        
        if(type != V_ASN1_SET)
        {
            break;
        }
        
        while (p < set_end)
        {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            
            if(type != V_ASN1_SEQUENCE)
            {
                break;
            }
            
            const uint8_t *seq_end = p + length;
            
            int attr_type = 0;
            int attr_version = 0;
            
            // Attribute type
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            
            if(type == V_ASN1_INTEGER)
            {
                if(length == 1)
                {
                    attr_type = p[0];
                }
                else if(length == 2)
                {
                    attr_type = p[0] * 0x100 + p[1];
                }
            }
            
            p += length;
            
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            
            if(type == V_ASN1_INTEGER && length == 1)
            {
                attr_version = p[0];
            }
            
            p += length;
            
            // Only parse attributes we're interested in
            if(attr_type == ASN1FieldTypeIAPQuantity ||
               attr_type == ASN1FieldTypeIAPProductIdentifier ||
               attr_type == ASN1FieldTypeIAPTransactionIdentifier ||
               attr_type == ASN1FieldTypeIAPPurchaseDate ||
               attr_type == ASN1FieldTypeIAPOriginalTransactionIdentifier ||
               attr_type == ASN1FieldTypeIAPOriginalPurchaseDate ||
               attr_type == ASN1FieldTypeIAPSubscriptionExpirationDate ||
               attr_type == ASN1FieldTypeIAPWebOrderLineItemID ||
               attr_type == ASN1FieldTypeIAPCancellationDate ||
               attr_type == ASN1FieldTypeIAPSubscriptionIntroductoryPricePeriod)
            {
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                
                if(type == V_ASN1_OCTET_STRING)
                {
                    // Integers
                    if(attr_type == ASN1FieldTypeIAPQuantity ||
                       attr_type == ASN1FieldTypeIAPSubscriptionIntroductoryPricePeriod ||
                       attr_type == ASN1FieldTypeIAPWebOrderLineItemID)
                    {
                        int num_type = 0;
                        long num_length = 0;
                        const uint8_t *num_p = p;
                        ASN1_get_object(&num_p, &num_length, &num_type, &xclass, seq_end - num_p);
                        
                        if(num_type == V_ASN1_INTEGER)
                        {
                            NSUInteger quantity = 0;
                            if(num_length)
                            {
                                quantity += num_p[0];
                                
                                if(num_length > 1)
                                {
                                    quantity += num_p[1] * 0x100;
                                    
                                    if(num_length > 2)
                                    {
                                        
                                        quantity += num_p[2] * 0x10000;
                                        
                                        if(num_length > 3)
                                        {
                                            quantity += num_p[3] * 0x1000000;
                                        }
                                    }
                                }
                            }
                            
                            NSNumber *number = @(quantity);
                            
                            if(attr_type == ASN1FieldTypeIAPQuantity)
                            {
                                iapReceipt.quantity = number;
                            }
                            else if(attr_type == ASN1FieldTypeIAPSubscriptionIntroductoryPricePeriod)
                            {
                                iapReceipt.is_in_intro_offer_period = number;
                            }
                            else if(attr_type == ASN1FieldTypeIAPWebOrderLineItemID)
                            {
                                iapReceipt.web_order_line_item_id = number;
                            }
                        }
                    }
                    
                    // Strings
                    if(attr_type == ASN1FieldTypeIAPProductIdentifier ||
                       attr_type == ASN1FieldTypeIAPTransactionIdentifier ||
                       attr_type == ASN1FieldTypeIAPOriginalTransactionIdentifier ||
                       attr_type == ASN1FieldTypeIAPPurchaseDate ||
                       attr_type == ASN1FieldTypeIAPOriginalPurchaseDate ||
                       attr_type == ASN1FieldTypeIAPSubscriptionExpirationDate ||
                       attr_type == ASN1FieldTypeIAPCancellationDate)
                    {
                        
                        int str_type = 0;
                        long str_length = 0;
                        const uint8_t *str_p = p;
                        ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                        
                        if(str_type == V_ASN1_UTF8STRING)
                        {
                            NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                        length:(NSUInteger)str_length
                                                                      encoding:NSUTF8StringEncoding];
                            
                            switch (attr_type)
                            {
                                case ASN1FieldTypeIAPProductIdentifier:
                                    iapReceipt.product_id = string;
                                    break;
                                case ASN1FieldTypeIAPTransactionIdentifier:
                                    iapReceipt.transaction_id = string;
                                    break;
                                case ASN1FieldTypeIAPOriginalTransactionIdentifier:
                                    iapReceipt.original_transaction_id = string;
                                    break;
                            }
                        }
                        
                        if(str_type == V_ASN1_IA5STRING)
                        {
                            NSString *dateAsString = [[NSString alloc] initWithBytes:str_p
                                                                              length:(NSUInteger)str_length
                                                                            encoding:NSASCIIStringEncoding];
                            
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
                            dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                            dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                        
                            NSDate *date = [dateFormatter dateFromString:dateAsString];
                            
                            switch (attr_type)
                            {
                                case ASN1FieldTypeIAPPurchaseDate:
                                    iapReceipt.purchase_date = date;
                                    break;
                                case ASN1FieldTypeIAPOriginalPurchaseDate:
                                    iapReceipt.original_purchase_date = date;
                                    break;
                                case ASN1FieldTypeIAPSubscriptionExpirationDate:
                                    iapReceipt.expires_date = date;
                                    break;
                                case ASN1FieldTypeIAPCancellationDate:
                                    iapReceipt.cancellation_date = date;
                                    break;
                            }
                        }
                    }
                }
                
                p += length;
            }
            
            //Skip any remaining fields in this SEQUENCE
            while (p < seq_end)
            {
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                p += length;
            }
        }
        
        //Skip any remaining fields in this SET
        while (p < set_end)
        {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            p += length;
        }
    }
    
    return iapReceipt;
}

- (NSDictionary *)fullDescription
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    dictionary[@"quantity"] = (self.quantity) ? self.quantity : @"";
    dictionary[@"product_id"] = (self.product_id) ? self.product_id : @"";
    dictionary[@"transaction_id"] = (self.transaction_id) ? self.transaction_id : @"";
    dictionary[@"original_transaction_id"] = (self.original_transaction_id) ? self.original_transaction_id : @"";
    dictionary[@"purchase_date"] = (self.purchase_date) ? self.purchase_date : @"";
    dictionary[@"original_purchase_date"] = (self.original_purchase_date) ? self.original_purchase_date : @"";
    dictionary[@"expires_date"] = (self.expires_date) ? self.expires_date : @"";
    dictionary[@"is_in_intro_offer_period"] = (self.is_in_intro_offer_period) ? self.is_in_intro_offer_period : @"";
    dictionary[@"cancellation_date"] = (self.cancellation_date) ? self.cancellation_date : @"";
    dictionary[@"web_order_line_item_id"] = (self.web_order_line_item_id) ? self.web_order_line_item_id : @"";
    
    return dictionary;
}

@end
