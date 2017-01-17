//
//  StaticVisionEngine.m
//  Sample
//
//  Created by Michael Rose on 4/8/15.
//  Copyright (c) 2015 Michael Rose. All rights reserved.
//

#import "StaticVisionEngine.h"
#import "StaticVisionConstants.h"
#import "StaticVisionItemHelper.h"

@interface StaticVisionEngine ()

@property (strong, nonatomic) NSDictionary *practice;
@property (strong, nonatomic) NSDictionary *screen;
@property (strong, nonatomic) NSDictionary *chart;
@property (strong, nonatomic) NSDictionary *pool;
@property (strong, nonatomic) NSDictionary *previousPool;
@property (strong, nonatomic, readonly) NSArray *sizes;
@property (nonatomic) NSInteger currentSizeIndex;

@property (nonatomic) BOOL practiceComplete;
@property (nonatomic) BOOL screeningComplete;
@property (nonatomic) NSInteger screeningDirection;

@end

@implementation StaticVisionEngine

- (void)setItemList:(NSArray *)itemList
{
    [super setItemList:itemList];
    
    // Practice
    NSInteger practiceSection = [self sectionForItemType:StaticVisionItemInfoItemTypePractice inItemList:self.itemList];
    self.practice = [self chartForSection:practiceSection inItemList:self.itemList shuffleLines:NO];
    NSLog(@"// PRACTICE");
    [self logChart:self.practice];
    
    // 8+ doesn't have a practice, so the practice chart will be empty
    if (!self.practice.count) {
        self.practiceComplete = YES;
    }
    
    // Screen
    NSInteger screenSection = [self sectionForItemType:StaticVisionItemInfoItemTypeScreen inItemList:self.itemList];
    self.screen = [self chartForSection:screenSection inItemList:self.itemList shuffleLines:YES];
    NSLog(@"// SCREEN");
    [self logChart:self.screen];
    
    // Chart
    NSInteger chartSection = [self sectionForItemType:StaticVisionItemInfoItemTypeChart inItemList:self.itemList];
    self.chart = [self chartForSection:chartSection inItemList:self.itemList shuffleLines:YES];
    NSLog(@"// CHART");
    [self logChart:self.chart];
    
    // Set the starting size index
    self.currentSizeIndex = [self.sizes indexOfObject:StaticVisionStartingSizeValue];
}

#pragma mark - Chart Utils

- (NSInteger)sectionForItemType:(NSString *)type inItemList:(NSArray *)itemList
{
    NSInteger section = NSNotFound;
    
    NSMutableSet *sections = [NSMutableSet set];
    for (MSSItem *item in itemList) {
        NSString *t = item.itemInfo[StaticVisionItemInfoItemType];
        if ([t isEqualToString:type]) {
            [sections addObject:@(item.Section)];
        }
    }
    
    if (sections.count > 1) {
        // Select a section at random
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        NSArray *sortedSections = [[sections allObjects] sortedArrayUsingDescriptors:@[ sort ]];
        NSNumber *minSection = [sortedSections firstObject];
        NSNumber *maxSection = [sortedSections lastObject];
        section = rand() % (maxSection.integerValue - minSection.integerValue) + minSection.integerValue;
    } else if (sections.count == 1) {
        // The only section available
        NSNumber *onlySection = [sections anyObject];
        section = onlySection.integerValue;
    }
    
    return section;
}

