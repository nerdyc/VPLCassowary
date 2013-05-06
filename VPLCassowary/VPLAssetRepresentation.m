#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLAssetRepresentation.h"
#import "VPLAsset.h"
#import "VPLLayer.h"
#import "VPLLayoutConstraint.h"
#import "VPLConstraintSet.h"
#import "VPLConstraint.h"
#import "VPLTableau.h"
#import "VPLLinearExpression.h"

NSString * const VPLAssetRepresentationErrorDomain = @"VPLAssetRepresentation";

@implementation VPLAssetRepresentation

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (instancetype)initWithAsset:(VPLAsset *)asset
                     filename:(NSString *)filename
                         size:(CGSize)size
                    rootLayer:(VPLLayer *)rootLayer
{
  self = [super init];
  if (self != nil)
  {
    _asset = asset;
    _filename = filename;
    _size = size;
    _rootLayer = rootLayer;
  }
  return self;
}

+ (instancetype)assetRepresentationWithDictionary:(NSDictionary *)assetRepresentationDictionary
                                            asset:(VPLAsset *)asset
                                            error:(NSError * __autoreleasing *)error
{
  NSString * filename = [assetRepresentationDictionary objectForKey:@"filename"];
  
  NSArray * sizeArray = [assetRepresentationDictionary objectForKey:@"size"];
  CGSize size = CGSizeZero;
  size.width = [sizeArray[0] floatValue];
  size.height = [sizeArray[1] floatValue];
  
  // root layer
  VPLLayer * rootLayer = nil;
  NSDictionary * layerDictionary = [assetRepresentationDictionary objectForKey:@"rootLayer"];
  if (layerDictionary != nil)
  {
    rootLayer = [VPLLayer layerWithDictionary:layerDictionary
                                       error:error];
    if (rootLayer == nil)
    {
      return nil;
    }
  }
  
  return [[self alloc] initWithAsset:asset
                            filename:filename
                                size:size
                           rootLayer:rootLayer];
}

// ===== FILENAME ======================================================================================================
#pragma mark - Filename

@synthesize filename = _filename;

// ===== ROOT LAYER ====================================================================================================
#pragma mark - Root Layer

@synthesize rootLayer = _rootLayer;

// ===== LAYOUT ========================================================================================================
#pragma mark - Layout

- (VPLConstraintSet *)buildConstraints
{
  VPLConstraintSet * constraintSet = [[VPLConstraintSet alloc] init];
  
  
  
  // add constraints for the root layer's dimensions
  [constraintSet addConstraint:[VPLConstraint constraintWithVariable:[NSString stringWithFormat:@"%@.x", self.rootLayer.identifier]
                                                          relatedBy:VPLConstraintRelationEqual
                                                         toVariable:nil
                                                         multiplier:0
                                                           constant:0]];
  
  [constraintSet addConstraint:[VPLConstraint constraintWithVariable:[NSString stringWithFormat:@"%@.y", self.rootLayer.identifier]
                                                          relatedBy:VPLConstraintRelationEqual
                                                         toVariable:nil
                                                         multiplier:0
                                                           constant:0]];
  
  if (self.size.width > 0)
  {
    [constraintSet addConstraint:[VPLConstraint constraintWithVariable:[NSString stringWithFormat:@"%@.width", self.rootLayer.identifier]
                                                            relatedBy:VPLConstraintRelationEqual
                                                           toVariable:nil
                                                           multiplier:0
                                                             constant:self.size.width]];
  }
  
  if (self.size.height > 0)
  {
    [constraintSet addConstraint:[VPLConstraint constraintWithVariable:[NSString stringWithFormat:@"%@.height", self.rootLayer.identifier]
                                                            relatedBy:VPLConstraintRelationEqual
                                                           toVariable:nil
                                                           multiplier:0
                                                             constant:self.size.height]];
  }
  
  // construct the constraint set...
  NSMutableArray * stack = [[NSMutableArray alloc] initWithObjects:self.rootLayer, nil];
  while ([stack count] > 0)
  {
    VPLLayer * topLayer = [stack lastObject];
    [stack removeLastObject];
    
    [topLayer updateConstraints];
    
    // process constraints
    for (VPLLayoutConstraint * layoutConstraint in topLayer.layoutConstraints)
    {
      [constraintSet addConstraint:layoutConstraint.constraint];
    }
    
    [stack addObjectsFromArray:topLayer.sublayers];
  }
  
  return constraintSet;
}

