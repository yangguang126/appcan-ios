/**
 *
 *	@file   	: ACEJSCHandler.m  in AppCanEngine
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/1/8.
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

#import "ACEJSCHandler.h"
#import "EUExBase.h"
#import "BUtility.h"
#import <objc/message.h>
#import "ACEJSCBaseJS.h"
#import "ACEPluginParser.h"

static NSMutableDictionary *ACEJSCGlobalPlugins;


@implementation ACEJSCHandler

+ (void)initializeGlobalPlugins{
    ACEJSCGlobalPlugins = [NSMutableDictionary dictionary];
    ACEPluginParser *parser = [ACEPluginParser sharedParser];
    [parser.globalPluginDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self registerGlobalPlugin:key];
    }];
}

+ (void)registerGlobalPlugin:(NSString *)pluginClassName{
    if(ACEJSCGlobalPlugins[pluginClassName]){
        return;
    }
    [ACEJSCGlobalPlugins setObject:[NSNull null] forKey:pluginClassName];
}


- (void)initializeWithJSContext:(JSContext *)context{
    context[@"uex"] = self;
    NSString *baseJS = [ACEJSCBaseJS baseJS];
    [context evaluateScript:baseJS];
    [context setExceptionHandler:^(JSContext *con, JSValue *exception) {
        NSLog(@"%@", exception);
        con.exception = exception;
    }];
}

- (id)executeWithPlugin:(NSString *)pluginName method:(NSString *)methodName arguments:(NSArray *)arguments asyncKey:(NSString *)asyncKey{
    if(!ACEJSCGlobalPlugins){
        [self.class initializeGlobalPlugins];
    }

    if(!pluginName || ![pluginName hasPrefix:@"uex"] || !methodName || methodName.length < 1){
        return nil;
    }
    NSString *className = [@"EUEx" stringByAppendingString:[pluginName substringFromIndex:3]];
    [self loadDynamicPlugins:pluginName];
    id pluginInstance = [self getGlobalPluginInstanceByClassName:className];
    if(!pluginInstance){
        pluginInstance = [self getNormalPluginInstanceByClassName:className];
    }
    if(![self isPluginInstanceValid:pluginInstance]){
        return nil;
    }
    __block NSMutableArray *args = [NSMutableArray array];
    if([arguments isKindOfClass:[NSArray class]]){
        [arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [args addObject:[obj copy]];
        }];
    }

    SEL method = NSSelectorFromString([methodName stringByAppendingString:@":"]);
    if(![pluginInstance respondsToSelector:method]){
        return nil;
    }
    BOOL async = [asyncKey isEqual:ACE_METHOD_SYNC]?NO:YES;
    if(async){
        dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [pluginInstance performSelector:method withObject:args];
        });
        return nil;
    }
    return [pluginInstance performSelector:method withObject:args];;
#pragma clang diagnostic pop
}

- (id)getGlobalPluginInstanceByClassName:(NSString *)className{
    if(!ACEJSCGlobalPlugins[className]){
        return nil;
    }
    id instance = ACEJSCGlobalPlugins[className];
    if (![instance isEqual:[NSNull null]]) {
        return instance;
    }
    Class instanceClass = NSClassFromString(className);
    if(!instanceClass){
        return nil;
    }
    instance = [[instanceClass alloc] initWithBrwView:self.eBrowserView];
    if(!instance){
        return nil;
    }
    [ACEJSCGlobalPlugins setValue:instance forKey:className];
    return instance;
}

- (id)getNormalPluginInstanceByClassName:(NSString *)className{

    if(self.pluginDict[className]){
        return self.pluginDict[className];
    }
    id instance;
    Class instanceClass = NSClassFromString(className);
    if(!instanceClass){
        return nil;
    }
    instance = [[instanceClass alloc] initWithBrwView:self.eBrowserView];
    if(!instance){
        return nil;
    }
    [self.pluginDict setValue:instance forKey:className];
    return instance;
}

- (void)loadDynamicPlugins:(NSString *)pluginName{
    NSString *frameworkName=[NSString stringWithFormat:@"%@.framework",pluginName];
    
    //载入指定document子目录下的framework
    NSBundle *dynamicBundle=[NSBundle bundleWithPath:[[BUtility dynamicPluginFrameworkFolderPath] stringByAppendingPathComponent:frameworkName]];
    
    if(dynamicBundle){
        if([dynamicBundle isLoaded]){
            return;
        }
        if([dynamicBundle load]){
            NSLog(@"load dynamic framework for plugin:%@",pluginName);
            return;
        }
    }
    
    //载入res目录下的framework
    //测试用
#if DEBUG
    dynamicBundle=[NSBundle bundleWithPath:[BUtility wgtResPath:[NSString stringWithFormat:@"res://%@",frameworkName]]];
    if(dynamicBundle){
        if([dynamicBundle isLoaded]){
            return;
        }
        if([dynamicBundle load]){
            NSLog(@"load dynamic framework for plugin:%@",pluginName);
            return;
        }
    }
#endif
}

- (BOOL)isPluginInstanceValid:(id)pluginInstance{
    if(!pluginInstance){
        return NO;
    }
    if(![NSStringFromClass([pluginInstance superclass]) isEqual:@"EUExBase"]){
        return NO;
    }
    return YES;
}

- (instancetype)initWithEBrowserView:(EBrowserView *)eBrowserView{
    if(!eBrowserView){
        return nil;
    }
    
    self = [super init];
    if (self) {
        _pluginDict = [NSMutableDictionary dictionary];
        _eBrowserView = eBrowserView;
    }
    return self;
}

- (void)clean{
    for(__kindof EUExBase *plugin in self.pluginDict.allValues){
        [plugin clean];
    }
    [self.pluginDict removeAllObjects];
    self.eBrowserView = nil;
}

- (void)dealloc{
    
}

@end
