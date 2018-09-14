//
//  QWReceipt.m
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import "QWReceipt.h"
#import "pkcs7.h"
#import "x509.h"

typedef NS_ENUM(NSInteger, ASN1FieldType)
{
    ASN1FieldTypeBundleIdentifier = 2,
    ASN1FieldTypeAppVersion = 3,
    ASN1FieldTypeOpaqueValue = 4,
    ASN1FieldTypeSHA1Hash = 5,
    ASN1FieldTypeReceiptCreationDate = 12,
    ASN1FieldTypeInAppPurchaseReceipt = 17,
    ASN1FieldTypeOriginalApplicationVersion = 19,
    ASN1FieldTypeReceiptExpirationDate = 21,
};

@interface QWReceipt ()

@property (nonatomic, strong) NSString *bundle_id;
@property (nonatomic, strong) NSString *application_version;
@property (nonatomic, strong) NSData *opaqueValue;
@property (nonatomic, strong) NSData *sha1hash;
@property (nonatomic, strong) NSArray<QWInAppPurchase *> *in_app;
@property (nonatomic, strong) NSString *original_application_version;
@property (nonatomic, strong) NSDate *receipt_creation_date;
@property (nonatomic, strong) NSDate *expiration_date;
@property (nonatomic, strong) NSData *bundleIdentifierData;

@end

@implementation QWReceipt