- (NSDictionary *)chartForSection:(NSInteger)section inItemList:(NSArray *)itemList shuffleLines:(BOOL)shuffle
{
    if (section == NSNotFound || section < 0) return nil;
    
    // Parse items (optotypes) into lines (5 letters per size) for selected section (chart)
    NSMutableDictionary *chart = [NSMutableDictionary dictionaryWithCapacity:itemList.count];
    for (MSSItem *item in itemList) {
        if (item.Section == section) {
            NSString *key = [StaticVisionItemHelper sizeForItem:item];
            NSArray *line = [chart objectForKey:key];
            NSMutableArray *updateLine = [NSMutableArray arrayWithArray:line];
            if (!updateLine && key.length) {
                updateLine = [NSMutableArray arrayWithCapacity:5];
            }
            [updateLine addObject:item];
            [chart setObject:[updateLine copy] forKey:key];
        }
    }
    
    // Shuffle each line on the selected chart
    if (shuffle) {
        NSString *previousKey;
        for (NSString *key in self.sizes) {
            
            NSArray *line = [chart objectForKey:key];
            NSArray *shuffledLine;
            
            NSArray *previousLine = [chart objectForKey:previousKey];
            NSString *previousLineLastCharacter = [StaticVisionItemHelper letterForItem:[previousLine lastObject]];
            
            BOOL unique = NO;
            while (!unique) {
                
                shuffledLine = [self shuffledLineForLine:line];
                
                // Make sure consecutive characters do not repeat in the same line
                BOOL lineUnique = YES;
                NSString *previousCharacter;
                for (MSSItem *item in shuffledLine) {
                    NSString *character = [StaticVisionItemHelper letterForItem:item];
                    if ([character isEqualToString:previousCharacter]) {
                        lineUnique = NO;
                        break;
                    }
                    previousCharacter = character;
                }
                
                // Make sure consecutive lines do not repeat the same last characters
                if (lineUnique) {
                    NSString *shuffledLineLastCharacter = [StaticVisionItemHelper letterForItem:[shuffledLine lastObject]];
                    if (![shuffledLineLastCharacter isEqualToString:previousLineLastCharacter]) {
                        unique = YES;
                    }
                }
                
            }
            
            [chart setObject:shuffledLine forKey:key];
            previousKey = key;
        }
    }
    
    return [chart copy];
}

- (NSArray *)shuffledLineForLine:(NSArray *)line
{
    NSMutableArray *shuffledLine = [NSMutableArray arrayWithArray:line];
    for (NSInteger i = shuffledLine.count-1; i > 0; i--) {
        [shuffledLine exchangeObjectAtIndex:i withObjectAtIndex:arc4random_uniform((uint32_t)i+1)];
    }
    
    return [shuffledLine copy];
}

- (void)logChart:(NSDictionary *)chart
{
    for (NSString *sizeKey in self.sizes) {
        NSArray *line = [chart objectForKey:sizeKey];
        NSString *letters = @"";
        for (MSSItem *item in line) {
            letters = [letters stringByAppendingString:[StaticVisionItemHelper letterForItem:item]];
            if ([line indexOfObject:item] != line.count-1) {
                letters = [letters stringByAppendingString:@", "];
            }
        }
        NSLog(@"%@ - %@", sizeKey, letters);
    }
}

#pragma mark - Line Size Utils

- (NSArray *)sizes
{
    // TODO:    Build from form or param XML
    return @[ @"10", @"12", @"16", @"20", @"25", @"32", @"40", @"50", @"64", @"80", @"100", @"125", @"160", @"200", @"250", @"320", @"400", @"500", @"640" ];
}

- (NSString *)sizeForIndex:(NSInteger)index
{
    if (index < 0 || index >= self.sizes.count) return nil;
    return [self.sizes objectAtIndex:index];
}

- (void)setCurrentSizeIndex:(NSInteger)currentSizeIndex
{
    if (currentSizeIndex < 0) {
        // Smallest size
        _currentSizeIndex = 0;
    } else if (currentSizeIndex >= self.sizes.count) {
        // Largest size
        _currentSizeIndex = self.sizes.count-1;
    } else {
        _currentSizeIndex = currentSizeIndex;
    }
}

#pragma mark - Item Navigation

