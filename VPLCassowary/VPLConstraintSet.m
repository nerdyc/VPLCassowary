#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLConstraintSet.h"
#import "VPLConstraint.h"
#import "VPLLinearExpression.h"
#import "VPLTableau.h"

static int64_t
VPLConstraintSetGenerateVariableNumber()
{
  static int64_t variableCount = 0;
  return OSAtomicIncrement64Barrier(&variableCount);
}

@interface VPLConstraintSet ()

@property (nonatomic, strong, readonly) NSMutableArray * constraints;

@end

@implementation VPLConstraintSet

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)init
{
  self = [super init];
  if (self != nil)
  {
    _tableau = [[VPLTableau alloc] init];
    _constraints = [[NSMutableArray alloc] init];
  }
  return self;
}

// ===== CONSTRAINTS ===================================================================================================
#pragma mark - Constraints

- (BOOL)containsConstraint:(VPLConstraint *)constraint
{
  return [self.constraints containsObject:constraint];
}

// ===== ADD CONSTRAINTS ===============================================================================================
#pragma mark - Add Constraints

/**
 * When adding a constraint, we first search the expression for a basic variable that can be added to the tableau
 * directly. This method returns the name of the variable that should be used to add the expression.
 *
 * If no variable can be found, then nil is returned, and the expression must be added using an artificial variable.
 */
- (NSString *)selectBasicVariableFromBasicExpression:(VPLLinearExpression *)expression
{
  // If there is an unrestricted variable in the equation, make that the basic variable. However, a new unrestricted
  // variable can be inserted into the tableau directly, so we prefer unknown variables first.
  NSArray * expressionVariableNames = expression.variableTerms.allKeys;
  NSArray * columnVariableNames = self.tableau.columnVariableNames;
  
  NSString * unrestrictedVariableName = nil;
  for (NSString * variableName in expressionVariableNames)
  {
    if (VPLLinearExpressionVariableIsUnrestricted(variableName))
    {
      if (![columnVariableNames containsObject:variableName])
      {
        // unrestricted, unknown variable
        return variableName;
      }
      else if (unrestrictedVariableName == nil)
      {
        // unrestricted, but known. Keep searching for a better match.
        unrestrictedVariableName = variableName;
      }
    }
  }
  
  if (unrestrictedVariableName != nil)
  {
    // there was an unrestricted variable, but we'll have to perform a substitution
    return unrestrictedVariableName;
  }
  
  // No unrestricted variables, but if there is an unknown restricted variable with a negative coefficient we can use
  // that.
  for (NSString * variableName in expressionVariableNames)
  {
    CGFloat coeff = [expression coefficientForVariable:variableName];
    if (coeff < 0.0
        && !VPLLinearExpressionVariableIsDummy(variableName)
        && ![columnVariableNames containsObject:variableName])
    {
      return variableName;
    }
  }
  
  // all restricted variables have positive coefficients, or are dummy variables. In the special case where the
  // expression contains only dummy variables, then pick the one that is not in the tableau to enter the basis.
  NSString * newDummyVariable = nil;
  for (NSString * variableName in expressionVariableNames)
  {
    if (VPLLinearExpressionVariableIsDummy(variableName))
    {
      if (![columnVariableNames containsObject:variableName])
      {
        newDummyVariable = variableName;
      }
    }
    else
    {
      // the expression contained non-dummy variables
      return nil;
    }
  }
  
  return newDummyVariable;
}

