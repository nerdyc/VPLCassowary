#import "VPLCassowaryTypes.h"

// ===== ERRORS ========================================================================================================

extern NSString * const VPLLinearExpressionErrorDomain;

typedef enum _VPLLinearExpressionErrorCode {

  VPLLinearExpressionSuccess = 0,
  VPLLinearExpressionParseError = 1
  
} VPLLinearExpressionErrorCode;

// ===== CONSTANTS =====================================================================================================

extern NSString * const VPLLinearExpressionDummyVariablePrefix;
extern NSString * const VPLLinearExpressionSlackVariablePrefix;
extern NSString * const VPLLinearExpressionObjectiveVariablePrefix;

BOOL VPLLinearExpressionVariableIsRestricted(NSString * variableName);
BOOL VPLLinearExpressionVariableIsUnrestricted(NSString * variableName);

BOOL VPLLinearExpressionVariableIsExternal(NSString * variableName);
BOOL VPLLinearExpressionVariableIsDummy(NSString * variableName);
BOOL VPLLinearExpressionVariableIsObjective(NSString * variableName);
BOOL VPLLinearExpressionVariableIsSlack(NSString * variableName);

CGFloat CGFloatFromObjectValue(id obj);

#define VPLSortVariables(array) [(array) sortedArrayUsingSelector:@selector(compare:)]
#define VPLSortedVariables(...) VPLSortVariables(([NSArray arrayWithObjects:__VA_ARGS__, nil]))

/**!
 * Describes a linear expression in standard form:
 *
 *     constantValue + coeff0*variable0 + ... + coeffN*variableN = 0
 *
 * An expression will never have duplicate terms of the same variable, they are always combined. However, variables may
 * have a zero coefficient, which may be useful to mark an expression with a dummy variable.
 *
 * Expressions with no variables are _constant_; those with variables are considered _parametric_.
 */
@interface VPLLinearExpression : NSObject <NSCopying> {}

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

+ (instancetype)expressionWithConstantValue:(CGFloat)constantValue;

+ (instancetype)expressionWithConstantValue:(CGFloat)constantValue
                              variableNames:(NSArray *)variableNames
                       variableCoefficients:(NSArray *)variableCoefficients;

+ (instancetype)expressionFromString:(NSString *)expressionString
                               error:(NSError * __autoreleasing *)error;

// ===== CONSTANT VALUE ================================================================================================
#pragma mark - Constant Value

@property (nonatomic, assign, readonly) CGFloat constantValue;
- (BOOL)isConstant;

// ===== VARIABLES =====================================================================================================
#pragma mark - Variables

@property (nonatomic, strong, readonly) NSDictionary * variableTerms;
- (BOOL)isParametric;

- (CGFloat)coefficientForVariable:(NSString *)variableName;
- (BOOL)containsVariable:(NSString *)variableName;

- (NSArray *)unrestrictedVariableNames;
- (NSArray *)variableNamesPassingTest:(BOOL(^)(NSString * variableName, NSNumber * coefficient, BOOL * stop))block;

// ===== OPERATIONS ====================================================================================================
#pragma mark - Operations

- (VPLLinearExpression *)expressionByNegatingExpression;

- (VPLLinearExpression *)expressionByMultiplying:(CGFloat)multiplier;

- (VPLLinearExpression *)expressionBySubstitutingExpression:(VPLLinearExpression *)expression
                                               forVariable:(NSString *)variableName;

/**
 * Returns a new expression by solving for the named variable. Expressions usually represent an equation like:
 *
 *    0 = 10 - a + b
 *
 * This method solves for one of the variables in this expression, such as 'b':
 *
 *    b = a - 10
 *
 * This method returns the right hand side of the above expression. An exception will be thrown if the variable doesn't
 * appear in the expression.
 */
- (VPLLinearExpression *)expressionBySolvingForVariable:(NSString *)variableName;

/**
 * Assuming that the current expression represents the right hand side of the following equation:
 *
 *    currentSubject = constant + c1*v1 + ... + cI*updatedSubject + ... + cN*vN
 *
 * this method solves for `updatedSubject` by introducing `currentSubject` into the returned expression and removing
 * `updatedSubject`. Thus, the returned expression will represent the right hand of the following expression:
 *
 *    updatedSubject = (1/cI)*currentSubject - (constant/cI) - (c1/cI)v1 + ... + (cN / cI)vN
 *
 */
- (VPLLinearExpression *)expressionByChangingSubjectFromVariable:(NSString *)currentSubject
                                                     toVariable:(NSString *)updatedSubject;

- (VPLLinearExpression *)expressionByRemovingVariableTerm:(NSString *)variableName;

// ===== EQUALITY ======================================================================================================
#pragma mark - Equality

- (BOOL)isEqualToExpression:(VPLLinearExpression *)otherExpression;

@end
