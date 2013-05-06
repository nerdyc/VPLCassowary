#import <Foundation/Foundation.h>

@interface VPLLayer : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

+ (instancetype)layerWithDictionary:(NSDictionary *)layerDictionary
                              error:(NSError * __autoreleasing *)error;

// ===== IDENTIFIER ====================================================================================================
#pragma mark - Identifier

@property (nonatomic, strong, readonly) NSString * identifier;

// ===== GEOMETRY ======================================================================================================
#pragma mark - Geometry

@property (nonatomic, assign, readwrite) CGRect frame;

@property (nonatomic, assign, readonly) CGSize intrinsicContentSize;

// ===== CONSTRAINTS ===================================================================================================
#pragma mark - Constraints

@property (nonatomic, strong, readonly) NSArray * layoutConstraints;

- (void)updateConstraints;

// ===== LAYER HIERARCHY ===============================================================================================
#pragma mark - Layer Hierarchy

@property (nonatomic, weak,   readonly) VPLLayer * superlayer;
@property (nonatomic, strong, readonly) NSArray * sublayers;

- (void)addSublayer:(VPLLayer *)sublayer;

- (void)insertSublayer:(VPLLayer *)sublayer
               atIndex:(NSUInteger)insertionIndex;

- (void)removeFromSuperlayer;

// ===== TEXT ==========================================================================================================
#pragma mark - Text

@property (nonatomic, strong, readwrite) NSString * text;

// ===== BACKGROUND COLOR ==============================================================================================
#pragma mark - Background Color

@property (nonatomic, assign, readwrite) CGColorRef backgroundColorRef;

// ===== DRAWING =======================================================================================================
#pragma mark - Drawing

- (void)drawInContext:(CGContextRef)ctx;

@end