- (void)addConstraint:(VPLConstraint *)constraint
{
  NSAssert(![self containsConstraint:constraint],
           @"Attempt to add constraint that already exists: %@",
           constraint);
  
  // The constraint's expression is in the form 0 = c - e, with c gauranteed to be positive as required by the cassowary
  // algorithm
  VPLLinearExpression * constraintExpr = constraint.expression;
  NSAssert(constraintExpr.constantValue >= 0.0,
           @"[%@ %@] constraint expressions are expected to have positive constants!",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd));
  
  // replace all basic variables in the expression with their expressions in the tableau
  VPLLinearExpression * basicExpression =
    [self.tableau expressionByReplacingRowVariablesInExpression:constraintExpr];
  
  // all basic variables have been removed from the expression, so the only variables left are parametric, or new
  // variables.
  
  // If we find a basic variable in the expression, we can add it directly to the tableau
  NSString * basicVariable = [self selectBasicVariableFromBasicExpression:basicExpression];
  if (basicVariable != nil)
  {
    VPLLinearExpression * rowExpression = [basicExpression expressionBySolvingForVariable:basicVariable];
    
    VPLTableau * tableau = self.tableau;
    if ([tableau.columnVariableNames containsObject:basicVariable])
    {
      // substitute for the basic variable
      tableau = [tableau tableauBySubstitutingExpression:rowExpression
                                       forColumnVariable:basicVariable];
    }
    
    _tableau = [tableau tableauBySettingExpression:rowExpression
                                    forRowVariable:basicVariable];
  }
  else
  {
    // create an artifical variable @az, and add a row @az = expr
    
    int64_t artificialVariableNumber = VPLConstraintSetGenerateVariableNumber();
    NSString * slackVariableName = [NSString stringWithFormat:@"%@AZ%lli",
                                                              VPLLinearExpressionSlackVariablePrefix,
                                                              artificialVariableNumber];

    NSString * objectiveVariableName = [NSString stringWithFormat:@"%@AZ%lli",
                                                                  VPLLinearExpressionObjectiveVariablePrefix,
                                                                  artificialVariableNumber];

    VPLTableau * artificialTableau = [self.tableau tableauBySettingExpression:basicExpression
                                                              forRowVariable:slackVariableName];
    
    // Minimize expr.
    VPLTableau * minimizedTableau = [artificialTableau tableauByMinimizingExpression:basicExpression
                                                              objectiveVariableName:objectiveVariableName];
    
    VPLLinearExpression * objExpr = [minimizedTableau expressionForRow:objectiveVariableName];
    CGFloat minimum = objExpr.constantValue;
    
    if (minimum != 0.0)
    {
      // if the minimum is not 0, the constraints are unsatisfiable
      [NSException raise:@"VPLConstraintSetUnsatisfiableConstraint"
                  format:@"Unable to satisy constraint %@",
                         constraint];
    }
    
    VPLLinearExpression * absRow = [minimizedTableau expressionForRow:slackVariableName];
    if (absRow == nil)
    {
      // Artificial parameter is parametric. Simply remove the column for it
      minimizedTableau = [minimizedTableau tableauByRemovingColumnVariable:slackVariableName];
      minimizedTableau = [minimizedTableau tableauByRemovingExpressionForRow:objectiveVariableName];
      
      _tableau = minimizedTableau;
    }
    else
    {
      // Artificial variable is basic (@az = 0 + ...). It must have a 0 constant, otherwise we wouldn't have been
      // able to get a minimum of 0.
      //
      // If it is 
      if ([absRow isConstant])
      {
        // it's constant (@az = 0), so we can simply remove the row
        minimizedTableau = [minimizedTableau tableauByRemovingExpressionForRow:slackVariableName];
        minimizedTableau = [minimizedTableau tableauByRemovingExpressionForRow:objectiveVariableName];
        _tableau = minimizedTableau;
      }
      else
      {
        // Artificial variable is non-constant (@az = 0 + bx + ...). We can pivot and turn @az into a column, which
        // can then be removed.
        NSString * entryVar = nil;
        for (NSString * variableName in absRow.variableTerms.allKeys)
        {
          if (VPLLinearExpressionVariableIsSlack(variableName))
          {
            entryVar = variableName;
            break;
          }
            
        }
        
        NSAssert(entryVar != nil,
                 @"Expected to be able to find one slack variable in expression: %@",
                 absRow);
        
        
        minimizedTableau = [minimizedTableau tableauByPivotingRowVariable:slackVariableName
                                                           columnVariable:entryVar];
        
        // remove column
        NSAssert([minimizedTableau expressionForRow:slackVariableName] == nil,
                 @"Expected artificial variable %@ to be parametric",
                 slackVariableName);
        
        minimizedTableau = [minimizedTableau tableauByRemovingColumnVariable:slackVariableName];
        minimizedTableau = [minimizedTableau tableauByRemovingExpressionForRow:objectiveVariableName];
        
        _tableau = minimizedTableau;

      }
    }
  }
  
  [self.constraints addObject:constraint];
}

