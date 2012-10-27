//
//  RoundedBox.j
//  RoundedBox
//
//  Created by Alexander Ljungberg on 12/10/2012, based on the original RoundedBox.m created by Matt Gemmell on 01/11/2005.
//  Copyright 2012 SlevenBits Ltd. (Cappuccino parts) and 2006 Matt Gemmell (Cocoa parts). http://mattgemmell.com/
//
//  Permission to use this code:
//
//  Feel free to use this code in your software, either as-is or
//  in a modified form. Either way, please include a credit in
//  your software's "About" box or similar, mentioning at least
//  my name (Matt Gemmell). A link to my site would be nice too.
//
//  Permission to redistribute this code:
//
//  You can redistribute this code, as long as you keep these
//  comments. You can also redistribute modified versions of the
//  code, as long as you add comments to say that you've made
//  modifications (keeping these original comments too).
//
//  If you do use or redistribute this code, an email would be
//  appreciated, just to let me know that people are finding my
//  code useful. You can reach me at matt.gemmell@gmail.com
//

var MG_TITLE_INSET = 3.0;


@implementation RoundedBox : CPBox
{
    BOOL    _drawsTitle;
    float   borderWidth;
    CPColor borderColor;
    CPColor titleColor;
    CPColor gradientStartColor;
    CPColor gradientEndColor;
    CPColor backgroundColor;
    BOOL    drawsFullTitleBar;
    BOOL    selected;
    BOOL    drawsGradientBackground;
    CGRect  titlePathRect;
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}


- (void)dealloc
{
    [borderColor release];
    [titleColor release];
    [gradientStartColor release];
    [gradientEndColor release];
    [backgroundColor release];

    [super dealloc];
}


- (void)setDefaults
{
    _drawsTitle = YES;
    [[self titleView] setLineBreakMode:CPLineBreakByTruncatingTail];
    [[self titleView] setEditable:YES];
    [[self titleView] setDelegate:self];

    borderWidth = 2.0;
    [self setBorderColor:[CPColor grayColor]];
    [self setTitleColor:[CPColor whiteColor]];
    [self setGradientStartColor:[CPColor colorWithCalibratedWhite:0.92 alpha:1.0]];
    [self setGradientEndColor:[CPColor colorWithCalibratedWhite:0.82 alpha:1.0]];
    [self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.90 alpha:1.0]];
    [self setTitleFont:[CPFont boldSystemFontOfSize:[CPFont systemFontSizeForControlSize:CPSmallControlSize]]];

    [self setDrawsFullTitleBar:NO];
    [self setSelected:NO];
    [self setDrawsGradientBackground:YES];
}


- (void)awakeFromCib
{
    // For when we've been created in a nib file
    [self setDefaults];
}


- (BOOL)preservesContentDuringLiveResize
{
    // NSBox returns YES for this, but doing so would screw up the gradients.
    return NO;
}


- (void)mouseDown:(CPEvent)evt {
    if (CPPointInRect([self convertPoint:[evt locationInWindow] fromView:nil], titlePathRect)) {
        [[self window] makeFirstResponder:[self titleView]];
    }
}

- (void)controlTextDidEndEditing:(CPNotification)aNotification
{
    _drawsTitle = YES;
    var stringValue = [[self titleView] stringValue];
    if ([stringValue length] > 0) {
        [self setTitle:stringValue];
    } else {
        [self setNeedsDisplay:YES];
        [[self titleView] setStringValue:[self title]];
    }
}


- (void)resetCursorRects {
    // [self addCursorRect:titlePathRect cursor:[CPCursor IBeamCursor]];
}


