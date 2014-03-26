GOTimeZone
==========

`GOTimeZone` is a lightweight wrapper around the [Google Timezone API](https://developers.google.com/maps/documentation/timezone/), allowing to get a suitable `NSTimeZone` for a `CLLocation` object.

## Usage

`GOTimeZone` follows similar pattern to `CLGeocoder`, simply create an instance and request a timezone for a location.

```objective-c
CLLocation *location = ...
GOTimeZone *timezone = [[GOTimeZone alloc] init];
[timezone requestTimezoneForLocation:location 
				   completionHandler:^(NSTimeZone *timezone, NSError *error) {
        // Do something with the found timezone
}];
```

### Google API Key

The [Google Timezone API](https://developers.google.com/maps/documentation/timezone/), allows requests to be both anonymous and identified by a Google API key. `GOTimeZone` by default uses anonymous requests, but an API key can be specified per instance. A default API key can also be defined for automatic use by the instances.

```objective-c
// Assuming timezone is a GOTimeZone instance and apiKey is an NSString containing the key
[timezone setGoogleAPIKey:apiKey];

// Setting the default key to be used by all the instances
[GOTimeZone setDefaultGoogleAPIKey:apiKey];
```

### NSProgress

`GOTimeZone` uses `NSProgress` to report the progress of its network request, it also supports cancellation, but not pausing. `NSProgress` cancellation is handled as if `-cancelRequest` had been called.

The network traffic is mostly minimal, but due to latency the process may take a while, thus progress reporting was added.

## Installation

Simply add the files in the GOTimeZone folder to your project (GOTimeZone.{h,m}).

GOTimeZone works on both OS X and iOS, requiring OS X 10.9 and iOS 7 respectively.

## Limitations

Each `GOTimeZone` instance can handle at most one request at a time, again following a similar pattern from `CLGeocoder`. Thus in order to start a new request the previous one should be cancelled via `-cancelRequest` method. Keep in mind that cancelling might take a moment and that the completion handler of the previous call will get invoked no matter what.

---

## Contact

Henri Normak

- http://github.com/henrinormak
- http://twitter.com/henrinormak

## License

`GOTimeZone` is licensed under the MIT license, see LICENSE file for more info.
