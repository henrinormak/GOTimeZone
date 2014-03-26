//
//  GOTimeZone.m
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

#import "GOTimeZone.h"

#pragma mark -
#pragma mark Constants

NSString *const GOTimeZoneErrorDomain = @"GOTimeZoneError";

NSString *const GOTimeZoneResponseStatus = @"status";
NSString *const GOTimeZoneResponseErrorMessage = @"error_message";
NSString *const GOTimeZoneResponseTimeZoneID = @"timeZoneId";

NSString *const GOTimeZoneResponseStatusOK = @"OK";
NSString *const GOTimeZoneResponseStatusInvalid = @"INVALID_REQUEST";
NSString *const GOTimeZoneResponseStatusOverQuota = @"OVER_QUERY_LIMIT";
NSString *const GOTimeZoneResponseStatusDenied = @"REQUEST_DENIED";
NSString *const GOTimeZoneResponseStatusUnknown = @"UNKNOWN_ERROR";
NSString *const GOTimeZoneResponseStatusZeroResults = @"ZERO_RESULTS";

static void * GOTimeZoneContext = &GOTimeZoneContext;

@interface GOTimeZone ()
@property (nonatomic, readwrite, getter = isRunning) BOOL running;
@property (nonatomic, readwrite, getter = isCancelling) BOOL cancelling;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, copy) GOTimeZoneCompletionHandler completionHandler;

- (void)finishRequest:(NSTimeZone *)result error:(NSError *)error;

@end

@implementation GOTimeZone

#pragma mark -
#pragma mark API Key

static NSString *GOTimeZoneDefaultAPIKey = @"";

+ (void)setDefaultGoogleAPIKey:(NSString *)key {
    GOTimeZoneDefaultAPIKey = key;
}

+ (NSString *)defaultGoogleAPIKey {
    return GOTimeZoneDefaultAPIKey;
}

#pragma mark -
#pragma mark GOTimeZone

- (instancetype)init {
    if ((self = [super init])) {
        self.googleAPIKey = [[self class] defaultGoogleAPIKey];
    }
    
    return self;
}

- (void)requestTimezoneForLocation:(CLLocation *)location completionHandler:(GOTimeZoneCompletionHandler)completionHandler {
    // Ignore if we are already running
    // Previous request has to be completely cancelled first
    @synchronized(self) {
        if (self.running || self.cancelling)
            return;
        
        self.running = YES;
    }
    
    // Update state
    self.completionHandler = completionHandler;
    
    // Create the connection
    NSMutableString *urlString = [NSMutableString stringWithString:@"https://maps.googleapis.com/maps/api/timezone/json?"];
    [urlString appendFormat:@"location=%f,%f&timestamp=%1.f&sensor=true", location.coordinate.latitude, location.coordinate.longitude, [location.timestamp timeIntervalSince1970]];
    
    if ([self.googleAPIKey length] > 0)
        [urlString appendFormat:@"&key=%@", self.googleAPIKey];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    // Start progress
    self.progress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress] userInfo:nil];
    self.progress.cancellable = YES;
    self.progress.pausable = NO;
    
    // Observe progress state
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(isCancelled)) options:0 context:GOTimeZoneContext];
    
    // Start the connection
    [self.connection start];
}

- (void)cancelRequest {
    // If not running, or already in the middle of cancelling, then ignore
    @synchronized(self) {
        if (!self.isRunning || self.isCancelling)
            return;
        
        self.cancelling = YES;
    }
    
    // Cancel the connection
    [self.connection cancel];
}

- (void)finishRequest:(NSTimeZone *)result error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionHandler)
            self.completionHandler(result, error);
        
        self.data = nil;
        self.connection = nil;
        self.completionHandler = nil;
        
        self.running = NO;
        self.cancelling = NO;
        
        [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(isCancelled)) context:GOTimeZoneContext];
        self.progress = nil;
    });
}

#pragma mark -
#pragma mark NSURLConnectionDelegates

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)[cachedResponse response];
    
    // Check if caching is protocol based, in which case make sure the protocol included necessary headers
    if([connection currentRequest].cachePolicy == NSURLRequestUseProtocolCachePolicy) {
        NSDictionary *headers = [httpResponse allHeaderFields];
        NSString *cacheControl = [headers valueForKey:@"Cache-Control"];
        NSString *expires = [headers valueForKey:@"Expires"];
        if((cacheControl == nil) && (expires == nil)) {
            return nil;
        }
    }
    
    return cachedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    
    if ([HTTPResponse statusCode] == 200) {
        NSInteger length = [response expectedContentLength];
        [self.progress setTotalUnitCount:length];
        
        if (length > 0)
            self.data = [NSMutableData dataWithCapacity:length];
        else
            self.data = [NSMutableData data];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    self.progress.completedUnitCount += [data length];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self finishRequest:nil error:[NSError errorWithDomain:GOTimeZoneErrorDomain code:kGOTimeZoneErrorNetwork userInfo:error.userInfo]];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error;
    NSTimeZone *result;
    
    // Check if we have any data
    if (self.data == nil) {
        error = [NSError errorWithDomain:GOTimeZoneErrorDomain code:kGOTimeZoneErrorNetwork userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Timezone API request returned no data", nil)}];
    } else {
        // We have data, try to parse the data
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
        if (!JSON) {
            error = [NSError errorWithDomain:GOTimeZoneErrorDomain code:kGOTimeZoneErrorDataCorrupt userInfo:error.userInfo];
        } else {
            // Parse the JSON output
            NSString *status = [JSON objectForKey:GOTimeZoneResponseStatus];
            if ([status isEqualToString:GOTimeZoneResponseStatusOK]) {
                // Everything was fine, create the timezone
                result = [NSTimeZone timeZoneWithName:[JSON objectForKey:GOTimeZoneResponseTimeZoneID]];
            } else if ([status isEqualToString:GOTimeZoneResponseStatusZeroResults]) {
                // No matches
                error = [NSError errorWithDomain:GOTimeZoneErrorDomain code:kGOTimeZoneErrorFoundNoResult userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Timezone API request returned zero results", nil)}];
            } else {
                // Generic error, simply claim as denied
                NSDictionary *userinfo;
                NSString *errorMessage = [JSON objectForKey:GOTimeZoneResponseErrorMessage];
                if (errorMessage)
                    userinfo = @{NSLocalizedDescriptionKey : errorMessage};
                
                error = [NSError errorWithDomain:GOTimeZoneErrorDomain code:kGOTimeZoneErrorDenied userInfo:userinfo];
            }
        }
    }
    
    [self finishRequest:result error:error];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == GOTimeZoneContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(isCancelled))]) {
            if ([object isCancelled])
                [self cancelRequest];   // Cancel the request
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
