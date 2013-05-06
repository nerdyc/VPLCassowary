#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLCassowaryCL.h"
#import "VPLAssetsLibrary.h"
#import "VPLAsset.h"
#import "VPLAssetRepresentation.h"

NSString * const VPLCassowaryCLDomain = @"VPLCassowaryCL";


@implementation VPLCassowaryCL

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (instancetype)init
{
  NSArray * processArgs = [[NSProcessInfo processInfo] arguments];
  NSArray * commandArgs = [processArgs subarrayWithRange:NSMakeRange(1, [processArgs count]-1)];
  
  return [self initWithArguments:commandArgs];
}

- (instancetype)initWithArguments:(NSArray *)arguments
{
  self = [super init];
  if (self != nil)
  {
    _libraryPath = [arguments objectAtIndex:0];
    _assetName = [arguments objectAtIndex:1];
  }
  return self;
}

// ===== LIBRARY PATH ==================================================================================================
#pragma mark - Library File

@synthesize libraryPath = _libraryPath;

// ===== ASSET NAME ====================================================================================================
#pragma mark - Asset Name

@synthesize assetName = _assetName;

// ===== EXECUTE =======================================================================================================
#pragma mark - Execute

- (BOOL)perform:(NSError * __autoreleasing *)error
{
  // create the asset library
  NSError * localError = nil;
  VPLAssetsLibrary * assetsLibrary = [VPLAssetsLibrary assetsLibraryWithPath:self.libraryPath
                                                                     error:&localError];
  if (assetsLibrary == nil)
  {
    if (error != NULL)
    {
      *error = [NSError errorWithDomain:VPLCassowaryCLDomain
                                   code:VPLCassowaryCLErrorUnableToLoadAssetsLibrary
                               userInfo:@{
                
             NSLocalizedDescriptionKey : NSLocalizedString(@"Unable to load assets library", nil),
                  NSUnderlyingErrorKey : localError
                
                }];
    }
    
    return NO;
  }
  
  // find the asset
  VPLAssetRepresentation * matchingAssetRepresentation = nil;
  for (VPLAsset * asset in assetsLibrary.assets)
  {
    NSUInteger matchingIndex = [asset.representations indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      
      return [((VPLAssetRepresentation *)obj).filename isEqualToString:self.assetName];
      
    }];
    
    if (matchingIndex != NSNotFound)
    {
      matchingAssetRepresentation = [asset.representations objectAtIndex:matchingIndex];
      break;
    }
  }
  
  if (matchingAssetRepresentation == nil)
  {
    if (error != NULL)
    {
      NSString * localizedFormatString = NSLocalizedString(@"Unable to find asset named %@", nil);
      NSString * localizedErrorMessage = [NSString stringWithFormat:localizedFormatString, self.assetName];
      
      *error = [NSError errorWithDomain:VPLCassowaryCLDomain
                                   code:VPLCassowaryCLErrorAssetNameNotFound
                               userInfo:@{
                
             NSLocalizedDescriptionKey : localizedErrorMessage

                }];
    }
    
    return NO;
  }
  
  // draw the asset
  return [matchingAssetRepresentation drawToFile:self.assetName
                                           error:error];
}

@end
