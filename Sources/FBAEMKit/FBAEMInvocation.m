// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if !TARGET_OS_TV

#import "FBAEMInvocation.h"

#import <CommonCrypto/CommonHMAC.h>

#import "FBCoreKitBasicsImportForAEMKit.h"

#define SEC_IN_DAY 86400

static NSString *const CAMPAIGN_ID_KEY = @"campaign_ids";
static NSString *const ACS_TOKEN_KEY = @"acs_token";
static NSString *const ACS_SHARED_SECRET_KEY = @"shared_secret";
static NSString *const ACS_CONFIG_ID_KEY = @"acs_config_id";
static NSString *const BUSINESS_ID_KEY = @"advertiser_id";
static NSString *const TEST_DEEPLINK_KEY = @"test_deeplink";
static NSString *const TIMESTAMP_KEY = @"timestamp";
static NSString *const CONFIG_MODE_KEY = @"config_mode";
static NSString *const CONFIG_ID_KEY = @"config_id";
static NSString *const RECORDED_EVENTS_KEY = @"recorded_events";
static NSString *const RECORDED_VALUES_KEY = @"recorded_values";
static NSString *const CONVERSION_VALUE_KEY = @"conversion_value";
static NSString *const PRIORITY_KEY = @"priority";
static NSString *const CONVERSION_TIMESTAMP_KEY = @"conversion_timestamp";
static NSString *const IS_AGGREGATED_KEY = @"is_aggregated";
static NSString *const HAS_SKAN_KEY = @"has_skan";

static NSString *const FB_CONTENT = @"fb_content";

typedef NSString *const FBAEMInvocationConfigMode;

FBAEMInvocationConfigMode FBAEMInvocationConfigDefaultMode = @"DEFAULT";
FBAEMInvocationConfigMode FBAEMInvocationConfigBrandMode = @"BRAND";

@implementation FBAEMInvocation

