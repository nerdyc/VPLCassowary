#import "VPLLayer.h"
#import "VPLLayoutConstraint.h"

@interface VPLLayer ()

// ===== SUBLAYERS =====================================================================================================
#pragma mark - Sublayers

@property (nonatomic, strong, readwrite) NSArray * sublayers;
@property (nonatomic, weak,   readwrite) VPLLayer * superlayer;

@property (nonatomic, strong, readwrite) NSArray * layoutConstraints;

@property (nonatomic, strong, readwrite) VPLLayoutConstraint * intrinsicWidthConstraint;
@property (nonatomic, strong, readwrite) VPLLayoutConstraint * intrinsicHeightConstraint;

@property (nonatomic, assign, readwrite) CTFramesetterRef textFramesetterRef;
@property (nonatomic, assign, readwrite) CFAttributedStringRef attributedTextRef;

@end

@implementation VPLLayer

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (instancetype)init
{
  return [self initWithIdentifier:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
  self = [super init];
  if (self != nil)
  {
    _sublayers = @[];
    _identifier = identifier;
    _frame = CGRectZero;
    _layoutConstraints = @[];
  }
  return self;
}

+ (instancetype)layerWithDictionary:(NSDictionary *)layerDictionary
                              error:(NSError * __autoreleasing *)error
{
  NSString * identifier = layerDictionary[@"identifier"];
  VPLLayer * layer = [[self alloc] initWithIdentifier:identifier];
  
  // text
  layer.text = layerDictionary[@"text"];
  
  // background color
  CGColorRef backgroundColorRef = NULL;
  NSArray * backgroundColorArray = layerDictionary[@"backgroundColor"];
  if (backgroundColorArray != nil)
  {
    CGFloat red   = [[backgroundColorArray objectAtIndex:0] floatValue];
    CGFloat green = [[backgroundColorArray objectAtIndex:1] floatValue];
    CGFloat blue  = [[backgroundColorArray objectAtIndex:2] floatValue];
    CGFloat alpha = [[backgroundColorArray objectAtIndex:3] floatValue];
    
    backgroundColorRef = CGColorCreateGenericRGB(red, green, blue, alpha);
    
    layer.backgroundColorRef = backgroundColorRef;
    
    CGColorRelease(backgroundColorRef);
  }
  
  // extract sublayers
  NSArray * sublayersDataArray = layerDictionary[@"sublayers"];
  if (sublayersDataArray != nil)
  {
    for (NSDictionary * sublayerData in sublayersDataArray)
    {
      VPLLayer * sublayer = [self layerWithDictionary:sublayerData
                                               error:error];
      if (sublayer != nil)
      {
        [layer addSublayer:sublayer];
      }
      else
      {
        return nil;
      }
    }
  }
  
  // extract constraints
  NSArray * constraintsDataArray = layerDictionary[@"constraints"];
  NSMutableArray * layoutConstraints = [[NSMutableArray alloc] initWithCapacity:[constraintsDataArray count]];
  if (constraintsDataArray != nil)
  {
    for (NSDictionary * constraintData in constraintsDataArray)
    {
      VPLLayoutConstraint * layoutConstraint = [[VPLLayoutConstraint alloc] initWithDictionary:constraintData];
      [layoutConstraints addObject:layoutConstraint];
    }
  }
  layer.layoutConstraints = layoutConstraints;
  
  return layer;
}

- (void)dealloc
{
  if (_backgroundColorRef != NULL)
  {
    CGColorRelease(_backgroundColorRef);
    _backgroundColorRef = NULL;
  }

  for (VPLLayer * sublayer in [self.sublayers copy])
  {
    [sublayer removeFromSuperlayer];
  }
}

// ===== GEOMETRY ======================================================================================================
#pragma mark - Geometry

NSString *
NSStringFromCFString(CFStringRef stringRef)
{
  return (__bridge NSString *)stringRef;
}

CFStringRef
CFStringFromNSString(NSString * string)
{
  return (__bridge CFStringRef)string;
}

- (CGSize)intrinsicContentSize
{
  CTFramesetterRef framesetterRef = self.textFramesetterRef;
  if (framesetterRef != NULL)
  {
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.textFramesetterRef,
                                                                   CFRangeMake(0, 0), // the whole string
                                                                   NULL,
                                                                   CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), // unconstrained
                                                                   NULL);
    
    
    textSize.width = ceil(textSize.width);
    textSize.height = ceil(textSize.height);
    
    return textSize;
  }
  else
  {
    return CGSizeMake(-1, -1);
  }
}

