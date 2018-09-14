//
//  NSError+QWReceiptValidator.m
//  PolyPuzzle
//
//  Created by WEI QIN on 2018/9/13.
//  Copyright © 2018 WEI QIN. All rights reserved.
//

#import "NSError+QWReceiptValidator.h"

@implementation NSError (Additions)

+ (NSError *)errorWithDomain:(NSString *)domain code:(QWErrorCode)code errorDescription:(NSString *)errorDescription errorFailureReason:(NSString *)errorFailureReason errorRecoverySuggestion:(NSString *)errorRecoverySuggestion
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey : errorDescription,
                               NSLocalizedFailureReasonErrorKey : errorFailureReason,
                               NSLocalizedRecoverySuggestionErrorKey : errorRecoverySuggestion
                               };
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

- (NSString *)fullDescription
{
    return [NSString stringWithFormat:@"\nFailure reason : %@\n   Description : %@\n    Suggestion : %@",
            ![self.localizedFailureReason isEqualToString:@""]  ? self.localizedFailureReason : @"N/A",
            ![self.localizedDescription isEqualToString:@""] ? self.localizedDescription : @"N/A",
            ![self.localizedRecoverySuggestion isEqualToString:@""] ? self.localizedRecoverySuggestion : @"N/A"];
}
@end
