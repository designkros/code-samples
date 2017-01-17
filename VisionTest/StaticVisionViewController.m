//
//  StaticVisionViewController.m
//  Sample
//
//  Created by Michael Rose on 4/8/15.
//  Copyright (c) 2015 Michael Rose. All rights reserved.
//

#import "StaticVisionViewController.h"

#import "StaticVisionConstants.h"
#import "StaticVisionItemHelper.h"
#import "StaticVisionAttributedStringHelper.h"
#import "StaticVisionScoreCalculations.h"

#import "StaticVisionFlowLayout.h"
#import "StaticVisionInstructionCell.h"
#import "StaticVisionOptotypeCell.h"

NSString * const StaticVisionInstructionCellKey = @"InstructionCell";
NSString * const StaticVisionOptotypeCellKey = @"OptotypeCell";

@interface StaticVisionViewController ()
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *sizeLabel;
@property (strong, nonatomic) UILabel *indexLabel;
@property (strong, nonatomic) NSArray *objects;
@property (nonatomic) StaticVisionKeyboardResponse keyboardResponse;
@property (nonatomic) NSInteger previousSize;
@property (nonatomic) NSInteger previousIndex;
@property (nonatomic) BOOL canSlide;
@property (nonatomic) BOOL didGoBack;
@end

@implementation StaticVisionViewController

#pragma mark - instrument init

- (id)initWithInstrument:(MSSInstrument *)instrument user:(MSSUser *)user engine:(id<Engine>)engine bundle:(NSBundle *)bundle
{
    self = [super initWithInstrument:instrument user:user engine:engine bundle:bundle];
    if (self) {
        _keyboardResponse = StaticVisionKeyboardResponseNone;
        _previousSize = 0;
        _canSlide = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLayoutConstraint *cnX;
    NSLayoutConstraint *cnY;
    NSLayoutConstraint *cnWidth;
    NSLayoutConstraint *cnHeight;
    
    // self
    self.view.backgroundColor = [UIColor whiteColor];
    
    // collection view
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[StaticVisionFlowLayout alloc] init]];
    [_collectionView registerClass:[StaticVisionInstructionCell class] forCellWithReuseIdentifier:StaticVisionInstructionCellKey];
    [_collectionView registerClass:[StaticVisionOptotypeCell class] forCellWithReuseIdentifier:StaticVisionOptotypeCellKey];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.scrollEnabled = NO;
    _collectionView.userInteractionEnabled = NO;
    [self.view addSubview:_collectionView];
    
    // collection view > auto layout
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    cnX = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    cnY = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    cnWidth = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    cnHeight = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self.view addConstraints:@[ cnX, cnY, cnWidth, cnHeight ]];
    
    // size label
    _sizeLabel = [[UILabel alloc] init];
    _sizeLabel.hidden = YES;
    [self.view addSubview:_sizeLabel];
    
    _sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    cnX = [NSLayoutConstraint constraintWithItem:_sizeLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:25.0];
    cnY = [NSLayoutConstraint constraintWithItem:_sizeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-25.0];
    cnWidth = [NSLayoutConstraint constraintWithItem:_sizeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:200.0];
    cnHeight = [NSLayoutConstraint constraintWithItem:_sizeLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0 constant:25.0];
    [self.view addConstraints:@[ cnX, cnY, cnWidth, cnHeight ]];
    
    // index label
    _indexLabel = [[UILabel alloc] init];
    _indexLabel.hidden = YES;
    [self.view addSubview:_indexLabel];
    
    _indexLabel.translatesAutoresizingMaskIntoConstraints = NO;
    cnX = [NSLayoutConstraint constraintWithItem:_indexLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-25.0];
    cnY = [NSLayoutConstraint constraintWithItem:_indexLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-25.0];
    cnWidth = [NSLayoutConstraint constraintWithItem:_indexLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0 constant:200.0];
    cnHeight = [NSLayoutConstraint constraintWithItem:_indexLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0 constant:25.0];
    [self.view addConstraints:@[ cnX, cnY, cnWidth, cnHeight ]];
}

# pragma mark - instrument life-cycle

- (void)startInstrument
{
    [self nextItem];
}

- (void)stopInstrument
{
    [self stopAllSounds];
    
    //
}

- (void)previousItem
{
    _didGoBack = YES;
    
    self.currentItem = [self.engine previousItem];
    
    if (self.currentItem) {
        [self displayItem:self.currentItem];
    }
}

- (void)nextItem
{
    _didGoBack = NO;
    
    self.currentItem = [self.engine nextItem];
    
    if (self.currentItem) {
        [self displayItem:self.currentItem];
    } else {
        // Instrument is finished, calculate score
        StaticVisionScoreCalculations *calc = [[StaticVisionScoreCalculations alloc] init];
        self.instrument.scores = [calc calculatedScoresFromItemList:self.instrument.items];
        NSLog(@"scores: %@", self.instrument.scores);
        
        [self.delegate instrumentDidFinish:self.instrument];
    }
}