- (QWReceipt *)initWithReceiptURL:(NSURL *)receiptURL
{
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests();
    
    /* Loading the Receipt */
    
    // Load the receipt file
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    // Create a memory buffer to extract the PKCS #7 container
    BIO *receiptBIO = BIO_new(BIO_s_mem());
    BIO_write(receiptBIO, [receiptData bytes], (int) [receiptData length]);
    PKCS7 *receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
    if (!receiptPKCS7) {
        return nil;
    }
    
    // Check that the container has a signature
    if (!PKCS7_type_is_signed(receiptPKCS7)) {
        PKCS7_free(receiptPKCS7);
        return nil;
    }
    
    // Check that the signed container has actual data
    if (!PKCS7_type_is_data(receiptPKCS7->d.sign->contents)) {
        PKCS7_free(receiptPKCS7);
        return nil;
    }
    
    /* Verifying the Receipt Signature */

    // Load the Apple Root CA
    NSData * appleRootData = [self appleIncRootCertificate];
    
    int verifyReturnValue = 0;
    X509_STORE *store = X509_STORE_new();
    
    if(store)
    {
        const uint8_t *data = (uint8_t *)(appleRootData.bytes);
        X509 *appleCA = d2i_X509(NULL, &data, (long)appleRootData.length);
        
        if(appleCA)
        {
            BIO *payload = BIO_new(BIO_s_mem());
            X509_STORE_add_cert(store, appleCA);
            
            if(payload)
            {
                verifyReturnValue = PKCS7_verify(receiptPKCS7,NULL,store,NULL,payload,0);
                BIO_free(payload);
            }
            
            X509_free(appleCA);
        }
        
        X509_STORE_free(store);
    }
    
    EVP_cleanup();
    
    /*
        Verify that the receipt is properly signed by Apple.
        If it is not signed by Apple, validation fails.
     */
    if(verifyReturnValue != 1)
    {
        PKCS7_free(receiptPKCS7);
        return nil;
    }
    
    /* Parsing the Receipt */
    
    ASN1_OCTET_STRING *octets = receiptPKCS7->d.sign->contents->d.data;
    const uint8_t *p = octets->data;
    const uint8_t *end = p + octets->length;
    
    int type = 0;
    int xclass = 0;
    long length = 0;
    
    ASN1_get_object(&p, &length, &type, &xclass, end - p);
    
    if(type != V_ASN1_SET)
    {
        PKCS7_free(receiptPKCS7);
        return nil;
    }
    
    QWReceipt *receipt = [[QWReceipt alloc] init];
    
    NSMutableArray *inAppArray = [NSMutableArray array];
    
    // Loop through all the asn1c attributes
    while (p < end)
    {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
        if(type != V_ASN1_SEQUENCE)
        {
            break;
        }
        
        const uint8_t *seq_end = p + length;
        
        int attr_type = 0;
        int attr_version = 0;
        
        // Attribute type
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        
        if(type == V_ASN1_INTEGER && length == 1)
        {
            attr_type = p[0];
        }
        
        p += length;
        
        // Attribute version
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        
        if(type == V_ASN1_INTEGER && length == 1)
        {
            attr_version = p[0];
            attr_version = attr_version;
        }
        
        p += length;
        
        // Only parse attributes we're interested in
        if(attr_type == ASN1FieldTypeBundleIdentifier ||
           attr_type == ASN1FieldTypeAppVersion ||
           attr_type == ASN1FieldTypeOpaqueValue ||
           attr_type == ASN1FieldTypeSHA1Hash ||
           attr_type == ASN1FieldTypeReceiptCreationDate ||
           attr_type == ASN1FieldTypeInAppPurchaseReceipt ||
           attr_type == ASN1FieldTypeOriginalApplicationVersion ||
           attr_type == ASN1FieldTypeReceiptExpirationDate)
        {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            
            if(type == V_ASN1_OCTET_STRING)
            {
                NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
                
                // Bytes
                if(attr_type == ASN1FieldTypeBundleIdentifier || attr_type == ASN1FieldTypeOpaqueValue || attr_type == ASN1FieldTypeSHA1Hash)
                {
                    switch (attr_type)
                    {
                        case ASN1FieldTypeBundleIdentifier:
                            receipt.bundleIdentifierData = data;
                            break;
                        case ASN1FieldTypeOpaqueValue:
                            receipt.opaqueValue = data;
                            break;
                        case ASN1FieldTypeSHA1Hash:
                            receipt.sha1hash = data;
                            break;
                    }
                }
                
                // Strings
                if(attr_type == ASN1FieldTypeBundleIdentifier || attr_type == ASN1FieldTypeAppVersion || attr_type == ASN1FieldTypeOriginalApplicationVersion || attr_type == ASN1FieldTypeReceiptCreationDate || attr_type == ASN1FieldTypeReceiptExpirationDate)
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
                            case ASN1FieldTypeBundleIdentifier:
                                receipt.bundle_id = string;
                                break;
                            case ASN1FieldTypeAppVersion:
                                receipt.application_version = string;
                                break;
                            case ASN1FieldTypeOriginalApplicationVersion:
                                receipt.original_application_version = string;
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
                            case ASN1FieldTypeReceiptCreationDate:
                                receipt.receipt_creation_date = date;
                                break;
                            case ASN1FieldTypeReceiptExpirationDate:
                                receipt.expiration_date = date;
                                break;
                        }
                    }
                }
                
                // In-App purchases
                if(attr_type == ASN1FieldTypeInAppPurchaseReceipt)
                {
                    QWInAppPurchase *iapReceipt = [[QWInAppPurchase alloc] initWithData:data];
                    
                    [inAppArray addObject:iapReceipt];
                }
            }
            p += length;
        }
        
        // Skip any remaining fields in this SEQUENCE
        while (p < seq_end)
        {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            p += length;
        }
    }
    
    PKCS7_free(receiptPKCS7);
    
    receipt.in_app = [NSArray arrayWithArray:inAppArray];
    
    return receipt;
}

- (NSData *)appleIncRootCertificate
{
    return [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"]];
}

- (NSDictionary *)fullDescription
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    dictionary[@"bundle_id"] = (self.bundle_id) ? self.bundle_id : @"";
    dictionary[@"application_version"] = (self.application_version) ? self.application_version : @"";
    dictionary[@"opaqueValue"] = (self.opaqueValue) ? self.opaqueValue : @"";
    dictionary[@"sha1hash"] = (self.sha1hash) ? self.sha1hash : @"";
    dictionary[@"in_app"] = (self.in_app) ? self.in_app : @"";
    dictionary[@"original_application_version"] = (self.original_application_version) ? self.original_application_version : @"";
    dictionary[@"receipt_creation_date"] = (self.receipt_creation_date) ? self.receipt_creation_date : @"";
    dictionary[@"expiration_date"] = (self.expiration_date) ? self.expiration_date : @"";
    dictionary[@"bundleIdentifierData"] = (self.bundleIdentifierData) ? self.bundleIdentifierData : @"";
    
    return dictionary;
}

@end