// ===== CONSTRAINTS ===================================================================================================
#pragma mark - Constraints

- (void)updateConstraints
{
  NSMutableArray * updatedConstraints = [[NSMutableArray alloc] initWithArray:self.layoutConstraints];
  
  if (self.intrinsicWidthConstraint != nil)
  {
    [updatedConstraints removeObject:self.intrinsicWidthConstraint];
    self.intrinsicWidthConstraint = nil;
  }
  
  if (self.intrinsicHeightConstraint != nil)
  {
    [updatedConstraints removeObject:self.intrinsicHeightConstraint];
    self.intrinsicHeightConstraint = nil;
  }
  
  CGSize intrinsicContentSize = self.intrinsicContentSize;
  NSLog(@"%@.intrinsicContentSize.width == %f", self.identifier, intrinsicContentSize.width);
  if (intrinsicContentSize.width >= 0)
  {
    // setup a width constraint
    self.intrinsicWidthConstraint = [[VPLLayoutConstraint alloc] initWithSubject:self.identifier
                                                                      attribute:@"width"
                                                                   relationship:@"=="
                                                                  relatedObject:nil
                                                               relatedAttribute:nil
                                                                     multiplier:0
                                                                       constant:intrinsicContentSize.width];
    
    [updatedConstraints addObject:self.intrinsicWidthConstraint];
  }
  
  NSLog(@"%@.intrinsicContentSize.height == %f", self.identifier, intrinsicContentSize.height);
  if (intrinsicContentSize.height >= 0)
  {
    self.intrinsicHeightConstraint = [[VPLLayoutConstraint alloc] initWithSubject:self.identifier
                                                                       attribute:@"height"
                                                                    relationship:@"=="
                                                                   relatedObject:nil
                                                                relatedAttribute:nil
                                                                      multiplier:0
                                                                        constant:intrinsicContentSize.height];
    
    
    [updatedConstraints addObject:self.intrinsicHeightConstraint];
  }
  
  self.layoutConstraints = updatedConstraints;

}

// ===== LAYER HIERARCHY ===============================================================================================
#pragma mark - Layer Hierarchy

@synthesize sublayers = _sublayers;

- (BOOL)isAncestorOfLayer:(VPLLayer *)sublayer
{
  return [sublayer isDescendentOfLayer:self];
}

- (BOOL)isDescendentOfLayer:(VPLLayer *)superlayer
{
  return superlayer == self || [self.superlayer isDescendentOfLayer:superlayer];
}

- (void)addSublayer:(VPLLayer *)sublayer
{
  [self insertSublayer:sublayer
               atIndex:[self.sublayers count]];
}

- (void)removeFromSuperlayer
{
  [self.superlayer removeSublayer:self];
}

// ----- HIERARCHY MUTATORS --------------------------------------------------------------------------------------------
#pragma mark Hierarchy Mutators

- (void)insertSublayer:(VPLLayer *)sublayer
               atIndex:(NSUInteger)sublayerIndex
{
  NSAssert(sublayer != nil,
           @"-[%@ %@] Attempt to insert nil sublayer",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd));
  
  NSAssert(![self.sublayers containsObject:sublayer],
           @"-[%@ %@] invoked with a layer it already contains: %@",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           sublayer);
  
  NSAssert(![self isDescendentOfLayer:sublayer],
           @"-[%@ %@] invoked with an ancestor layer: %@",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           sublayer);
  
  [sublayer willMoveToSuperlayer:self];
  
  [sublayer.superlayer removeSublayer:sublayer];
  NSArray * sublayers = [self.sublayers arrayByAddingObject:sublayer];
  self.sublayers = sublayers;
  
  sublayer.superlayer = self;
  
  [self didAddSublayer:sublayer];
  [sublayer didMoveToSuperlayer];
}

