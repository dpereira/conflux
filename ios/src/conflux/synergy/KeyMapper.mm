//
//  KeyMapper.m
//  conflux
//
//  Created by Diego Pereira on 5/3/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import <map>
#import <vector>
#import <algorithm>
#import <Foundation/Foundation.h>
#import "KeyMapper.h"

@interface KeyMapper()

@end

@implementation KeyMapper {
}

- (id)init {
    if(self = [super init]) {
        return self;
    } else {
        return nil;
    }
}

- (UInt16)translate:(UInt16)asciiCodepoint {
    static const std::map<UInt16, KeyID> mapping = {
        {'\n', kKeyReturn},
        {'\b', kKeyBackSpace},
        {'\t', kKeyTab},
        {' ', kKeyKP_Space }
    };
    
    std::map<UInt16, KeyID>::const_iterator i = mapping.find(asciiCodepoint);
    
    if(i != mapping.end()) {
        return (UInt16)i->second;
    } else {
        return asciiCodepoint;
    }
}

- (KeyModifierMask)getKeyModifier:(UInt16)key
{
    static const std::vector<UInt16> upperCaseKeys = {
        '>', '$', '%', '&', '/', '(', ')',
        '*', '^', '_', '!', '?', ':', '"',
        '=', '@', '#', '[', ']', '{', '}',
        '|', '~'
    };
    
    static const std::vector<UInt16> optionKeys = {
        
    };
    
    KeyModifierMask mask = 0;
    
    if((key >= 'A' && key <= 'Z')) {
        mask |= KeyModifierShift;
    } else if(std::find(upperCaseKeys.begin(), upperCaseKeys.end(), key) != upperCaseKeys.end()) {
        mask |= KeyModifierShift;
    }
    
    if(std::find(optionKeys.begin(), optionKeys.end(), key) != optionKeys.end()) {
        mask |= KeyModifierAlt;
    }
    
    return mask;
}

@end