- (void)drawRect:(CGRect)rect {

    // Construct rounded rect path
    var boxRect = [self bounds];
    var bgRect = boxRect;
    bgRect = CGRectInset(boxRect, borderWidth / 2.0, borderWidth / 2.0);
    bgRect = CGRectIntegral(bgRect);
    /*bgRect.origin.x += 0.5;
    bgRect.origin.y += 0.5;*/
    var minX = CGRectGetMinX(bgRect);
    var midX = CGRectGetMidX(bgRect);
    var maxX = CGRectGetMaxX(bgRect);
    var minY = CGRectGetMinY(bgRect);
    var midY = CGRectGetMidY(bgRect);
    var maxY = CGRectGetMaxY(bgRect);
    var radius = 4.0;
    var bgPath = [CPBezierPath bezierPath];

    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:CGPointMake(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:CGPointMake(maxX, minY)
                                     toPoint:CGPointMake(maxX, midY)
                                      radius:radius];

    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:CGPointMake(maxX, maxY)
                                     toPoint:CGPointMake(midX, maxY)
                                      radius:radius];

    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:CGPointMake(minX, maxY)
                                     toPoint:CGPointMake(minX, midY)
                                      radius:radius];

    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:CGPointMake(minX, minY)
                                     toPoint:CGPointMake(midX, minY)
                                      radius:radius];
    [bgPath closePath];


    // Draw background

    if ([self drawsGradientBackground])
    {
        // Draw gradient background
        var nsContext = [CPGraphicsContext currentContext];
        [nsContext saveGraphicsState];
        [bgPath addClip];
        var gradient = [[CPGradient alloc] initWithColors:[[self gradientStartColor], [self gradientEndColor]]];
        var gradientRect = [bgPath bounds];
        [gradient drawInRect:gradientRect angle:90.0];
        [nsContext restoreGraphicsState];
    }
    else
    {
        // Draw solid color background
        [backgroundColor set];
        [bgPath fill];
    }


    // Create drawing rectangle for title

    var titleHInset = borderWidth + MG_TITLE_INSET + 1.0;
    var titleVInset = borderWidth + 3.0;
    var titleSize = [[self title] sizeWithFont:[[self titleView] font]];

    var titleRect = CGRectMake(boxRect.origin.x + titleHInset,
                               boxRect.origin.y + titleVInset,
                               titleSize.width + (borderWidth * 2.0),
                               titleSize.height + 4.0);
    titleRect.size.width = MIN(titleRect.size.width, boxRect.size.width - (2.0 * titleHInset));

    if ([self selected]) {
        [[CPColor alternateSelectedControlColor] set];
        // We use the alternate (darker) selectedControlColor since the regular one is too light.
        // The alternate one is the highlight color for NSTableView, NSOutlineView, etc.
        // This mimics how Automator highlights the selected action in a workflow.
    } else {
        [borderColor set];
    }


    // Draw title background
    var titlePath = [self titlePathWithinRect:bgRect cornerRadius:radius titleRect:titleRect];
    [titlePath fill];
    titlePathRect = [titlePath bounds];


    // Draw rounded rect around entire box
    if (borderWidth > 0.0) {
        [bgPath setLineWidth:borderWidth];
        [bgPath stroke];
    }


    // Draw title text using the titleView
    if (_drawsTitle)
    {
        [[self titleView] setFrame:titleRect];
        // [[self titleView] drawInteriorWithFrame:titleRect inView:self];
    }
}


