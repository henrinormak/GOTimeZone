//
//  GOTimeZone.h
//  A lightweight wrapper around Google's Timezone API
//
//  GOTimeZone supports NSProgress, reporting the progress during
//  network activity
//
//  Copyright (c) 2014 Henri Normak
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@import Foundation;
@import CoreLocation;

typedef void (^GOTimeZoneCompletionHandler)(NSTimeZone *timezone, NSError *error);

NS_CLASS_AVAILABLE(10_9, 7_0)
@interface GOTimeZone : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, readonly, getter = isRunning) BOOL running;

// API key this instance uses, if empty then no key will be sent (i.e an anonymous per ip limit is applied)
@property (nonatomic, copy) NSString *googleAPIKey;

/**
 *  Change the default API key to be used by any future requests
 *  Initially empty string
 *
 *  @param key The new key to use, not validated in any way
 */
+ (void)setDefaultGoogleAPIKey:(NSString *)key;

/**
 *  Request control flow, only one request at a time per GOTimeZone instance is handled, attempting to start
 *  another request before first has completed/been cancelled will be ignored.
 *
 *  Completion block will be called even if the request fails or is cancelled, the block is called on the main queue
 */
- (void)requestTimezoneForLocation:(CLLocation *)location completionHandler:(GOTimeZoneCompletionHandler)completionHandler;
- (void)cancelRequest;

@end

#pragma mark -
#pragma mark Error

extern NSString *const GOTimeZoneErrorDomain;

typedef NS_ENUM(NSUInteger, GOTimeZoneErrorCode) {
    kGOTimeZoneErrorNetwork,
    kGOTimeZoneErrorFoundNoResult,
    kGOTimeZoneErrorCancelled,
    kGOTimeZoneErrorDenied,         // If the API responds with an error, likely due to quota
    kGOTimeZoneErrorDataCorrupt,
};