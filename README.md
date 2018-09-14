# QWReceiptValidator
Validate In-App Purchase Receipt Locally


# 1. Setup OpenSSL Library
* Build your OpenSSL static library file
* Import .h and .a files into your project
* Set `Header Search Paths` and `User Header Search Paths`
* Add .a files into `Linked Frameworks and Libraries`

# 2. Copy `QWReceiptValidator` directory to your project

# 3. Validate Receipt
* Note: bundle id and version must be hardcoded.
```swift
let validator = QWReceiptValidator.sharedInstance()
        validator.validateReceipt(withBundleIdentifier: "your.Bundle.Id", bundleVersion: "1", tryAgain: true, success: { (receipt) in
            // Handle Success
            // TODO: Parse the in-apps data and deliver content
            /*
            for iap in receipt.in_app {
                if iap.cancellation_date == nil &&
                iap.expires_date != nil &&
                Date().compare(iap.original_purchase_date) == .orderedDescending &&
                Date().compare(iap.expires_date!) == .orderedAscending {
                // ...
            }
            */
        }) { (error) in
            // Handle Failure
        }
```
