#import <Foundation/Foundation.h>

@class VPLLayer;

@interface VPLAsset : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

+ (instancetype)assetWithDictionary:(NSDictionary *)assetDictionary
                              error:(NSError * __autoreleasing *)error;

// ===== TITLE =========================================================================================================
#pragma mark - Title

@property (nonatomic, strong, readonly) NSString * title;

// ===== REPRESENTATIONS ===============================================================================================
#pragma mark - Representations

@property (nonatomic, strong, readonly) NSArray * representations;

@end