- (CPBezierPath)titlePathWithinRect:(CGRect)rect cornerRadius:(float)radius titleRect:(CGRect)titleRect
{
    // Construct rounded rect path

    var bgRect = rect;
    var minX = CGRectGetMinX(bgRect);
    var maxX = minX + titleRect.size.width + ((titleRect.origin.x - rect.origin.x) * 2.0);
    var maxY = CGRectGetMaxY(titleRect);
    var minY = CGRectGetMinY(rect);
    var titleExpansionThreshold = 20.0;
    // i.e. if there's less than 20px space to the right of the short titlebar, just draw the full one.

    var path = [CPBezierPath bezierPath];

    [path moveToPoint:CGPointMake(minX, maxY)];

    if (bgRect.size.width - titleRect.size.width >= titleExpansionThreshold && ![self drawsFullTitleBar] && _drawsTitle) {
        // Draw a short titlebar
        [path appendBezierPathWithArcFromPoint:CGPointMake(maxX, maxY)
                                       toPoint:CGPointMake(maxX, minY)
                                        radius:radius];
        [path lineToPoint:CGPointMake(maxX, minY)];
    } else {
        // Draw full titlebar, since we're either set to always do so, or we don't have room for a short one.
        [path lineToPoint:CGPointMake(CGRectGetMaxX(bgRect), maxY)];
        [path appendBezierPathWithArcFromPoint:CGPointMake(CGRectGetMaxX(bgRect), minY)
                                       toPoint:CGPointMake(CGRectGetMaxX(bgRect) - (bgRect.size.width / 2.0), minY)
                                        radius:radius];
    }

    [path appendBezierPathWithArcFromPoint:CGPointMake(minX, minY)
                                   toPoint:CGPointMake(minX, maxY)
                                    radius:radius];

    [path closePath];

    return path;
}


- (void)setTitle:(CPString)newTitle
{
    [super setTitle:newTitle];
    // [[self window] invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
}


- (BOOL)drawsFullTitleBar
{
    return drawsFullTitleBar;
}


- (void)setDrawsFullTitleBar:(BOOL)newDrawsFullTitleBar
{
    drawsFullTitleBar = newDrawsFullTitleBar;
    // [[self window] invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
}


- (BOOL)selected
{
    return selected;
}


- (void)setSelected:(BOOL)newSelected
{
    selected = newSelected;
    [self setNeedsDisplay:YES];
}


- (CPColor)borderColor
{
    return borderColor;
}


- (void)setBorderColor:(CPColor)newBorderColor
{
    [newBorderColor retain];
    [borderColor release];
    borderColor = newBorderColor;
    [self setNeedsDisplay:YES];
}


- (CPColor)titleColor
{
    return titleColor;
}


- (void)setTitleColor:(CPColor)newTitleColor
{
    [[self titleView] setTextColor:newTitleColor];
    [self setNeedsDisplay:YES];
}


- (CPColor)gradientStartColor
{
    return gradientStartColor;
}


- (void)setGradientStartColor:(CPColor)newGradientStartColor
{
    var newCalibratedGradientStartColor = [newGradientStartColor colorUsingColorSpaceName:CPCalibratedRGBColorSpace];
    [newCalibratedGradientStartColor retain];
    [gradientStartColor release];
    gradientStartColor = newCalibratedGradientStartColor;
    if ([self drawsGradientBackground]) {
        [self setNeedsDisplay:YES];
    }
}


- (CPColor)gradientEndColor
{
    return gradientEndColor;
}


- (void)setGradientEndColor:(CPColor)newGradientEndColor
{
    var newCalibratedGradientEndColor = [newGradientEndColor colorUsingColorSpaceName:CPCalibratedRGBColorSpace];
    [newCalibratedGradientEndColor retain];
    [gradientEndColor release];
    gradientEndColor = newCalibratedGradientEndColor;
    if ([self drawsGradientBackground]) {
        [self setNeedsDisplay:YES];
    }
}


- (CPColor)backgroundColor
{
    return backgroundColor;
}


- (void)setBackgroundColor:(CPColor)newBackgroundColor
{
    [newBackgroundColor retain];
    [backgroundColor release];
    backgroundColor = newBackgroundColor;
    if (![self drawsGradientBackground]) {
        [self setNeedsDisplay:YES];
    }
}


- (BOOL)drawsGradientBackground
{
    return drawsGradientBackground;
}


- (void)setDrawsGradientBackground:(BOOL)newDrawsGradientBackground
{
    drawsGradientBackground = newDrawsGradientBackground;
    [self setNeedsDisplay:YES];
}


@end