- (MSSItem *)nextItem
{
    NSString *previousLetter = [StaticVisionItemHelper letterForItem:self.currentItem];
    NSString *sizeKey = [self sizeForIndex:self.currentSizeIndex];
    
    if (self.practiceComplete && self.screeningComplete) {
        // Chart
        if (!_pool) {
            NSMutableDictionary *pool = [NSMutableDictionary dictionaryWithCapacity:self.chart.allValues.count];
            // Adding line to pool based on screening results
            [pool setObject:[_chart objectForKey:sizeKey] forKey:sizeKey];
            _pool = [pool copy];
        }
        
        // Grab a unique (non-repeating) character from the largest available line
        NSArray *line = [self largestAvailableLineFromPool:_pool];
        self.currentItem = [self uniqueItemFromLine:line withPreviousLetter:previousLetter];
 
        // Add item index to chart items (used for debugging)
        NSArray *availableItems = [self availableItemsForLine:line];
        // Item index from line array isn't reliable as it can be shuffled to find a unique letter
        NSInteger itemIndex = line.count - availableItems.count;
        NSMutableDictionary *itemInfo = [self.currentItem.itemInfo mutableCopy];
        [itemInfo setObject:@(itemIndex) forKey:StaticVisionItemInfoItemIndex];
        self.currentItem.itemInfo = [itemInfo copy];
        
    } else if (self.practiceComplete && self.currentItem) {
        // Screen
        NSArray *line = [self.screen objectForKey:sizeKey];
        self.currentItem = [self uniqueItemFromLine:line withPreviousLetter:previousLetter];
    } else if (!self.practiceComplete && self.currentItem) {
         // Practice (Sequence)
        NSUInteger index = [self.itemList indexOfObject:self.currentItem];
        index = (index == NSNotFound) ? 0 : (index + 1);
        MSSItem *nextItem = (index < self.itemList.count) ? [self.itemList objectAtIndex:index] : nil;
        
        // Fail the participant if they run out of practice items
        if (nextItem.Section != self.currentItem.Section && self.administeredItemList.count) {
            self.currentItem = nil;
        } else {
            self.currentItem = nextItem;
        }
    } else {
        // Title
        self.currentItem = [self.itemList firstObject];
    }
    
    return self.currentItem;
}

- (NSArray *)availableItemsForLine:(NSArray *)line
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Position.length == 0"];
    return [line filteredArrayUsingPredicate:predicate];
}

- (MSSItem *)previousItem
{
    MSSItem *currentItem = self.currentItem;
    NSString *currentItemType = currentItem.itemInfo[StaticVisionItemInfoItemType];
    
    // Grab the last item in the adminsteredItems array and clear all values set in process response
    MSSItem *previousItem = [super previousItem];
    NSString *previousItemType = previousItem.itemInfo[StaticVisionItemInfoItemType];
    
    if ( self.screeningComplete && [currentItemType isEqualToString:previousItemType] ) {
    
        // Chart
        
        // Reset the pool to its previous state
        _pool = [_previousPool copy];
        
    }
    
    else if ( self.screeningComplete && ![currentItemType isEqualToString:previousItemType] ) {
        
        // Chart -> Screen
        
        // Go back to screening mode
        self.screeningComplete = NO;
        
        // Remove the pool that was created (starting size can change)
        _pool = nil;
        
        // If the last answer was incorrect, let them go back to the smaller value to try again
        if (self.screeningDirection == 1) {
            self.screeningDirection = 2;
        } else if (self.screeningDirection == 2) {
            NSString *size = [self sizeForIndex:self.currentSizeIndex];
            if (![size isEqualToString:StaticVisionMaxSizeValue]) {
                self.screeningDirection = 1;
                self.currentSizeIndex--;
            }
        }
        
    }
    
    else if ( self.practiceComplete && [currentItemType isEqualToString:previousItemType] ) {
        
        // Screen
        
        // Inspect screening direction and move the size index appropitely
        if (self.screeningDirection == 1) {
            self.currentSizeIndex++;
        } else if (self.screeningDirection == 2) {
            self.currentSizeIndex--;
        }
    }
    
    else if ( self.practiceComplete && ![currentItemType isEqualToString:previousItemType] ) {
        
        // Screen -> Practice
        
        // Go back to practice mode
        self.practiceComplete = NO;
        
        //
        
    }
    
    self.currentItem = previousItem;
    
    return self.currentItem;
}

