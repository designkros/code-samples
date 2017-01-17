//
//  MSSSequenceEngine.h
//  Sample
//
//  Created by Michael Rose on 4/8/15.
//  Copyright (c) 2015 Michael Rose. All rights reserved.
//

#import <Player/Player.h>

@interface MSSSequenceEngine : NSObject <Engine>

@property (strong, nonatomic) MSSUser *user;
@property (strong, nonatomic) MSSItem *currentItem;
@property (strong, nonatomic) NSArray *itemList;
@property (strong, nonatomic, readonly) NSArray *administeredItemList;

- (void)resetItem:(MSSItem *)item;

@end