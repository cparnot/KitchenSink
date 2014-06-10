//  PARAppDelegate.m
//  NSMapTable+Zeroing
//  Created by Charles Parnot on 12/10/13.


#import "PARAppDelegate.h"


#pragma mark - Marker Objects

static NSTextView *sharedConsole;
static NSUInteger countAdded = 0, countTotal = 0, countDeallocated = 0;
static NSHashTable *liveMarkers = nil;
static BOOL shouldLog = NO;

@interface PARMarker : NSObject
@property NSUInteger markerIndex;
@end

@implementation PARMarker

- (id)init
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"Not on the main thread");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        liveMarkers = [NSHashTable weakObjectsHashTable];
    });
    
    self = [super init];
    if (self)
    {
        self.markerIndex = countTotal;
        [liveMarkers addObject:self];
        countTotal ++;
        if (shouldLog)
            printf("+++ %s\n", [[@(self.markerIndex) description] UTF8String]);
    }
    
    return self;
}

- (void)dealloc
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"Not on the main thread");
    if (shouldLog)
        printf("--- %s\n", [[@(self.markerIndex) description] UTF8String]);
    countDeallocated ++;
}

@end



#pragma mark - App Delegate

@interface PARAppDelegate ()

// state
@property (strong) NSMapTable *mapTable;
@property NSUInteger mapTableType;

// UI
@property (weak, nonatomic) IBOutlet NSPopUpButton *mapTableTypeButton;
@property (weak, nonatomic) IBOutlet NSTextField *addedField, *countField, *keyCountField, *objectCountField, *createdField, *liveField, *deallocatedField, *entriesToAddField;
@property (weak, nonatomic) IBOutlet NSButton *logCheckBox;
@end

@implementation PARAppDelegate

+ (NSTextView*) console { return sharedConsole; }

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)awakeFromNib
{
    [self resetAll:self]; if(!sharedConsole) sharedConsole = _console;
}

- (void)refreshUI
{
    self.addedField.stringValue       = [@(countAdded) description];
    self.countField.stringValue       = [@(self.mapTable.count) description];
    self.keyCountField.stringValue    = [@(self.mapTable.keyEnumerator.allObjects.count)    description];
    self.objectCountField.stringValue = [@(self.mapTable.objectEnumerator.allObjects.count) description];

    self.createdField.stringValue     = [@(countTotal) description];
    self.deallocatedField.stringValue = [@(countDeallocated) description];
    self.liveField.stringValue        = [@(countTotal - countDeallocated) description];
}

- (IBAction)changeTypeOfMapTable:(id)sender
{
    NSUInteger type = self.mapTableTypeButton.selectedItem.tag;
    if (type == self.mapTableType)
        return;
    
    if (type == 1)
        self.mapTable = [NSMapTable strongToWeakObjectsMapTable];
    else if (type == 2)
        self.mapTable = [NSMapTable weakToStrongObjectsMapTable];
    else if (type == 3)
        self.mapTable = [NSMapTable weakToWeakObjectsMapTable];
    else if (type == 4)
        self.mapTable = [NSMapTable strongToStrongObjectsMapTable];

    self.mapTableType = type;
    
    countAdded = 0;
    
    [self refreshUI];
}

- (IBAction)mapTableReplace:(id)sender
{
    self.mapTableType = 0;
    [self changeTypeOfMapTable:self.mapTableTypeButton];
    [self refreshUI];
}

- (IBAction)mapTableRemoveAllObjects:(id)sender
{
    [self.mapTable removeAllObjects];
    [self refreshUI];
}

- (IBAction)mapTableRemoveObjectsForLiveKeys:(id)sender
{
    // using liveMarkers.allObjects to keep them alive until done
    @autoreleasepool
    {
        for (id marker in liveMarkers.allObjects)
        {
            [self.mapTable removeObjectForKey:marker];
        }
    }
    [self refreshUI];
}

- (IBAction)resetAll:(id)sender
{
    [self mapTableReplace:self];
    countTotal = 0;
    countDeallocated = 0;
    [self refreshUI];
}

- (IBAction)addEntriesToMapTable:(id)sender
{
    @autoreleasepool
    {
        NSUInteger addCount = [self.entriesToAddField.stringValue integerValue];
        for (NSUInteger i = 0; i < addCount; i++)
        {
            PARMarker *key = [[PARMarker alloc] init];
            PARMarker *object = [[PARMarker alloc] init];
            if (shouldLog)
            {
                printf("addentry with key: %s\n"
                       "           object: %s\n", [[@(key.markerIndex) description] UTF8String], [[@(object.markerIndex) description] UTF8String]);
            }
            [self.mapTable setObject:object forKey:key];
        }
        countAdded += addCount;
    }
    [self refreshUI];
}

- (IBAction)refresh:(id)sender
{
    [self refreshUI];
}

- (IBAction)toggleLog:(id)sender
{
    shouldLog = self.logCheckBox.state == NSOnState ? YES : NO;



}

@end
