#import "VPLCassowaryTypes.h"
@class VPLLinearExpression;

typedef enum _VPLConstraintRelation {
  
  VPLConstraintRelationLessThanOrEqual = -1,
  VPLConstraintRelationEqual = 0,
  VPLConstraintRelationGreaterThanOrEqual = 1
  
} VPLConstraintRelation;

/**
 * Expresses a constraint relating two variables with each other in the form of:
 *
 *    v = m*x + b
 *
 * In addition to equality constraints, inequalities such as <= and >= can also be declared:
 *
 *    v <= m*x + b
 *    v >= m*x + b
 *
 */
@interface VPLConstraint : NSObject

// ===== INITIALIZATION ================================================================================================

+ (instancetype)constraintWithVariable:(NSString *)variableName
                             relatedBy:(VPLConstraintRelation)relation
                            toVariable:(NSString *)relatedVariableName
                            multiplier:(CGFloat)multiplier
                              constant:(CGFloat)constant;

// ===== VARIABLE ======================================================================================================

@property (nonatomic, strong, readonly) NSString * variableName;

// ===== RELATION ======================================================================================================

@property (nonatomic, assign, readonly) VPLConstraintRelation relation;

// ===== RELATED VARIABLE ==============================================================================================

@property (nonatomic, strong, readonly) NSString * relatedVariableName;
@property (nonatomic, assign, readonly) CGFloat multiplier;
@property (nonatomic, assign, readonly) CGFloat constant;

// ===== EXPRESSION ====================================================================================================

@property (nonatomic, strong, readonly) VPLLinearExpression * expression;
@property (nonatomic, strong, readonly) NSString * markerVariableName;

@end