+ (nullable instancetype)invocationWithAppLinkData:(nullable NSDictionary<id, id> *)applinkData
{
  @try {
    applinkData = [FBSDKTypeUtility dictionaryValue:applinkData];
    if (!applinkData) {
      return nil;
    }

    NSString *campaignID = [FBSDKTypeUtility dictionary:applinkData objectForKey:CAMPAIGN_ID_KEY ofType:NSString.class];
    NSString *ACSToken = [FBSDKTypeUtility dictionary:applinkData objectForKey:ACS_TOKEN_KEY ofType:NSString.class];
    NSString *ACSSharedSecret = [FBSDKTypeUtility dictionary:applinkData objectForKey:ACS_SHARED_SECRET_KEY ofType:NSString.class];
    NSString *ACSConfigID = [FBSDKTypeUtility dictionary:applinkData objectForKey:CONFIG_ID_KEY ofType:NSString.class];
    NSString *businessID = [FBSDKTypeUtility dictionary:applinkData objectForKey:BUSINESS_ID_KEY ofType:NSString.class];
    NSNumber *isTestMode = [FBSDKTypeUtility dictionary:applinkData objectForKey:TEST_DEEPLINK_KEY ofType:NSNumber.class] ?: @NO;
    NSNumber *hasSKAN = [FBSDKTypeUtility dictionary:applinkData objectForKey:HAS_SKAN_KEY ofType:NSNumber.class] ?: @NO;
    if (campaignID == nil || ACSToken == nil) {
      return nil;
    }
    return [[FBAEMInvocation alloc] initWithCampaignID:campaignID
                                              ACSToken:ACSToken
                                       ACSSharedSecret:ACSSharedSecret
                                           ACSConfigID:ACSConfigID
                                            businessID:businessID
                                            isTestMode:isTestMode.boolValue
                                               hasSKAN:hasSKAN.boolValue];
  } @catch (NSException *exception) {
    return nil;
  }
}

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN
{
  return [self initWithCampaignID:campaignID
                         ACSToken:ACSToken
                  ACSSharedSecret:ACSSharedSecret
                      ACSConfigID:ACSConfigID
                       businessID:businessID
                        timestamp:nil
                       configMode:@"DEFAULT"
                         configID:-1
                   recordedEvents:nil
                   recordedValues:nil
                  conversionValue:-1
                         priority:-1
              conversionTimestamp:nil
                     isAggregated:YES
                       isTestMode:isTestMode
                          hasSKAN:hasSKAN];
}

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  timestamp:(nullable NSDate *)timestamp
                                 configMode:(NSString *)configMode
                                   configID:(NSInteger)configID
                             recordedEvents:(nullable NSMutableSet<NSString *> *)recordedEvents
                             recordedValues:(nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues
                            conversionValue:(NSInteger)conversionValue
                                   priority:(NSInteger)priority
                        conversionTimestamp:(nullable NSDate *)conversionTimestamp
                               isAggregated:(BOOL)isAggregated
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN
{
  if ((self = [super init])) {
    _campaignID = campaignID;
    _ACSToken = ACSToken;
    _ACSSharedSecret = ACSSharedSecret;
    _ACSConfigID = ACSConfigID;
    _businessID = businessID;
    if ([timestamp isKindOfClass:NSDate.class]) {
      _timestamp = timestamp;
    } else {
      _timestamp = [NSDate date];
    }
    _configMode = configMode;
    _configID = configID;
    if ([recordedEvents isKindOfClass:NSMutableSet.class]) {
      _recordedEvents = recordedEvents;
    } else {
      _recordedEvents = [NSMutableSet new];
    }
    if ([recordedValues isKindOfClass:NSMutableDictionary.class]) {
      _recordedValues = recordedValues;
    } else {
      _recordedValues = [NSMutableDictionary new];
    }
    _conversionValue = conversionValue;
    _priority = priority;
    _conversionTimestamp = conversionTimestamp;
    _isAggregated = isAggregated;
    _isTestMode = isTestMode;
    _hasSKAN = hasSKAN;
  }
  return self;
}

- (BOOL)attributeEvent:(NSString *)event
              currency:(nullable NSString *)currency
                 value:(nullable NSNumber *)value
            parameters:(nullable NSDictionary<NSString *, id> *)parameters
               configs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  if ([self _isOutOfWindowWithConfig:config] || ![config.eventSet containsObject:event]) {
    return NO;
  }
  // Check advertiser rule matching
  if (config.matchingRule && ![config.matchingRule isMatchedEventParameters:[self processedParameters:parameters]]) {
    return NO;
  }
  BOOL isAttributed = NO;
  if (![_recordedEvents containsObject:event]) {
    [_recordedEvents addObject:event];
    isAttributed = YES;
  }
  // Change currency to default currency if currency is not found in currencySet
  NSString *valueCurrency = [currency uppercaseString];
  if (![config.currencySet containsObject:valueCurrency]) {
    valueCurrency = config.defaultCurrency;
  }
  if (value != nil) {
    NSMutableDictionary<NSString *, id> *mapping = [[FBSDKTypeUtility dictionary:_recordedValues objectForKey:event ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
    NSNumber *valueInMapping = [FBSDKTypeUtility dictionary:mapping objectForKey:valueCurrency ofType:NSNumber.class] ?: @0.0;
    // Overwrite values when the incoming event's value is greater than the cached one
    if (value.doubleValue > valueInMapping.doubleValue) {
      [FBSDKTypeUtility dictionary:mapping setObject:@(value.doubleValue) forKey:valueCurrency];
      [FBSDKTypeUtility dictionary:_recordedValues setObject:mapping forKey:event];
      isAttributed = YES;
    }
  }
  return isAttributed;
}

- (BOOL)updateConversionValueWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  if (!config) {
    return NO;
  }
  // Update conversion value if a rule is matched
  for (FBAEMRule *rule in config.conversionValueRules) {
    if (rule.priority <= _priority) {
      break;
    }
    if ([rule isMatchedWithRecordedEvents:_recordedEvents recordedValues:_recordedValues]) {
      _conversionValue = rule.conversionValue;
      _priority = rule.priority;
      _conversionTimestamp = [NSDate date];
      _isAggregated = NO;
      return YES;
    }
  }
  return NO;
}

- (BOOL)isOutOfWindowWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  return [self _isOutOfWindowWithConfig:config];
}

