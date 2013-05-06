#import <Foundation/Foundation.h>

extern NSString * const VPLAssetsLibraryErrorDomain;

typedef
enum _VPLAssetsLibraryError
{
  VPLAssetsLibraryErrorNone,
  VPLAssetsLibraryErrorInvalidContents,
}
VPLAssetsLibaryError;

@interface VPLAssetsLibrary : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

+ (instancetype)assetsLibraryWithPath:(NSString *)libraryPath
                                error:(NSError * __autoreleasing *)error;

+ (instancetype)assetsLibraryWithDictionary:(NSDictionary *)libraryDictionary
                                      error:(NSError * __autoreleasing *)error;

// ===== ASSETS ========================================================================================================
#pragma mark - Assets

@property (nonatomic, strong, readonly) NSArray * assets;

@end
