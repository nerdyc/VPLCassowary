#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLTableau.h"
#import "VPLLinearExpression.h"

static int64_t
VPLTableauGenerateVariableNumber()
{
  static int64_t variableCount = 0;
  return OSAtomicIncrement64Barrier(&variableCount);
}

BOOL
VPLTableauIsVariablePivotable(NSString * variableName)
{
  return [variableName hasPrefix:VPLLinearExpressionSlackVariablePrefix];
}

@implementation VPLTableau

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)init
{
  return [self initWithEquations:@{}];
}

- (id)initWithEquations:(NSDictionary *)equations
{
  self = [super init];
  if (self != nil)
  {
    _equations = equations;
  }
  return self;
}

+ (instancetype)tableau
{
  return [[self alloc] init];
}

+ (instancetype)tableauWithEquations:(NSDictionary *)equations
{
  return [[self alloc] initWithEquations:equations];
}

// ===== BASIC VARIABLES ===============================================================================================
#pragma mark - Basic Variables

- (NSArray *)rowVariableNames
{
  return [self.equations.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (VPLLinearExpression *)expressionForRow:(NSString *)basicVariableName
{
  return [self.equations objectForKey:basicVariableName];
}

- (VPLLinearExpression *)expressionByReplacingRowVariablesInExpression:(VPLLinearExpression *)expression
{
  for (NSString * rowVariableName in self.rowVariableNames)
  {
    if ([expression containsVariable:rowVariableName])
    {
      VPLLinearExpression * rowExpression = [self expressionForRow:rowVariableName];
      expression = [expression expressionBySubstitutingExpression:rowExpression
                                                      forVariable:rowVariableName];
    }
  }
  
  return expression;
}

// ===== COLUMN VARIABLES ==============================================================================================
#pragma mark - Column Variables

- (NSArray *)columnVariableNames
{
  NSMutableArray * columnVariables = [[NSMutableArray alloc] init];
  [self.equations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    VPLLinearExpression * expr = obj;
    
    for (NSString * variableName in expr.variableTerms.allKeys)
    {
      if ([columnVariables containsObject:variableName] == NO)
      {
        [columnVariables addObject:variableName];
      }
    }
  }];
  
  [columnVariables sortUsingSelector:@selector(compare:)];
  return columnVariables;
}

// ===== ADDING ROWS ===================================================================================================
#pragma mark - Adding Rows

- (VPLTableau *)tableauBySettingExpression:(VPLLinearExpression *)expression
                           forRowVariable:(NSString *)variableName
{
  NSMutableDictionary * equations = [[NSMutableDictionary alloc] initWithDictionary:self.equations];
  [equations setObject:expression
                forKey:variableName];
  
  return [[[self class] alloc] initWithEquations:equations];
}

- (VPLTableau *)tableauBySubstitutingExpression:(VPLLinearExpression *)expression
                             forColumnVariable:(NSString *)columnVariableName
{
  // iterate through each row, and substitute the expression
  NSMutableDictionary * substitutedEquations = [[NSMutableDictionary alloc] initWithCapacity:[self.equations count]];
  [self.equations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    VPLLinearExpression * variableExpression = obj;
    VPLLinearExpression * substitutedExpression =
      [variableExpression expressionBySubstitutingExpression:expression
                                                 forVariable:columnVariableName];
    
    [substitutedEquations setObject:substitutedExpression
                             forKey:key];
  }];
  
  return [[[self class] alloc] initWithEquations:substitutedEquations];
}

// ===== REMOVING ROWS =================================================================================================
#pragma mark - Removing Rows

- (VPLTableau *)tableauByRemovingExpressionForRow:(NSString *)rowVariable
{
  NSMutableDictionary * updatedEquations = [[NSMutableDictionary alloc] initWithDictionary:self.equations];
  [updatedEquations removeObjectForKey:rowVariable];
  
  return [[[self class] alloc] initWithEquations:updatedEquations];
}

// ===== REMOVING COLUMNS ==============================================================================================
#pragma mark - Removing Columns

- (VPLTableau *)tableauByRemovingColumnVariable:(NSString *)columnVariable
{
  NSMutableDictionary * updatedEquations = [[NSMutableDictionary alloc] initWithCapacity:[self.equations count]];
  [self.equations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    VPLLinearExpression * expr = obj;
    updatedEquations[key] = [expr expressionByRemovingVariableTerm:columnVariable];
    
  }];
  
  return [[[self class] alloc] initWithEquations:updatedEquations];
}