- (void)displayItem:(MSSItem *)item
{
    [super displayItem:item];

    // Reset
    _keyboardResponse = StaticVisionKeyboardResponseNone;
    _objects = nil;
    
    // Determine item type
    NSString *type = item.itemInfo[StaticVisionItemInfoItemType];

    // Parse item
    /*
    MSSElement *element = [item.elements objectAtIndex:0];
    MSSResource *resource = [element.resources objectAtIndex:0];
    NSString *description = resource.Description;
    */
     
    // Flow layout
    StaticVisionFlowLayout *layout = (StaticVisionFlowLayout *)self.collectionView.collectionViewLayout;
    layout.slide = NO;
    
    if ([type isEqualToString:StaticVisionItemInfoItemTypeTitle]) {
            
        // Title
        NSAttributedString *displayText = [StaticVisionAttributedStringHelper instructionAttributedStringForString:self.instrument.title];
        NSAttributedString *instructionText = [StaticVisionAttributedStringHelper adminInstructionAttributedStringForString:StaticVisionPressSpacebarText];
        
        NSDictionary *dict = @{ StaticVisionObjectDisplayTextKey : displayText, StaticVisionObjectInstructionTextKey : instructionText };
        
        _objects = @[ dict ];
        
    }
            
    else if ([type isEqualToString:StaticVisionItemInfoItemTypePractice] || [type isEqualToString:StaticVisionItemInfoItemTypeScreen] || [type isEqualToString:StaticVisionItemInfoItemTypeChart]) {
        
        // Optotype (Practice, Screen or Chart)
        NSString *filename = [StaticVisionItemHelper filenameForItem:self.currentItem];
        NSString *size = [StaticVisionItemHelper sizeForItem:item];
        NSAttributedString *attributedSize = [StaticVisionAttributedStringHelper debugSizeAttributedStringForString:size];
    
        NSString *indexString;
        if ([type isEqualToString:StaticVisionItemInfoItemTypePractice]) {
            indexString = @"PRACTICE";
        } else if ([type isEqualToString:StaticVisionItemInfoItemTypeScreen]) {
            indexString = @"SCREEN";
        } else {
            NSNumber *itemIndex = self.currentItem.itemInfo[StaticVisionItemInfoItemIndex];
            indexString = [NSString stringWithFormat:@"%@/5", @(itemIndex.integerValue+1)];
        }
       
        NSAttributedString *attributedIndex = [StaticVisionAttributedStringHelper debugIndexAttributedStringForString:indexString];
        NSDictionary *dict = @{ StaticVisionObjectFilenameKey : filename, StaticVisionObjectSizeKey : attributedSize, StaticVisionObjectIndexKey : attributedIndex };
        
        _objects = @[ dict ];
        
        // Slide layout
        layout.slide = _canSlide;
        layout.reverse = _didGoBack;
        layout.oldSize = _previousSize;
        layout.newSize = size.integerValue;
        _previousSize = layout.newSize;
    }
    
    // Reload the collection view
    NSTimeInterval duration = (_canSlide) ? 0.5 : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [_collectionView performBatchUpdates:^{
            [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:^(BOOL finished) {
            //
        }];
    } completion:nil];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    NSString *type = self.currentItem.itemInfo[StaticVisionItemInfoItemType];
    if ([type isEqualToString:StaticVisionItemInfoItemTypeTitle]) {
        // title
        StaticVisionInstructionCell *instructionCell = [collectionView dequeueReusableCellWithReuseIdentifier:StaticVisionInstructionCellKey forIndexPath:indexPath];
        [self configureInstructionCell:instructionCell atIndexPath:indexPath];
        cell = instructionCell;
    } else if ([type isEqualToString:StaticVisionItemInfoItemTypePractice] || [type isEqualToString:StaticVisionItemInfoItemTypeScreen] || [type isEqualToString:StaticVisionItemInfoItemTypeChart]) {
        // optotype (screen or chart)
        StaticVisionOptotypeCell *optotypeCell = [collectionView dequeueReusableCellWithReuseIdentifier:StaticVisionOptotypeCellKey forIndexPath:indexPath];
        [self configureOptotypeCell:optotypeCell atIndexPath:indexPath];
        cell = optotypeCell;
    }
    
    return cell;
}

- (void)configureInstructionCell:(StaticVisionInstructionCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [_objects lastObject];
    
    cell.displayTextLabel.attributedText = dict[StaticVisionObjectDisplayTextKey];
    cell.instructionTextLabel.attributedText = dict[StaticVisionObjectInstructionTextKey];
}

- (void)configureOptotypeCell:(StaticVisionOptotypeCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [_objects lastObject];
    
    UIImage *image = [self imageForImageName:dict[StaticVisionObjectFilenameKey]];
    cell.imageView.image = image;
    
    _sizeLabel.attributedText = dict[StaticVisionObjectSizeKey];
    _indexLabel.attributedText = dict[StaticVisionObjectIndexKey];
}

#pragma mark - collection view flow layout delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.bounds.size;
}

#pragma mark - process response

