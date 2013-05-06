#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLConstraint.h"
#import "VPLLinearExpression.h"

static int64_t
VPLConstraintGenerateMarkerNumber()
{
  static int64_t markerCount = 0;
  return OSAtomicIncrement64Barrier(&markerCount);
}

@implementation VPLConstraint

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)initWithVariable:(NSString *)variableName
             relatedBy:(VPLConstraintRelation)relation
            toVariable:(NSString *)relatedVariableName
            multiplier:(CGFloat)multiplier
              constant:(CGFloat)constant
{
  self = [super init];
  if (self != nil)
  {
    _variableName = variableName;
    _relation = relation;
    _relatedVariableName = relatedVariableName;
    _multiplier = multiplier;
    _constant = constant;
    
    // Convert inequalities to an equality, and produce a 'marker' variable to help identify the constraint's effect in
    // the tableau. Inequalities need a slack variable, which can act as a marker as well. But equalities will have a
    // 'dummy' marker that has no effect except to track the constraint when removing a constraint.
    
    NSUInteger markerId = VPLConstraintGenerateMarkerNumber();
    NSString * markerVariablePrefix = nil;
    CGFloat markerVariableCoefficient = 1.0;
    
    if (relation == VPLConstraintRelationEqual)
    {
      // x = 50
      // x + d1 = 50
      markerVariablePrefix = VPLLinearExpressionDummyVariablePrefix;
    }
    else if (relation == VPLConstraintRelationGreaterThanOrEqual)
    {
      // x >= 50
      // x - s1 = 50
      markerVariablePrefix = VPLLinearExpressionSlackVariablePrefix;
      markerVariableCoefficient = -1.0;
    }
    else if (relation == VPLConstraintRelationLessThanOrEqual)
    {
      // x <= 50
      // x + s1 = 50
      markerVariablePrefix = VPLLinearExpressionSlackVariablePrefix;
    }
    else
    {
      NSString * className = NSStringFromClass([self class]);
      
      self = nil;
      [NSException raise:NSInternalInconsistencyException
                  format:@"Attempt to initialize %@ with invalid relation (%li)",
                         className,
                         (long)relation];
    }
    
    _markerVariableName = [NSString stringWithFormat:@"%@%@%lu",
                                                     markerVariablePrefix,
                                                     variableName,
                                                     (unsigned long)markerId];
    
    // construct an expression:
    //
    // variableName + (markerVariableCoeff * markerVariable) = constant + (multiplier * relatedVariableName)
    // 0 =  constant + (multiplier * relatedVariableName) - variableName - (markerVariableCoeff * markerVariable)
    //
    // if constant is negative, negate it
    
    NSArray * variableNames;
    NSArray * variableCoefficients;
    if (relatedVariableName != nil && multiplier != 0.0)
    {
      variableNames = @[ relatedVariableName, _markerVariableName, variableName ];
      variableCoefficients = @[ @(multiplier), @(-markerVariableCoefficient), @(-1) ];
    }
    else
    {
      variableNames = @[ _markerVariableName, variableName ];
      variableCoefficients = @[ @(-markerVariableCoefficient), @(-1) ];
    }
    
    VPLLinearExpression * expr = [VPLLinearExpression expressionWithConstantValue:constant
                                                                  variableNames:variableNames
                                                           variableCoefficients:variableCoefficients];
    if (expr.constantValue < 0.0)
    {
      expr = [expr expressionByNegatingExpression];
    }
    
    _expression = expr;
  }
  return self;
}

+ (instancetype)constraintWithVariable:(NSString *)variableName
                             relatedBy:(VPLConstraintRelation)relation
                            toVariable:(NSString *)relatedVariableName
                            multiplier:(CGFloat)multiplier
                              constant:(CGFloat)constant
{
  return [[self alloc] initWithVariable:variableName
                              relatedBy:relation
                             toVariable:relatedVariableName
                             multiplier:multiplier
                               constant:constant];
}

@end
