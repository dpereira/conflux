//
//  KeyMapper.m
//  conflux
//
//  Created by Diego Pereira on 5/3/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import <map>
#import <Foundation/Foundation.h>
#import "KeyMapper.h"
#import "synergy/key_types.h"

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
    static const std::map<UInt16, KeyID> _mapping = {
        {'\n', kKeyReturn},
        {'\b', kKeyBackSpace}
    };
    
    std::map<UInt16, KeyID>::const_iterator i =_mapping.find(asciiCodepoint);
    
    if(i != _mapping.end()) {
        return (UInt16)i->second;
    } else {
        return asciiCodepoint;
    }
}

@end