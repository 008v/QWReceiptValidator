//
//  NSError+QWReceiptValidator .h
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

@import Foundation;

static NSString *receiptValidatorDomain = @"ReceiptValidatorDomain";

typedef NS_ENUM(NSInteger, QWErrorCode) {
    QWErrorCodePaymentQueueCanNotMakePayments = 0,
    QWErrorCodeVersionNumberInvalid,
    QWErrorCodeBundleIdentifierInvalid,
    QWErrorCodeCouldNotParseAppStoreReceipt,
    QWErrorCodeCouldNotValidateReceipt,
    QWErrorCodeCouldNotRefreshAppReceipt,
    QWErrorCodeCouldNotLoadAppleRootCertificate,
    QWErrorCodeInvalidApplicationReceiptSignature,
    QWErrorCodeNoAppReceipt,
    QWErrorCodeAppReceiptInvalid,
};

@interface NSError (Additions)

//Helper method to ease creation of an error by not having to remember the keys for the user info dictionary
+ (NSError *)errorWithDomain:(NSString *)domain code:(QWErrorCode)code errorDescription:(NSString *)errorDescription errorFailureReason:(NSString *)errorFailureReason errorRecoverySuggestion:(NSString *)errorRecoverySuggestion;

//Helper method to return the full description of an NSError as one string
- (NSString *)fullDescription;

@end