- (nullable NSString *)getHMAC:(NSInteger)delay
{
  if (!_ACSSharedSecret || !_ACSConfigID) {
    return nil;
  }
  @try {
    NSData *secretData = [self decodeBase64UrlSafeString:_ACSSharedSecret];
    if (!secretData) {
      return nil;
    }
    NSMutableData *hmac = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    NSString *text = [NSString stringWithFormat:@"%@|%@|%@|%@", _campaignID, @(_conversionValue), @(delay), @"server"];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    CCHmac(kCCHmacAlgSHA512, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], hmac.mutableBytes);
    NSString *base64UrlSafeString = [hmac base64EncodedStringWithOptions:0];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"/"
                                                                         withString:@"_"];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"+"
                                                                         withString:@"-"];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"="
                                                                         withString:@""];
    return base64UrlSafeString;
  } @catch (NSException *exception) {
    return nil;
  }
}

- (nullable NSData *)decodeBase64UrlSafeString:(NSString *)base64UrlSafeString
{
  if (!base64UrlSafeString.length) {
    return nil;
  }
  NSString *base64String = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  NSString *padding = [@"" stringByPaddingToLength:(4 - base64String.length % 4) withString:@"=" startingAtIndex:0];
  base64String = [base64String stringByAppendingString:padding];
  NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
  return decodedData;
}

- (nullable NSDictionary<NSString *, id> *)processedParameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  if (!parameters) {
    return parameters;
  }
  @try {
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionaryWithDictionary:parameters];
    NSString *content = [FBSDKTypeUtility dictionary:result objectForKey:FB_CONTENT ofType:NSString.class];
    if (content) {
      [FBSDKTypeUtility dictionary:result
                         setObject:[FBSDKTypeUtility JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:nil]
                            forKey:FB_CONTENT];
    }
    return [result copy];
  } @catch (NSException *exception) {
    return parameters;
  }
}

- (BOOL)_isOutOfWindowWithConfig:(nullable FBAEMConfiguration *)config
{
  if (!config) {
    return true;
  }
  BOOL isCutoff = [[NSDate date] timeIntervalSinceDate:_timestamp] > config.cutoffTime * SEC_IN_DAY;
  BOOL isOverLastConversionWindow = _conversionTimestamp && [[NSDate date] timeIntervalSinceDate:_conversionTimestamp] > SEC_IN_DAY;
  return isCutoff || isOverLastConversionWindow;
}

- (nullable FBAEMConfiguration *)_findConfig:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  NSString *configMode = _businessID ? FBAEMInvocationConfigBrandMode : FBAEMInvocationConfigDefaultMode;
  NSArray<FBAEMConfiguration *> *configList = [FBSDKTypeUtility dictionary:configs objectForKey:configMode ofType:NSArray.class];
  if (0 == configList.count) {
    return nil;
  }
  if (_configID > 0) {
    for (FBAEMConfiguration *config in configList) {
      if ([config isSameValidFrom:_configID businessID:_businessID]) {
        return config;
      }
    }
    return nil;
  } else {
    FBAEMConfiguration *config = nil;
    for (FBAEMConfiguration *c in [configList reverseObjectEnumerator]) {
      if (c.validFrom <= _timestamp.timeIntervalSince1970 && [c isSameBusinessID:_businessID]) {
        config = c;
        break;
      }
    }
    if (!config) {
      return nil;
    }
    [self _setConfig:config];
    return config;
  }
}

