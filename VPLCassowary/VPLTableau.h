#import "VPLCassowaryTypes.h"

@class VPLLinearExpression;

/**
 * A tableau is a collection of equations in "basic feasible solved form". This means that each equation looks like
 * this:
 *
 *     bv0 = constantValue + coeff1*pv1 + ... + coeffN*pvN
 *
 * and that `bv0` doesn't appear in the right side of the equation **or any other equation** in the tableau.
 *
 * As a result, each row in the tableau maps a variable to a linear expression that defines that variable's value. The
 * variable on the left hand side of each row (`bv0` in the example above) is considered a _basic variable_ because its
 * value is determined completely by the variables in the right hand side, and is not affected by other rows.
 *
 * Columns in the tableau define the _parametric variables_, so called because they are the paramters to the system that
 * define the values of all the basic variables.
 *
 * We end up with a matrix of `M` rows representing basic variables, and `N` columns of parametric variables.
 */
@interface VPLTableau : NSObject

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)initWithEquations:(NSDictionary *)equations;

+ (instancetype)tableau;
+ (instancetype)tableauWithEquations:(NSDictionary *)equations;

// ===== EQUATIONS =====================================================================================================
#pragma mark - Equations

@property (nonatomic, strong, readonly) NSDictionary * equations;

@property (nonatomic, strong, readonly) NSArray * rowVariableNames;
@property (nonatomic, strong, readonly) NSArray * columnVariableNames;

- (VPLLinearExpression *)expressionForRow:(NSString *)rowVariableName;

- (VPLLinearExpression *)expressionByReplacingRowVariablesInExpression:(VPLLinearExpression *)expression;

// ===== ADDING ROWS ===================================================================================================
#pragma mark - Adding Rows

- (VPLTableau *)tableauBySettingExpression:(VPLLinearExpression *)expression
                           forRowVariable:(NSString *)variableName;

- (VPLTableau *)tableauBySubstitutingExpression:(VPLLinearExpression *)expression
                             forColumnVariable:(NSString *)variableName;

// ===== REMOVING ROWS =================================================================================================
#pragma mark - Removing Rows

- (VPLTableau *)tableauByRemovingExpressionForRow:(NSString *)rowVariable;

// ===== REMOVING COLUMNS ==============================================================================================
#pragma mark - Removing Columns

- (VPLTableau *)tableauByRemovingColumnVariable:(NSString *)columnVariable;

// ===== OPTIMIZATION ==================================================================================================
#pragma mark - Optimization

- (VPLTableau *)tableauByMinimizingExpression:(VPLLinearExpression *)linearExpression
                       objectiveVariableName:(NSString *)objectiveVar;

// ===== PIVOTING ======================================================================================================
#pragma mark - Pivoting

- (VPLTableau *)tableauByPivotingRowVariable:(NSString *)rowVariable
                             columnVariable:(NSString *)columnVariable;

@end
