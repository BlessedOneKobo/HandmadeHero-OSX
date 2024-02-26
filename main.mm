#include <AppKit/AppKit.h>
#include <stdio.h>

#define WINDOW_WIDTH 640
#define WINDOW_HEIGHT 480
#define BYTES_PER_PIXEL 4

bool Running = true;

uint8_t *buffer;
int bitmapWidth;
int bitmapHeight;
int bytesPerRow;

@interface MainWindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation MainWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    Running = false;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    bitmapWidth = sender.contentView.bounds.size.width;
    bitmapHeight = sender.contentView.bounds.size.height;
    bytesPerRow = bitmapWidth * BYTES_PER_PIXEL;
    return frameSize;
}

@end

void refreshBuffer(NSWindow *window) {
    if (buffer) {
        free(buffer);
    }

    bitmapWidth = window.contentView.bounds.size.width;
    bitmapHeight = window.contentView.bounds.size.height;
    bytesPerRow = bitmapWidth * BYTES_PER_PIXEL;
    buffer = (uint8_t *)malloc(bytesPerRow * bitmapHeight);
}

int main(int argc, char *argv[]) {
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect contentRect =
        NSMakeRect((screenRect.size.width - WINDOW_WIDTH) * 0.5,
                   (screenRect.size.height - WINDOW_HEIGHT) * 0.5, WINDOW_WIDTH,
                   WINDOW_HEIGHT);
    NSWindow *window =
        [[NSWindow alloc] initWithContentRect:contentRect
                                    styleMask:NSWindowStyleMaskTitled |
                                              NSWindowStyleMaskClosable |
                                              NSWindowStyleMaskMiniaturizable |
                                              NSWindowStyleMaskResizable
                                      backing:NSBackingStoreBuffered
                                        defer:YES];

    [window setDelegate:[[MainWindowDelegate alloc] init]];
    [window setTitle:@"Handmade Hero"];
    [window setLevel:NSMainMenuWindowLevel + 1];
    [window makeKeyAndOrderFront:nil];
    window.contentView.wantsLayer = YES;

    refreshBuffer(window);

    int offsetX = 0;
    int offsetY = 0;

    while (Running) {
        uint8_t *row = (uint8_t *)buffer;
        for (int y = 0; y < bitmapHeight; ++y) {
            uint8_t *channel = (uint8_t *)row;
            for (int x = 0; x < bitmapWidth; ++x) {
                *channel++ = 0;                      // red
                *channel++ = (uint8_t)(x + offsetX); // green
                *channel++ = (uint8_t)(y + offsetY); // blue
                *channel++ = 255;                    // alpha
            }
            row += bytesPerRow;
        }
        offsetX = (offsetX + 1) % 256;
        offsetY = (offsetY + 1) % 256;

        @autoreleasepool {
            NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes:&buffer
                              pixelsWide:bitmapWidth
                              pixelsHigh:bitmapHeight
                           bitsPerSample:8
                         samplesPerPixel:BYTES_PER_PIXEL
                                hasAlpha:YES
                                isPlanar:NO
                          colorSpaceName:NSDeviceRGBColorSpace
                             bytesPerRow:bytesPerRow
                            bitsPerPixel:8 * BYTES_PER_PIXEL] autorelease];
            NSImage *image = [[[NSImage alloc]
                initWithSize:NSMakeSize(bitmapWidth, bitmapHeight)]
                autorelease];
            [image addRepresentation:rep];
            window.contentView.layer.contents = image;
        }

        refreshBuffer(window);

        NSEvent *event;
        do {
            event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                       untilDate:nil
                                          inMode:NSDefaultRunLoopMode
                                         dequeue:YES];
            [NSApp sendEvent:event];
        } while (event != nil);
    }

    return 0;
}
