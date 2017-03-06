/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKPhoneNumber.h"

@implementation MXKPhoneNumber

@synthesize msisdn;

- (id)initWithTextNumber:(NSString*)textNumber type:(NSString*)type contactID:(NSString*)contactID matrixID:(NSString*)matrixID
{
    self = [super initWithContactID:contactID matrixID:matrixID];
    
    if (self)
    {
        _type = type ? type : @"";
        _textNumber = textNumber ? textNumber : @"" ;
        _cleanedPhonenumber = [MXKPhoneNumber cleanPhonenumber:_textNumber];
        _defaultCountryCode = nil;
        msisdn = nil;
        
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:nil error:nil];
    }
    
    return self;
}

// remove the unuseful characters in a phonenumber
+ (NSString*)cleanPhonenumber:(NSString*)phoneNumber
{
    // sanity check
    if (nil == phoneNumber)
    {
        return nil;
    }
    
    // empty string
    if (0 == [phoneNumber length])
    {
        return @"";
    }
    
    static NSCharacterSet *invertedPhoneCharSet = nil;
    
    if (!invertedPhoneCharSet)
    {
        invertedPhoneCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+*#,"] invertedSet];
    }
    
    return [[phoneNumber componentsSeparatedByCharactersInSet:invertedPhoneCharSet] componentsJoinedByString:@""];
}


- (BOOL)matchedWithPatterns:(NSArray*)patterns
{
    // no number -> cannot match
    if (_textNumber.length == 0)
    {
        return NO;
    }
    
    if (patterns.count > 0)
    {
        NSString *msisdnPattern;
        
        for (NSString *pattern in patterns)
        {
            if ([pattern hasPrefix:@"+"])
            {
                msisdnPattern = [pattern substringFromIndex:1];
            }
            else if ([pattern hasPrefix:@"00"])
            {
                msisdnPattern = [pattern substringFromIndex:2];
            }
            else
            {
                msisdnPattern = pattern;
            }
            
            if (([_textNumber rangeOfString:pattern].location == NSNotFound) && ([_cleanedPhonenumber rangeOfString:pattern].location == NSNotFound))
            {
                // Check the msisdn
                if (!self.msisdn || !msisdnPattern.length || [self.msisdn rangeOfString:msisdnPattern].location == NSNotFound)
                {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)hasPrefix:(NSString*)prefix
{
    // no number -> cannot match
    if (_textNumber.length == 0)
    {
        return NO;
    }
    
    if ([_cleanedPhonenumber hasPrefix:prefix] || [_textNumber hasPrefix:prefix])
    {
        return YES;
    }
    else if (self.msisdn)
    {
        if ([prefix hasPrefix:@"+"])
        {
            prefix = [prefix substringFromIndex:1];
        }
        else if ([prefix hasPrefix:@"00"])
        {
            prefix = [prefix substringFromIndex:2];
        }
        
        return [self.msisdn hasPrefix:prefix];
    }
    
    return NO;
}

- (void)setDefaultCountryCode:(NSString *)defaultCountryCode
{
    if (![defaultCountryCode isEqualToString:_defaultCountryCode])
    {
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:defaultCountryCode error:nil];
        
        _defaultCountryCode = defaultCountryCode;
        msisdn = nil;
    }
}

- (NSString*)msisdn
{
    if (!msisdn && _nbPhoneNumber)
    {
        NSString *e164 = [[NBPhoneNumberUtil sharedInstance] format:_nbPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:nil];
        if ([e164 hasPrefix:@"+"])
        {
            msisdn = [e164 substringFromIndex:1];
        }
        else if ([e164 hasPrefix:@"00"])
        {
            msisdn = [e164 substringFromIndex:2];
        }
    }
    return msisdn;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        _type = [coder decodeObjectForKey:@"type"];
        _textNumber = [coder decodeObjectForKey:@"textNumber"];
        _cleanedPhonenumber = [coder decodeObjectForKey:@"cleanedPhonenumber"];
        _defaultCountryCode = [coder decodeObjectForKey:@"countryCode"];
        
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:_defaultCountryCode error:nil];
        msisdn = nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_textNumber forKey:@"textNumber"];
    [coder encodeObject:_cleanedPhonenumber forKey:@"cleanedPhonenumber"];
    [coder encodeObject:_defaultCountryCode forKey:@"countryCode"];
}

@end
