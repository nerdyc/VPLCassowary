#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLAsset.h"
#import "VPLAssetRepresentation.h"
#import "VPLLayer.h"

NSString * const VPLAssetTypeKey = @"Asset";
NSString * const VPLAssetTitleKey = @"title";

@interface VPLAsset ()

@property (nonatomic, strong, readonly) NSArray * representationData;

@end

@implementation VPLAsset

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)initWithTitle:(NSString *)title
 representationData:(NSArray *)representationData
{
  self = [super init];
  if (self != nil)
  {
    _title = title;
    _representationData = representationData;
  }
  return self;
}

+ (VPLAsset *)assetWithDictionary:(NSDictionary *)assetDictionary
                           error:(NSError * __autoreleasing *)error
{
  NSAssert([[assetDictionary objectForKey:@"type"] isEqualToString:VPLAssetTypeKey],
           @"Expected a '%@' dictionary. Received: %@",
           VPLAssetTypeKey,
           assetDictionary);
  
  // title
  NSString * assetTitle = [assetDictionary objectForKey:VPLAssetTitleKey];
  
  // representations
  NSArray * representationDictionaries = [assetDictionary objectForKey:@"representations"];
  
  return [[self alloc] initWithTitle:assetTitle
                  representationData:representationDictionaries];
}

// ===== REPRESENTATIONS ===============================================================================================
#pragma mark - Representations

@synthesize representations = _representations;

- (NSArray *)representations
{
  if (_representations == nil)
  {
    NSMutableArray * representations = [[NSMutableArray alloc] initWithCapacity:[self.representationData count]];
    for (NSDictionary * representationDictionary in self.representationData)
    {
      NSError * error = nil;
      VPLAssetRepresentation * representation = [VPLAssetRepresentation assetRepresentationWithDictionary:representationDictionary
                                                                                                  asset:self
                                                                                                  error:&error];
      if (representation != nil)
      {
        [representations addObject:representation];
      }
      else
      {
        NSLog(@"Error constructing representation: %@", [error localizedDescription]);
      }
    }
    
    _representations = representations;
  }
  return _representations;
}

@end