- (void)moveSublayerAtIndex:(NSUInteger)currentIndex
                    toIndex:(NSUInteger)destinationIndex
{
  VPLLayer * sublayer = [self.sublayers objectAtIndex:currentIndex];
  
  NSMutableArray * sublayers = [[NSMutableArray alloc] initWithArray:self.sublayers];
  [sublayers removeObjectAtIndex:currentIndex];
  
  [sublayers insertObject:sublayer
                  atIndex:destinationIndex];
  
  self.sublayers = [[NSArray alloc] initWithArray:sublayers];
}

- (void)removeSublayer:(VPLLayer *)sublayer
{
  NSAssert([self.sublayers containsObject:sublayer],
           @"-[%@ %@] invoked with a layer it doesn't contain: %@",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           sublayer);
  
  [sublayer willMoveToSuperlayer:nil];
  [self willRemoveSublayer:sublayer];
  
  NSMutableArray * sublayers = [[NSMutableArray alloc] initWithArray:self.superlayer.sublayers];
  [sublayers removeObject:self];
  self.sublayers = [NSArray arrayWithArray:sublayers];
  
  [self didRemoveSublayer:sublayer];
  
  sublayer.superlayer = nil;
  [sublayer didMoveToSuperlayer];
}

// ----- HIERARCHY NOTIFICATIONS ---------------------------------------------------------------------------------------
#pragma mark Hierarchy Notifications

- (void)didAddSublayer:(VPLLayer *)sublayer
{
  
}

- (void)willRemoveSublayer:(VPLLayer *)sublayer
{
  
}

- (void)didRemoveSublayer:(VPLLayer *)sublayer
{
  
}

- (void)willMoveToSuperlayer:(VPLLayer *)superlayer
{
  
}

- (void)didMoveToSuperlayer
{
  
}

// ===== BACKGROUND COLOR ==============================================================================================
#pragma mark - Background Color

@synthesize backgroundColorRef = _backgroundColorRef;

- (void)setBackgroundColorRef:(CGColorRef)backgroundColorRef
{
  if (backgroundColorRef == _backgroundColorRef) return;
  
  [self willChangeValueForKey:@"backgroundColorRef"];
  
  if (_backgroundColorRef != NULL)
  {
    CGColorRelease(_backgroundColorRef);
    _backgroundColorRef = NULL;
  }
  
  if (backgroundColorRef != NULL)
  {
    _backgroundColorRef = CGColorRetain(backgroundColorRef);
  }
  
  [self didChangeValueForKey:@"backgroundColorRef"];
}

// ===== TEXT ==========================================================================================================
#pragma mark - Text

- (CFAttributedStringRef)attributedTextRef
{
  if (_attributedTextRef == NULL
      && self.text != nil)
  {
    // create default text attributes
    CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica Neue"),
                                          17.0,
                                          NULL);
    
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { font };
    
    CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault,
                                                    (const void**)&keys,
                                                    (const void**)&values,
                                                    1,
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);
    
    // create an attributed string
    CFStringRef stringRef = CFStringFromNSString(self.text);
    _attributedTextRef = CFAttributedStringCreate(NULL,
                                                  stringRef,
                                                  attributes);
    
    CFRelease(font);
    CFRelease(attributes);
  }
  return _attributedTextRef;
}

- (CTFramesetterRef)textFramesetterRef
{
  if (_textFramesetterRef == NULL
      && self.text != nil)
  {
    _textFramesetterRef = CTFramesetterCreateWithAttributedString(self.attributedTextRef);
  }
  
  return _textFramesetterRef;
}

// ===== DRAWING =======================================================================================================
#pragma mark - Drawing

- (void)drawInContext:(CGContextRef)ctx
{
  if (self.backgroundColorRef != NULL)
  {
    CGContextSetFillColorWithColor(ctx, self.backgroundColorRef);
    
    NSLog(@"[%@] drawing in %@",
          self.identifier,
          NSStringFromRect(self.frame));
    
    CGContextFillRect(ctx, self.frame);
  }
  
  if (self.text != nil)
  {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.frame);
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(self.textFramesetterRef,
                                                   CFRangeMake(0, 0),
                                                   path,
                                                   NULL);
    
    CTFrameDraw(frameRef, ctx);
    
    CFRelease(frameRef);
  }
  
  for (VPLLayer * layer in self.sublayers)
  {
    CGContextSaveGState(ctx);
  
    [layer drawInContext:ctx];
    
    CGContextRestoreGState(ctx);
  }
}


@end