// ===== OPTIMIZATION ==================================================================================================
#pragma mark - Optimization

- (VPLTableau *)tableauByMinimizingExpression:(VPLLinearExpression *)linearExpression
                       objectiveVariableName:(NSString *)objectiveVar
{
  NSAssert(VPLLinearExpressionVariableIsObjective(objectiveVar),
           @"[%@ %@] objective variable name (%@) must be an objective variable",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           objectiveVar);
  
  // look for a pivotable term whose coefficient is >= 0
  VPLTableau * tableau = [self tableauBySettingExpression:linearExpression
                                          forRowVariable:objectiveVar];
  
  while (YES)
  {
    VPLLinearExpression * objectiveExpr = [tableau expressionForRow:objectiveVar];
    
    // Phase 1: Pick an entry variable with a negative coefficient. If none exist, then the solution is optimal. We
    // sort the terms to ensure consistent ordering, and to avoid cycles (Bland’s anti-cycling rule).
    CGFloat objectiveCoefficient = 0.0;
    NSString * entryVariableName = nil;
    for (NSString * parametricVar in [objectiveExpr.variableTerms.allKeys sortedArrayUsingSelector:@selector(compare:)])
    {
      if (VPLTableauIsVariablePivotable(parametricVar))
      {
        CGFloat coeff = [objectiveExpr coefficientForVariable:parametricVar];
        if (coeff < 0.0)
        {
          objectiveCoefficient = coeff;
          entryVariableName = parametricVar;
          break;
        }
      }
    }
    
    // no entry variable, so we're optimal.
    if (entryVariableName == nil) break;
    
    
    // PHASE 2: Pick a pivot row (exit variable row), which will become parametric. We choose a row that contains the
    // entry variable, and has the minimum ratio of (-(rowConstant) / entryCoeff)), as the simplex algorithm describes.
    // This ensures we maintain a feasible system.
    NSString * exitVariableName = nil;
    CGFloat minRatio = CGFLOAT_MAX;
    for (NSString * rowVariable in tableau.rowVariableNames)
    {
      if (VPLTableauIsVariablePivotable(rowVariable))
      {
        VPLLinearExpression * expr = [tableau expressionForRow:rowVariable];
        if ([expr containsVariable:entryVariableName])
        {
          CGFloat entryCoeff = [expr coefficientForVariable:entryVariableName];
          if (entryCoeff < 0.0)
          {
            CGFloat ratio = - expr.constantValue / entryCoeff;
            if (ratio < minRatio)
            {
              minRatio = ratio;
              exitVariableName = rowVariable;
            }
          }
        }
      }
    }
    
    if (exitVariableName != nil)
    {
      // PIVOT
      tableau = [tableau tableauByPivotingRowVariable:exitVariableName
                                       columnVariable:entryVariableName];
    }
    else
    {
      // UNBOUNDED!
      [NSException raise:@"VPLTableauIsUnboundedException"
                  format:@"Tableau is unbounded!"];
    }
  }
  
  return tableau;
}

- (VPLTableau *)tableauByPivotingRowVariable:(NSString *)rowVariable
                             columnVariable:(NSString *)columnVariable
{
  VPLLinearExpression * rowExpression = [self expressionForRow:rowVariable];
  NSAssert([rowExpression containsVariable:columnVariable],
           @"Expected expression for row (%@ = %@) to contain %@",
           rowVariable,
           rowExpression,
           columnVariable);
  
  // change its subject (rowV = c + ... + colV) => colV = c1 + ... + rowV)
  VPLLinearExpression * colExpr = [rowExpression expressionByChangingSubjectFromVariable:rowVariable
                                                                             toVariable:columnVariable];
  
  // remove the row expression (row = expr)
  VPLTableau * tableau = [self tableauByRemovingExpressionForRow:rowVariable];
  tableau = [tableau tableauBySubstitutingExpression:colExpr
                                   forColumnVariable:columnVariable];
  
  return [tableau tableauBySettingExpression:colExpr
                              forRowVariable:columnVariable];
}

@end