// ===== REMOVE CONSTRAINT =============================================================================================
#pragma mark - Remove Constraint

- (void)removeConstraint:(VPLConstraint *)constraint
{
  NSAssert([self containsConstraint:constraint],
           @"Attempt to remove constraint that doesn't exist: %@",
           constraint);
  
  NSString * markerVariableName = constraint.markerVariableName;
  if ([self.tableau.rowVariableNames containsObject:markerVariableName])
  {
    _tableau = [self.tableau tableauByRemovingExpressionForRow:markerVariableName];
  }
  else
  {
    // The marker variable is parametric, so we need to find a way to pivot it into the basis before we can remove it
    
    // First look for a restricted row that contains the marker variable with a negative coefficient. Then we can do a
    // simple pivot.
    NSString * exitVariableName = nil;
    CGFloat minRatio = CGFLOAT_MAX;
    for (NSString * rowVariableName in self.tableau.rowVariableNames)
    {
      if (VPLLinearExpressionVariableIsRestricted(rowVariableName))
      {
        VPLLinearExpression * rowExpr = [self.tableau expressionForRow:rowVariableName];
        if ([rowExpr containsVariable:markerVariableName])
        {
          CGFloat coeff = [rowExpr coefficientForVariable:markerVariableName];
          if (coeff < 0.0)
          {
            CGFloat ratio = -rowExpr.constantValue / coeff;
            if (exitVariableName == nil || ratio < minRatio)
            {
              minRatio = ratio;
              exitVariableName = rowVariableName;
            }
          }
        }
      }
    }
    
    if (exitVariableName == nil)
    {
      // the marker variable is either positive in all restricted row expressions, or only appears in unrestricted rows.
      //
      // Let's look again at restricted rows, and pick the one with the smallest ratio
      for (NSString * rowVariableName in self.tableau.rowVariableNames)
      {
        if (VPLLinearExpressionVariableIsRestricted(rowVariableName))
        {
          VPLLinearExpression * rowExpr = [self.tableau expressionForRow:rowVariableName];
          if ([rowExpr containsVariable:markerVariableName])
          {
            CGFloat coeff = [rowExpr coefficientForVariable:markerVariableName];
            CGFloat ratio = rowExpr.constantValue / coeff;
            if (exitVariableName == nil || ratio < minRatio)
            {
              minRatio = ratio;
              exitVariableName = rowVariableName;
            }
          }
        }
      }
    }
    
    if (exitVariableName == nil)
    {
      // the marker variable only appears in unrestricted row expressions. Pick any, but prefer the original equation
      VPLLinearExpression * originalExpr = [self.tableau expressionForRow:constraint.variableName];
      if (originalExpr != nil
          && [originalExpr containsVariable:markerVariableName])
      {
        exitVariableName = constraint.variableName;
      }
      else
      {
        for (NSString * rowVariableName in self.tableau.rowVariableNames)
        {
          VPLLinearExpression * rowExpr = [self.tableau expressionForRow:rowVariableName];
          if ([rowExpr containsVariable:markerVariableName])
          {
            exitVariableName = rowVariableName;
            break;
          }
        }
      }
    }
    
    if (exitVariableName != nil)
    {
      VPLTableau * tableau = [self.tableau tableauByPivotingRowVariable:exitVariableName
                                                        columnVariable:markerVariableName];
      _tableau = [tableau tableauByRemovingExpressionForRow:markerVariableName];
    }
    // else the marker variable doesn't appear in any equations
  }
}

@end