- (void)processResponse:(StaticVisionKeyboardResponse)response
{
    if (response != StaticVisionKeyboardResponseNone) {
        MSSMap *map = [StaticVisionItemHelper mapForItem:self.currentItem andKeyboardResponse:response];
        [self submitResponseWithMap:map];
    }
}

- (void)submitResponseWithMap:(MSSMap *)map
{
    if (map.ItemResponseOID.length) {
        NSArray *processedItems = [self.engine processResponses:@[map] withResponseTime:0];
        if (processedItems.count) {
            [self.delegate instrument:self.instrument didReceiveResponsesForItemsInArray:processedItems];
        }
    }
    
    [self nextItem];
}
 
#pragma mark - key commands

- (NSArray *)keyCommands
{
    UIKeyCommand *zeroKeyCommand = [UIKeyCommand keyCommandWithInput:@"0" modifierFlags:0 action:@selector(didTapZero)];
    UIKeyCommand *zeroCapsKeyCommand = [UIKeyCommand keyCommandWithInput:@"0" modifierFlags:UIKeyModifierAlphaShift action:@selector(didTapZero)];
    UIKeyCommand *oneKeyCommand = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:0 action:@selector(didTapOne)];
    UIKeyCommand *oneCapsKeyCommand = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierAlphaShift action:@selector(didTapOne)];
    UIKeyCommand *spaceKeyCommand = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(didTapSpace)];
    UIKeyCommand *spaceCapsKeyCommand = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:UIKeyModifierAlphaShift action:@selector(didTapSpace)];
    UIKeyCommand *leftArrowKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(didTapLeftArrow)];
    UIKeyCommand *leftArrowCapsKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:UIKeyModifierAlphaShift action:@selector(didTapLeftArrow)];
    UIKeyCommand *ctrlShiftQKeyCommand = [UIKeyCommand keyCommandWithInput:@"q" modifierFlags:UIKeyModifierControl|UIKeyModifierCommand action:@selector(didTapAdmin)];
    UIKeyCommand *ctrlShiftQCapsKeyCommand = [UIKeyCommand keyCommandWithInput:@"q" modifierFlags:UIKeyModifierAlphaShift|UIKeyModifierControl|UIKeyModifierCommand action:@selector(didTapAdmin)];
    
    UIKeyCommand *debugKeyCommand = [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(didTapDebug)];
    UIKeyCommand *debugCapsKeyCommand = [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:UIKeyModifierAlphaShift action:@selector(didTapDebug)];
    
    return @[ zeroKeyCommand, zeroCapsKeyCommand, oneKeyCommand, oneCapsKeyCommand, spaceKeyCommand, spaceCapsKeyCommand, leftArrowKeyCommand, leftArrowCapsKeyCommand, ctrlShiftQKeyCommand, ctrlShiftQCapsKeyCommand, debugKeyCommand, debugCapsKeyCommand ];
}

- (void)didTapZero
{
    // Incorrect
    _keyboardResponse = StaticVisionKeyboardResponseIncorrect;
}

- (void)didTapOne
{
    // Correct
    _keyboardResponse = StaticVisionKeyboardResponseCorrect;
}

- (void)didTapSpace
{
    // Advance
    NSString *type = self.currentItem.itemInfo[StaticVisionItemInfoItemType];
    if ([type isEqualToString:StaticVisionItemInfoItemTypeTitle]) {
        // the instrument did start after the title screen did advance
        [self.delegate instrumentDidStart:self.instrument];
        [self nextItem];
    } else {
        [self processResponse:_keyboardResponse];
    }
}

- (void)didTapLeftArrow
{
    // Don't allow go back on the title screen
    // TODO:    Making administeredItems a public property on the Engine protocol would be ideal
    //          if (engine.adminsiteredItems.count)
    NSString *type = self.currentItem.itemInfo[StaticVisionItemInfoItemType];
    if (![type isEqualToString:StaticVisionItemInfoItemTypeTitle]) {
        if (!_didGoBack) {
            [self previousItem];
        }
    }
}

- (void)didTapAdmin
{
    [self.delegate didReceiveAdminKeyCommandFromInstrument:self.instrument];
}

- (void)didTapDebug
{
    _canSlide = !_canSlide;
    _sizeLabel.hidden = !_sizeLabel.hidden;
    _indexLabel.hidden = !_indexLabel.hidden;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - media utility

- (NSString *)localizedTextForKey:(NSString *)key
{
    return [self localizedTextForKey:key fromBundle:self.bundle];
}

- (UIImage *)imageForImageName:(NSString *)imageName
{
    return [self imageForImageName:imageName fromBundle:self.bundle];
}

- (void)playLocalizedSound:(NSString *)filename
{
    [self playLocalizedSound:filename afterDelay:0];
}

- (void)playLocalizedSound:(NSString *)filename afterDelay:(NSTimeInterval)delay
{
    [self playLocalizedSound:filename fromBundle:self.bundle afterDelay:delay];
}

- (NSTimeInterval)localizedSoundDuration:(NSString *)filename
{
    return [self localizedSoundDuration:filename fromBundle:self.bundle];
}

@end