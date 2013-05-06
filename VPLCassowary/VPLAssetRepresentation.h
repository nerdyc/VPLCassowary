#import <Foundation/Foundation.h>

@class VPLAsset;
@class VPLLayer;

extern NSString * const VPLAssetRepresentationErrorDomain;

typedef enum _VPLAssetRepresentationError {
  
  VPLAssetRepresentationErrorNone = 0,
  VPLAssetRepresentationErrorWriteFailed
  
} VPLAssetRepresentationError;

@interface VPLAssetRepresentation : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

+ (instancetype)assetRepresentationWithDictionary:(NSDictionary *)assetRepresentationDictionary
                                            asset:(VPLAsset *)asset
                                            error:(NSError * __autoreleasing *)error;

// ===== ASSET =========================================================================================================
#pragma mark - Asset

@property (nonatomic, weak, readonly) VPLAsset * asset;

// ===== FILENAME ======================================================================================================
#pragma mark - Filename

@property (nonatomic, strong, readonly) NSString * filename;

// ===== SIZE ==========================================================================================================
#pragma mark - Size

@property (nonatomic, assign, readonly) CGSize size;

// ===== ROOT LAYER ====================================================================================================
#pragma mark - Root Layer

@property (nonatomic, strong, readonly) VPLLayer * rootLayer;

// ===== DRAWING =======================================================================================================
#pragma mark - Drawing

- (CGImageRef)drawCGImage;

- (BOOL)drawToFile:(NSString *)filename
             error:(NSError * __autoreleasing *)error;

@end