#pragma mark - Process Response

- (NSArray *)processResponses:(NSArray *)responses withResponseTime:(NSTimeInterval)responseTime
{
    MSSMap *response = [responses firstObject];
    BOOL correct = (response.Value.integerValue == 1);
    
    if (self.practiceComplete && self.screeningComplete) {
        
        // Chart
        
        _previousPool = [_pool copy];

        if (correct) {
            // Correct
            
            // Does the current item belong to the smallest line (available) in the pool?
            if ([self item:self.currentItem isFromSmallestAvailableLineInPool:_pool]) {
                // Is the current line score 3/5 or better?
                NSString *currentSize = [StaticVisionItemHelper sizeForItem:self.currentItem];
                NSArray *currentLine = [self.chart objectForKey:currentSize];
                NSInteger score = [self scoreForLine:currentLine];
                if (score >= 2) { // Current correct item hasn't been responsed to yet 
                    // Does the next smallest line already exist in the pool?
                    NSString *nextSmallestLine = [self sizeForIndex:self.currentSizeIndex-1];
                    if ([self lineSize:nextSmallestLine.integerValue isNotInPool:_pool]) {
                        // Add the next smallest line to the pool
                        NSArray *line = [self.chart objectForKey:nextSmallestLine];
                        if (line.count) {
                            NSMutableDictionary *pool = [_pool mutableCopy];
                            [pool setObject:line forKey:nextSmallestLine];
                            _pool = [pool copy];
                        }
                    }
                }
            }
            
        } else {
            // Incorrect
            
            // Does the current item belong to the largest line (available) in the pool?
            if ([self item:self.currentItem isFromLargestAvailableLineInPool:_pool]) {
                // Does the next largest line already exist in the pool?
                NSString *nextLargestLine = [self sizeForIndex:self.currentSizeIndex+1];
                if ([self lineSize:nextLargestLine.integerValue isNotInPool:_pool]) {
                    // Add the next largest line to the pool
                    NSArray *line = [self.chart objectForKey:nextLargestLine];
                    if (line.count) {
                        NSMutableDictionary *pool = [_pool mutableCopy];
                        [pool setObject:line forKey:nextLargestLine];
                        _pool = [pool copy];
                    }
                }
            }
        }

    } else if (self.practiceComplete) {
        
        // Screen

        NSInteger direction = response.Value.integerValue;
        
        if (correct) {
            // Smaller (correct)
            if (self.currentSizeIndex != 0) {
                self.currentSizeIndex--;
            } else {
                // Min value reached, stop screening
                self.screeningComplete = YES;
            }
        } else {
            // Larger (incorrect)
            if (self.currentSizeIndex != self.sizes.count-1) {
                self.currentSizeIndex++;
            } else {
                // Max value reached, stop screening
                self.screeningComplete = YES;
            }
        }
        
        if (!self.screeningComplete && self.screeningDirection && self.screeningDirection != direction) {
            // Direction changed (correct>incorrect or incorrect>correct), stop screening
            if (response.Value.integerValue == 1) {
                self.currentSizeIndex++;
            }
            self.screeningComplete = YES;
        }
        
        self.screeningDirection = direction;
        
    } else {
        
        // Practice
        if (correct) {
            // TODO:    Update so practice trails (sections) are not hardcoded
            NSInteger trialCount = ceil(self.currentItem.Order/4.0);        // 4 items per trial section, 12 items total (3 trial sections)
            NSInteger practiceScore = 0;
            for (MSSItem *item in self.administeredItemList) {
                NSString *type = item.itemInfo[StaticVisionItemInfoItemType];
                NSInteger trial = ceil(item.Order/4.0);
                if ([type isEqualToString:StaticVisionItemInfoItemTypePractice] && trialCount == trial) {
                    if (item.Response.integerValue == 1) {
                        practiceScore++;
                    }
                }
            }
            if (practiceScore >= 2) {
                // The last 2/3 were correct + 1 for this answer = 3/4
                self.practiceComplete = YES;
            }
            
        }
    }
    
    // TODO:    Process response could be called at the beginning so actual values in only the administeredItems array could be used
    return [super processResponses:responses withResponseTime:responseTime];;
}

