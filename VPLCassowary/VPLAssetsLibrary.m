#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLAssetsLibrary.h"
#import "VPLCassowaryTypes.h"
#import "VPLAsset.h"

NSString * const VPLAssetsLibraryErrorDomain = @"com.vulpinelabs.VPLAssetLibrary";

NSString * const VPLAssetsLibraryTypeKey = @"assets_library";
NSString * const VPLAssetsLibraryAssetsKey = @"assets";

@implementation VPLAssetsLibrary

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (instancetype)initWithAssets:(NSArray *)assets
{
  self = [super init];
  if (self != nil)
  {
    _assets = assets;
  }
  return self;
}

+ (instancetype)assetsLibraryWithPath:(NSString *)libraryPath
                                error:(NSError * __autoreleasing *)error
{
  // load the library file
  NSData * libraryData = [NSData dataWithContentsOfFile:libraryPath
                                                options:0
                                                  error:error];
  if (libraryData == nil)
  {
    return nil;
  }
  
  id jsonObj = [NSJSONSerialization JSONObjectWithData:libraryData
                                               options:0
                                                 error:error];
  if (jsonObj != nil)
  {
    if ([jsonObj isKindOfClass:[NSDictionary class]])
    {
      return [self assetsLibraryWithDictionary:jsonObj
                                         error:error];
    }
    else
    {
      if (error != NULL)
      {
        NSString * localizedString = NSLocalizedString(@"Invalid asset library data", nil);
        *error = [NSError errorWithDomain:VPLAssetsLibraryErrorDomain
                                     code:VPLAssetsLibraryErrorInvalidContents
                                 userInfo:@{ NSLocalizedDescriptionKey : localizedString }];
      }
    }
  }
  return nil;
}

+ (instancetype)assetsLibraryWithDictionary:(NSDictionary *)libraryDictionary
                                      error:(NSError * __autoreleasing *)error
{
  NSArray * assetsData = [libraryDictionary objectForKey:VPLAssetsLibraryAssetsKey];
  
  NSMutableArray * assets = [[NSMutableArray alloc] initWithCapacity:[assetsData count]];
  for (NSDictionary * assetDictionary in assetsData)
  {
    VPLAsset * asset = [VPLAsset assetWithDictionary:assetDictionary
                                             error:error];
    if (asset != nil)
    {
      [assets addObject:asset];
    }
    else
    {
      return nil;
    }
  }
  
  return [[self alloc] initWithAssets:assets];
}

// ===== ASSETS ========================================================================================================
#pragma mark - Assets

@synthesize assets = _assets;

@end