- (void)_setConfig:(FBAEMConfiguration *)config
{
  _configID = config.validFrom;
  _configMode = config.configMode;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *campaignID = [decoder decodeObjectOfClass:NSString.class forKey:CAMPAIGN_ID_KEY];
  NSString *ACSToken = [decoder decodeObjectOfClass:NSString.class forKey:ACS_TOKEN_KEY];
  NSString *ACSSharedSecret = [decoder decodeObjectOfClass:NSString.class forKey:ACS_SHARED_SECRET_KEY];
  NSString *ACSConfigID = [decoder decodeObjectOfClass:NSString.class forKey:ACS_CONFIG_ID_KEY];
  NSString *businessID = [decoder decodeObjectOfClass:NSString.class forKey:BUSINESS_ID_KEY];
  NSDate *timestamp = [decoder decodeObjectOfClass:NSDate.class forKey:TIMESTAMP_KEY];
  NSString *configMode = [decoder decodeObjectOfClass:NSString.class forKey:CONFIG_MODE_KEY];
  NSInteger configID = [decoder decodeIntegerForKey:CONFIG_ID_KEY];
  NSMutableSet<NSString *> *recordedEvents = [decoder decodeObjectOfClass:NSMutableSet.class forKey:RECORDED_EVENTS_KEY];
  NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *recordedValues = [decoder decodeObjectOfClass:NSMutableDictionary.class forKey:RECORDED_VALUES_KEY];
  NSInteger conversionValue = [decoder decodeIntegerForKey:CONVERSION_VALUE_KEY];
  NSInteger priority = [decoder decodeIntegerForKey:PRIORITY_KEY];
  NSDate *conversionTimestamp = [decoder decodeObjectOfClass:NSDate.class forKey:CONVERSION_TIMESTAMP_KEY];
  BOOL isAggregated = [decoder decodeBoolForKey:IS_AGGREGATED_KEY];
  BOOL hasSKAN = [decoder decodeBoolForKey:HAS_SKAN_KEY];
  return [self initWithCampaignID:campaignID
                         ACSToken:ACSToken
                  ACSSharedSecret:ACSSharedSecret
                      ACSConfigID:ACSConfigID
                       businessID:businessID
                        timestamp:timestamp
                       configMode:configMode
                         configID:configID
                   recordedEvents:recordedEvents
                   recordedValues:recordedValues
                  conversionValue:conversionValue
                         priority:priority
              conversionTimestamp:conversionTimestamp
                     isAggregated:isAggregated
                       isTestMode:NO
                          hasSKAN:hasSKAN];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_campaignID forKey:CAMPAIGN_ID_KEY];
  [encoder encodeObject:_ACSToken forKey:ACS_TOKEN_KEY];
  [encoder encodeObject:_ACSSharedSecret forKey:ACS_SHARED_SECRET_KEY];
  [encoder encodeObject:_ACSConfigID forKey:ACS_CONFIG_ID_KEY];
  [encoder encodeObject:_businessID forKey:BUSINESS_ID_KEY];
  [encoder encodeObject:_timestamp forKey:TIMESTAMP_KEY];
  [encoder encodeObject:_configMode forKey:CONFIG_MODE_KEY];
  [encoder encodeInteger:_configID forKey:CONFIG_ID_KEY];
  [encoder encodeObject:_recordedEvents forKey:RECORDED_EVENTS_KEY];
  [encoder encodeObject:_recordedValues forKey:RECORDED_VALUES_KEY];
  [encoder encodeInteger:_conversionValue forKey:CONVERSION_VALUE_KEY];
  [encoder encodeInteger:_priority forKey:PRIORITY_KEY];
  [encoder encodeObject:_conversionTimestamp forKey:CONVERSION_TIMESTAMP_KEY];
  [encoder encodeBool:_isAggregated forKey:IS_AGGREGATED_KEY];
  [encoder encodeBool:_hasSKAN forKey:HAS_SKAN_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

#if DEBUG
 #if FBTEST

- (void)setRecordedEvents:(NSMutableSet<NSString *> *)recordedEvents
{
  _recordedEvents = recordedEvents;
}

- (void)setRecordedValues:(NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues
{
  _recordedValues = recordedValues;
}

- (void)setPriority:(NSInteger)priority
{
  _priority = priority;
}

- (void)setConfigID:(NSInteger)configID
{
  _configID = configID;
}

- (void)setBusinessID:(NSString *_Nullable)businessID
{
  _businessID = businessID;
}

- (void)setConversionTimestamp:(NSDate *_Nonnull)conversionTimestamp
{
  _conversionTimestamp = conversionTimestamp;
}

- (void)setConversionValue:(NSInteger)conversionValue
{
  _conversionValue = conversionValue;
}

- (void)setCampaignID:(NSString *_Nonnull)campaignID
{
  _campaignID = campaignID;
}

- (void)setACSSharedSecret:(NSString *_Nullable)ACSSharedSecret
{
  _ACSSharedSecret = ACSSharedSecret;
}

- (void)setACSConfigID:(NSString *_Nullable)ACSConfigID
{
  _ACSConfigID = ACSConfigID;
}

- (void)reset
{
  _timestamp = [NSDate date];
  _configMode = @"DEFAULT";
  _configID = -1;
  _businessID = nil;
  _recordedEvents = [NSMutableSet new];
  _recordedValues = [NSMutableDictionary new];
  _conversionValue = -1;
  _priority = -1;
  _conversionTimestamp = [NSDate date];
  _isAggregated = YES;
  _hasSKAN = NO;
}

 #endif
#endif

@end

#endif