#pragma mark - Engine/Item Helpers

- (NSArray *)largestAvailableLineFromPool:(NSDictionary *)pool
{
    // TODO:    Could be cleaner?
    NSInteger largestAvailableSize = 0;
    for (NSArray *array in pool.allValues) {
        for (MSSItem *item in array) {
            // Check to see if the item is available
            if (!item.Position.length) {
                NSInteger size = [StaticVisionItemHelper sizeForItem:item].integerValue;
                if (size > largestAvailableSize) {
                    largestAvailableSize = size;
                }
            }
        }
    }
    NSString *sizeKey = @(largestAvailableSize).stringValue;

    // Update current index based on the largest line selected
    self.currentSizeIndex = [self.sizes indexOfObject:sizeKey];
    
    return [pool objectForKey:sizeKey];
}

- (MSSItem *)uniqueItemFromLine:(NSArray *)line withPreviousLetter:(NSString *)previousLetter
{
    MSSItem *uniqueItem;
    NSMutableArray *availableItems = [[self availableItemsForLine:line] mutableCopy];
    
    // If there are items available on the line
    if (availableItems.count) {
        while (!uniqueItem) {
            // Try to use the first item in the line
            MSSItem *item = [availableItems firstObject];
            NSString *currentLetter = [StaticVisionItemHelper letterForItem:item];
            // Next item's letter is unique?
            if ([currentLetter isEqualToString:previousLetter]) {
                if (availableItems.count == 1) {
                    // Can't shuffle line, must repeat character :(
                    uniqueItem = item;
                } else {
                    // Try again, shuffle the line to get a new character
                    [availableItems removeObject:item];
                    [availableItems addObject:item];
                }
            }
            // Doesn't match, OK to use
            else {
                uniqueItem = item;
            }
        }
    }
    
    return uniqueItem;
}

- (BOOL)item:(MSSItem *)item isFromSmallestAvailableLineInPool:(NSDictionary *)pool
{
    NSInteger itemSize = [StaticVisionItemHelper sizeForItem:item].integerValue;
    for (NSArray *array in pool.allValues) {
        for (MSSItem *item in array) {
            if (!item.Position.length) {
                NSInteger size = [StaticVisionItemHelper sizeForItem:item].integerValue;
                if (size < itemSize) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)item:(MSSItem *)item isFromLargestAvailableLineInPool:(NSDictionary *)pool
{
    NSInteger itemSize = [StaticVisionItemHelper sizeForItem:item].integerValue;
    for (NSArray *array in pool.allValues) {
        for (MSSItem *item in array) {
            if (!item.Position.length) {
                NSInteger size = [StaticVisionItemHelper sizeForItem:item].integerValue;
                if (size > itemSize) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)lineSize:(NSInteger)lineSize isNotInPool:(NSDictionary *)pool
{
    for (NSString *sizeKey in pool.allKeys) {
        if (sizeKey.integerValue == lineSize) {
            return NO;
        }
    }
    
    return YES;
}

- (NSInteger)scoreForLine:(NSArray *)line
{
    NSInteger score = 0;
    for (MSSItem *item in line) {
        if (item.Response.integerValue == 1) {
            score++;
        }
    }
    
    return score;
}

@end