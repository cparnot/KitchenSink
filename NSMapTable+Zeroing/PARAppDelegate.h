//  PARAppDelegate.h
//  NSMapTable+Zeroing
//  Created by Charles Parnot on 12/10/13.


#import <Cocoa/Cocoa.h>

@interface PARAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *console;

+ (NSTextView*) console;

@end
