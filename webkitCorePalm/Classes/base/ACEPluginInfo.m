/**
 *
 *	@file   	: ACEPluginInfo.m  in AppCanEngine
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/1/9.
 *
 *	@copyright 	: 2015 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "ACEPluginInfo.h"
#import <Ono/Ono.h>
@interface ACEPluginInfo()

@end
@implementation ACEPluginInfo

- (instancetype)initWithName:(NSString *)uexName;
{
    self = [super init];
    if (self) {
        _uexName=uexName;
        _methods=[NSMutableDictionary dictionary];
        _properties=[NSMutableDictionary dictionary];
    }
    return self;
}
-(void)updateWithXMLElement:(ONOXMLElement *)XMLElement{
    NSArray *newMethods = [XMLElement childrenWithTag:@"method"];
    for (ONOXMLElement *aMethod in newMethods) {
        NSString *methodName = aMethod[@"name"];
        NSString *async = ACE_METHOD_ASYNC;
        NSString *syncType = aMethod[@"sync"];
        if(syncType){
            if([syncType.lowercaseString isEqual:@"true"] || [syncType boolValue]){
                async = ACE_METHOD_SYNC;
            }
        }
        if(methodName && methodName.length >0){
            [self.methods setValue:async forKey:methodName];
        }
    }
    NSArray *newProperties = [XMLElement childrenWithTag:@"property"];
    for (ONOXMLElement *aProperty in newProperties) {
        NSString *propertyName = aProperty[@"property"];
        if(propertyName && propertyName.length >0 && aProperty.stringValue){
            [self.properties setValue:aProperty.stringValue forKey:propertyName];
        }
    }
}
@end