#import "VPLCassowaryTypes.h"

@class VPLConstraint;

@interface VPLLayoutConstraint : NSObject

// ===== INITIALIZATION ================================================================================================

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)initWithSubject:(NSString *)subject
            attribute:(NSString *)attribute
         relationship:(NSString *)relationship
        relatedObject:(NSString *)relatedObject
     relatedAttribute:(NSString *)relatedAttribute
           multiplier:(CGFloat)relatedAttributeMultiplier
             constant:(CGFloat)relatedAttributeConstant;

// ===== SUBJECT =======================================================================================================

@property (nonatomic, strong, readonly) NSString * subject;
@property (nonatomic, strong, readonly) NSString * attribute;

// ===== RELATIONSHIP ==================================================================================================

@property (nonatomic, strong, readonly) NSString * relationship;

// ===== RELATED OBJECT ================================================================================================

@property (nonatomic, strong, readonly) NSString * relatedObject;
@property (nonatomic, strong, readonly) NSString * relatedObjectAttribute;

@property (nonatomic, assign, readonly) CGFloat relatedObjectAttributeMultiplier;
@property (nonatomic, assign, readonly) CGFloat relatedObjectAttributeOffset;

// ===== CONSTRAINT ====================================================================================================

@property (nonatomic, strong, readonly) VPLConstraint * constraint;

@end