- (void)performLayout
{
  VPLConstraintSet * constraintSet = [self buildConstraints];
  
  // ...and then apply
  NSMutableArray * stack = [[NSMutableArray alloc] initWithObjects:self.rootLayer, nil];
  while ([stack count] > 0)
  {
    VPLLayer * topLayer = [stack lastObject];
    [stack removeLastObject];
    
    CGRect frame = CGRectZero;
    
    // apply all variables for this layer
    NSString * prefix = [topLayer.identifier stringByAppendingString:@"."];
    
    for (NSString * variableName in constraintSet.tableau.rowVariableNames)
    {
      
      if ([variableName hasPrefix:prefix])
      {
        NSString * attributeName = [variableName substringFromIndex:prefix.length];
        CGFloat value = [[constraintSet.tableau expressionForRow:variableName] constantValue];
        NSLog(@"%@ = %f", variableName, value);
        if ([attributeName isEqualToString:@"x"])
        {
          frame.origin.x = value;
        }
        else if ([attributeName isEqualToString:@"y"])
        {
          frame.origin.y = value;
        }
        else if ([attributeName isEqualToString:@"width"])
        {
          frame.size.width = value;
        }
        else if ([attributeName isEqualToString:@"height"])
        {
          frame.size.height = value;
        }
      }
    }
    
    topLayer.frame = frame;
    
    [stack addObjectsFromArray:topLayer.sublayers];
  }
}

// ===== DRAWING =======================================================================================================
#pragma mark - Drawing

// From Programming with Quartz p353
#define BEST_BYTE_ALIGNMENT 16
#define COMPUTE_BEST_BYTES_PER_ROW(bpr) ( ((bpr) + (BEST_BYTE_ALIGNMENT - 1)) & ~(BEST_BYTE_ALIGNMENT - 1) )

static CGContextRef
CreateRGBBitmapContext(size_t width, size_t height)
{
  size_t bytesPerRow = width * 4;
  bytesPerRow = COMPUTE_BEST_BYTES_PER_ROW(bytesPerRow);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
  
  // allocate a buffer to manage the bytes
  CGContextRef context = CGBitmapContextCreateWithData(NULL,
                                                       width,
                                                       height,
                                                       8,
                                                       bytesPerRow,
                                                       colorSpace,
                                                       bitmapInfo,
                                                       NULL,
                                                       NULL);
  
  CGColorSpaceRelease(colorSpace);
  
  return context;
}

static NSError *
CGImageWriteToFile(CGImageRef image, NSString * filename)
{
  NSURL * url = [NSURL fileURLWithPath:[filename stringByExpandingTildeInPath]];
  
  CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url,
                                                                           kUTTypePNG,
                                                                           1,
                                                                           NULL);
  if (imageDestination == NULL)
  {
    NSString * localizedErrorFormat = NSLocalizedString(@"Unable to write to file (%@)", nil);
    NSString * localizedErrorMsg = [NSString stringWithFormat:localizedErrorFormat, filename];
    
    return [NSError errorWithDomain:VPLAssetRepresentationErrorDomain
                               code:VPLAssetRepresentationErrorWriteFailed
                           userInfo:@{
            
         NSLocalizedDescriptionKey : localizedErrorMsg
            
            }];
  }
  
  // add the image
  CGImageDestinationAddImage(imageDestination, image, NULL);
  
  // write to disk
  CGImageDestinationFinalize(imageDestination);
  
  // cleanup
  CFRelease(imageDestination);
  
  return nil;
}

- (CGImageRef)drawCGImage
{
  [self performLayout];
  
  // create a bitmap context
  CGContextRef ctx = CreateRGBBitmapContext(self.rootLayer.frame.size.width,
                                            self.rootLayer.frame.size.height);
  
  // draw in the context
  [self.rootLayer drawInContext:ctx];
  
  // create an image from the context
  CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
  
  CGContextRelease(ctx);
  
  return imageRef;
}

- (BOOL)drawToFile:(NSString *)filename
             error:(NSError * __autoreleasing *)error
{
  CGImageRef image = [self drawCGImage];
  
  NSError * writeError = CGImageWriteToFile(image, filename);
  if (writeError != nil && error != NULL)
  {
    *error = writeError;
  }
  
  CGImageRelease(image);
  
  return writeError == nil;
}

@end
