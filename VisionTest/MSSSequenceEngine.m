//
//  MSSSequenceEngine.m
//  Sample
//
//  Created by Michael Rose on 4/8/15.
//  Copyright (c) 2015 Michael Rose. All rights reserved.
//

#import "MSSSequenceEngine.h"

@interface MSSSequenceEngine ()

@end

@implementation MSSSequenceEngine

-(id)initWithParameterDictionary:(NSDictionary *)parameterDictionary andConfigurationDictionary:(NSDictionary *)configurationDictionary
{
	
	self = [super init];
    if (self) {
        //
    }
    
    return self;
}

// MR   Should be set in the init method
- (void)setUser:(MSSUser *)user
{
	_user = user;
}

// MR   Should be set in the init method
- (void)setItemList:(NSArray *)itemList
{
    _itemList = itemList;
}

- (NSArray *)administeredItemList
{
	// MR   Only administed items have a position (set in processUserGeneratedResponses)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Position.length > 0"];
    NSArray *administeredItems = [_itemList filteredArrayUsingPredicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"Position" ascending:YES selector:@selector(localizedStandardCompare:)];
    
    return [administeredItems sortedArrayUsingDescriptors:@[sort]];
}

#pragma mark - Display Management

- (MSSItem *)previousItem
{
	MSSItem *item = self.administeredItemList.lastObject;
    if (item) {
        [self resetItem:item];
        _currentItem = item;
    }
    
    return _currentItem;
}

- (MSSItem *)nextItem
{
    // MR   Get the next item in the items array list
    NSUInteger index = [_itemList indexOfObject:_currentItem];
    index = (index == NSNotFound) ? 0 : (index + 1);
    _currentItem = (index < _itemList.count) ? [_itemList objectAtIndex:index] : nil;
    
    return _currentItem;
}

- (void)resetItem:(MSSItem *)item
{
    // MR   Item's position (and other properties set by processResponse) should be reset
    //      when previousItem is called or the item will be skipped by nextItem
    item.ItemResponseOID = nil;
    item.Response = nil;
    item.ResponseTime = nil;
    item.score = nil;
    item.ResponseDescription = nil;
    item.Position = nil;
}

#pragma mark - Response Management

- (NSArray *)processResponses:(NSArray *)responses withResponseTime:(NSTimeInterval)responseTime
{
    MSSMap *response = [responses firstObject];
    
    _currentItem.ItemResponseOID = response.ItemResponseOID;
    _currentItem.Response = response.Value;
    _currentItem.ResponseTime = [NSString stringWithFormat:@"%f", responseTime];
    _currentItem.score = @(response.Description.integerValue);
    
    if (response.resources.count) {
        MSSResource *resource = response.resources[0];
        _currentItem.ResponseDescription = resource.Description;
    }
    
    // MR   Don't assign a new position if one already exists (restart)
    NSInteger position;
    if (_currentItem.Position.length) {
        position = _currentItem.Position.integerValue;
    } else {
        position = self.administeredItemList.count + 1;
    }
    _currentItem.Position = @(position).stringValue;
    
    return @[ _currentItem ];
}

@end
