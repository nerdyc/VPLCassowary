#import "VPLCassowaryTypes.h"

extern NSString * const VPLCassowaryCLErrorDomain;

typedef enum _VPLCassowaryCLError
{
  VPLCassowaryCLErrorNone = 0,
  VPLCassowaryCLErrorUnableToLoadAssetsLibrary,
  VPLCassowaryCLErrorAssetNameNotFound,
}
VPLCassowaryCLError;

@interface VPLCassowaryCL : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (instancetype)initWithArguments:(NSArray *)arguments;

// ===== LIBRARY PATH ==================================================================================================
#pragma mark - Library File

@property (nonatomic, strong, readonly) NSString * libraryPath;

// ===== ASSET NAME ====================================================================================================
#pragma mark - Asset Name

@property (nonatomic, strong, readonly) NSString * assetName;

// ===== PERFORM =======================================================================================================
#pragma mark - Perform

- (BOOL)perform:(NSError * __autoreleasing *)error;

@end
