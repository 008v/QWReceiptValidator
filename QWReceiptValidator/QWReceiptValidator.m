//
//  QWReceiptValidator.m
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import "QWReceiptValidator.h"
#import "NSError+QWReceiptValidator.h"
#import "x509.h"

@interface QWReceiptValidator ()

@property (nonatomic, strong) Success successBlock;
@property (nonatomic, strong) Failure failureBlock;
@property (nonatomic, strong) NSString *bundleVersion;
@property (nonatomic, strong) NSString *bundleIdentifier;

@end

@implementation QWReceiptValidator

+ (instancetype)sharedInstance
{
    static QWReceiptValidator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion tryAgain:(BOOL)tryAgain success:(Success)successBlock failure:(Failure)failureBlock
{
    self.bundleVersion = bundleVersion;
    self.bundleIdentifier = bundleIdentifier;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;

    /*
        Locate the receipt.
        If no receipt is present, validation fails.
     */
    NSURL *receiptURL = [NSBundle mainBundle].appStoreReceiptURL;
    if(![[NSFileManager defaultManager] fileExistsAtPath:receiptURL.path])
    {
        [self requestNewReceipt];
        return;
    }
    
    /*
        Validate the receipt
     */
    [self verifyReceiptWithURL:receiptURL success:_successBlock failure:^(NSError *error) {
        if(tryAgain)
        {
            [self requestNewReceipt];
        }
        else
        {
            if(self->_failureBlock)
            {
                self->_failureBlock(error);
            }
            return;
        }
    }];
}

- (void)requestNewReceipt
{
    SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
    receiptRefreshRequest.delegate = self;
    [receiptRefreshRequest start];
}

- (void)verifyReceiptWithURL:(NSURL *)receiptURL success:(Success)successBlock failure:(Failure)failureBlock
{
    // Parse the receipt with signature validation
    QWReceipt *receipt = [[QWReceipt alloc] initWithReceiptURL:receiptURL];
    
    // If it failed return
    if(!receipt)
    {
        if(failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeCouldNotParseAppStoreReceipt
                                     errorDescription:@"Receipt could not be parsed to a NSDictionary"
                                   errorFailureReason:@""
                              errorRecoverySuggestion:@""];
            failureBlock(error);
        }
        return;
    }
    
    /*
        Verify that the bundle identifier in the receipt matches a hard-coded constant containing the CFBundleIdentifier value you expect in the Info.plist file.
        If they do not match, validation fails.
     */
    if(![_bundleIdentifier isEqualToString:receipt.bundle_id])
    {
        if(failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeBundleIdentifierInvalid
                                     errorDescription:@"Bundle identifier invalid"
                                   errorFailureReason:@""
                              errorRecoverySuggestion:@"Make sure the passed bundle identifier matches that of the info.plist"];
            failureBlock(error);
        }
        return;
    }
    
    /*
        Verify that the version identifier string in the receipt matches a hard-coded constant containing the CFBundleShortVersionString value (for macOS) or the CFBundleVersion value (for iOS) that you expect in the Info.plist file.
        If they do not match, validation fails.
     */
    if(![_bundleVersion isEqualToString:receipt.application_version])
    {
        if(failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeVersionNumberInvalid
                                     errorDescription:@"Version number invalid"
                                   errorFailureReason:@""
                              errorRecoverySuggestion:@"Make sure the passed version number matches that of the info.plist"];
            failureBlock(error);
        }
        return;
    }
    
    /*
        Compute the Hash of the GUID
     
        In macOS, use the method described in Get the GUID in macOS to fetch the computer’s GUID.
        In iOS, use the value returned by the identifierForVendor property of UIDevice as the computer’s GUID.
        To compute the hash, first concatenate the GUID value with the opaque value (the attribute of type 4) and the bundle identifier. Use the raw bytes from the receipt without performing any UTF-8 string interpretation or normalization. Then compute the SHA-1 hash of this concatenated series of bytes.
     */
    
    // To further validate get the UUID of the current device
    unsigned char uuidBytes[16];
    NSUUID *vendorUUID = [UIDevice currentDevice].identifierForVendor;
    [vendorUUID getUUIDBytes:uuidBytes];
    
    // Build up the data in order appending the data from the receipt
    NSMutableData *input = [NSMutableData data];
    [input appendBytes:uuidBytes length:sizeof(uuidBytes)];
    [input appendData:receipt.opaqueValue];
    [input appendData:receipt.bundleIdentifierData];
    
    // Hash the data
    NSMutableData *hash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
    SHA1(input.bytes, input.length, hash.mutableBytes);
    
    /*
        Compute the hash of the GUID as described in Compute the Hash of the GUID.
        If the result does not match the hash in the receipt, validation fails.
     */
    if(![hash isEqualToData:receipt.sha1hash])
    {
        if(failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeAppReceiptInvalid
                                     errorDescription:@"Receipt hash invalid"
                                   errorFailureReason:@""
                              errorRecoverySuggestion:@""];
            failureBlock(error);
        }
        return;
    }
    
    // If an expiration date is present, check it
    if (receipt.expiration_date) {
        NSDate *currentDate = [NSDate date];
        if ([receipt.expiration_date compare:currentDate] == NSOrderedAscending) {
            if(failureBlock)
            {
                NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                     code:QWErrorCodeAppReceiptInvalid
                                         errorDescription:@"Receipt expiration date invalid"
                                       errorFailureReason:@""
                                  errorRecoverySuggestion:@""];
                failureBlock(error);
            }
            return;
        }
    }
    
    // Success
    if (successBlock)
    {
        successBlock(receipt);
    }
}

#pragma mark - SKRequestDelegate methods

- (void)requestDidFinish:(SKRequest *)request
{
    NSString  *appReceiptPath = [NSBundle mainBundle].appStoreReceiptURL.path;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:appReceiptPath])
    {
        [self validateReceiptWithBundleIdentifier:_bundleIdentifier bundleVersion:_bundleVersion tryAgain:NO success:_successBlock failure:_failureBlock];
    }
    else
    {
        if(_failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeCouldNotRefreshAppReceipt
                                     errorDescription:@"Receipt request complete but there is still no receipt"
                                   errorFailureReason:@"This can happen if the user cancels the login screen for the store"
                              errorRecoverySuggestion:@""];
            _failureBlock(error);
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSString *appRecPath = [NSBundle mainBundle].appStoreReceiptURL.path;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:appRecPath])
    {
        if(_failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeAppReceiptInvalid
                                     errorDescription:@"The existing receipt is invalid"
                                   errorFailureReason:@"There is an existing receipt but failed to get a new one"
                              errorRecoverySuggestion:@""];
            _failureBlock(error);
        }
    }
    else
    {
        if(_failureBlock)
        {
            NSError *error = [NSError errorWithDomain:receiptValidatorDomain
                                                 code:QWErrorCodeNoAppReceipt
                                     errorDescription:@"There is no existing receipt"
                                   errorFailureReason:@"Unable to request a new receipt"
                              errorRecoverySuggestion:@""];
            _failureBlock(error);
        }
    }
}

@end
