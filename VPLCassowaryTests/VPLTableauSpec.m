#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLSpecHelper.h"
#import "VPLTableau.h"
#import "VPLLinearExpression.h"

SpecBegin(VPLTableau)

describe(@"VPLTableau", ^{
  
  __block VPLTableau * tableau;
  
  afterEach(^{
    tableau = nil;
  });
  
  // ===== BASIC VARIABLES =============================================================================================
#pragma mark - Basic Variables
  
  describe(@"- expressionByReplacingRowVariablesInExpression:", ^{
    
    __block VPLLinearExpression * expression;
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
        @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
        @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
        @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      tableau = [VPLTableau tableauWithEquations:equations];
    });

    afterEach(^{
      expression = nil;
      result = nil;
    });
    
    it(@"returns the expression when it contains no basic variables", ^{
      expression = [VPLLinearExpression expressionFromString:@"2a - 1"];
      result = [tableau expressionByReplacingRowVariablesInExpression:expression];
      
      expect(result == expression).to.beTruthy();
    });

    it(@"returns a new expression when it contains basic variables", ^{
      expression = [VPLLinearExpression expressionFromString:@"2x - 1"];
      result = [tableau expressionByReplacingRowVariablesInExpression:expression];
      
      // 2(95 - 0.5a - b) - 1
      // = 190 - a - 2b - 1
      // = 189 - a - 2b
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"189 - a - 2b"]);
    });

  });
  
  // ===== ADD ROW =====================================================================================================
#pragma mark - Add Row
  
  describe(@"tableauBySettingExpression:forRowVariable:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
        @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
        @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
        @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      originalTableau = [VPLTableau tableauWithEquations:equations];
    });
    
    afterEach(^{
      originalTableau = nil;
      result = nil;
    });
    
    describe(@"if the variable is not in the tableau", ^{
      
      beforeEach(^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"2x + 20"];
        result = [originalTableau tableauBySettingExpression:expression
                                              forRowVariable:@"v"];
      });
      
      it(@"adds a row with the expression", ^{
        expect(result.rowVariableNames).to.equal(VPLSortedVariables(@"v", @"x", @"y", @"z"));
        expect([result expressionForRow:@"v"]).to.equal([VPLLinearExpression expressionFromString:@"2x + 20"]);
      });
      
    });
    
  });
  
  // ===== REMOVE ROW ==================================================================================================
#pragma mark - Remove Row
  
  describe(@"- tableauByRemovingExpressionForRow:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
      @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
      @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
      @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      originalTableau = [VPLTableau tableauWithEquations:equations];
      result = [originalTableau tableauByRemovingExpressionForRow:@"x"];
    });
    
    afterEach(^{
      originalTableau = nil;
      result = nil;
    });
    
    it(@"should return a new tableau without the given row", ^{
      expect(result.rowVariableNames).to.equal(VPLSortedVariables(@"y", @"z"));
    });
    
  });
  
  describe(@"- tableauBySubstitutingExpression:forColumnVariable:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
        @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
        @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
        @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      originalTableau = [VPLTableau tableauWithEquations:equations];
      result = [originalTableau tableauBySubstitutingExpression:[VPLLinearExpression expressionFromString:@"c - 50"]
                                              forColumnVariable:@"b"];
    });
    
    afterEach(^{
      originalTableau = nil;
      result = nil;
    });
    
    it(@"substitutes the given expression in each row", ^{
      // x: 95 - 0.5a - (c - 50)
      //    95 - 0.5a - c + 50
      //    145 - 0.5a - c
      
      VPLLinearExpression * xExpr = [VPLLinearExpression expressionFromString:@"145 - 0.5a - c"];
      expect([result expressionForRow:@"x"]).to.equal(xExpr);
      
      // y: 100       - (c - 50)
      //    100       - c + 50
      //    150       - c

      VPLLinearExpression * yExpr = [VPLLinearExpression expressionFromString:@"150 - c"];
      expect([result expressionForRow:@"y"]).to.equal(yExpr);

      // z: 90  -   a - (c - 50)
      //    90  -   a - c + 50
      //    140 -   a - c
      
      VPLLinearExpression * zExpr = [VPLLinearExpression expressionFromString:@"140 - a - c"];
      expect([result expressionForRow:@"z"]).to.equal(zExpr);
    });
    
  });
  
  // ===== PIVOT ROW ===================================================================================================
#pragma mark - Pivot Row
  
  describe(@"- tableauByPivotingRowVariable:columnVariable:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
        @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
        @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
        @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      originalTableau = [VPLTableau tableauWithEquations:equations];
      result = [originalTableau tableauByPivotingRowVariable:@"x"
                                              columnVariable:@"a"];
    });
    
    afterEach(^{
      originalTableau = nil;
      result = nil;
    });
    
    it(@"makes the row variable into a column variable", ^{
      expect(result.rowVariableNames).to.equal(VPLSortedVariables(@"a", @"y", @"z"));
    });

    it(@"makes the column variable into a row variable", ^{
      expect(result.columnVariableNames).to.equal(VPLSortedVariables(@"x", @"b"));
    });
    
    it(@"constructs the column variable's row expression by changing the subject of the row variable's expression", ^{
      // x = 95 - 0.5a - b
      // x - 95 + b = -0.5a
      // 2x - 190 + 2b = -a
      // -2x + 190 - 2b = a
      
      expect([result expressionForRow:@"a"]).to.equal([VPLLinearExpression expressionFromString:@"-2x + 190 - 2b"]);
    });
    
    it(@"substitutes the column variable in other expressions", ^{
      // y  = 100 - b
      expect([result expressionForRow:@"y"]).to.equal([VPLLinearExpression expressionFromString:@"100 - b"]);
      
      // z  =  90 - a - b
      // z  =  90 - (-2x + 190 - 2b) - b
      //    =  90 + 2x - 190 + 2b - b
      //    = -100 + 2x + b
      expect([result expressionForRow:@"z"]).to.equal([VPLLinearExpression expressionFromString:@"-100 + 2x + b"]);
    });
    
  });
  
  // ===== OPTIMIZATION ================================================================================================
#pragma mark - Optimization
  
  // ----- MINIMIZATION ------------------------------------------------------------------------------------------------
#pragma mark Minimization
  
  describe(@"- tableauByMinimizingExpression:objectiveVariableName:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    __block NSString * slackA;
    __block NSString * slackX;
    __block NSString * slackXX;
    __block NSString * objectiveVariableName;
    
    beforeEach(^{
      // Original Tableau:
      //
      //    x = 10 + sX
      //    A = 90 - sX - sXX
      //
      // This is the tableau we'd have after adding inequality x >= 10:
      //
      //    x >= 10
      //    x - sX = 10
      //    x = 10 + sX
      //
      // and then the inequality x <= 100:
      //
      //    x <= 100
      //    x + sXX = 100
      //
      // Since x is a basic variable, we replace it:
      //
      //    (10 + sX) + sXX = 100
      //    10 + sX + sXX = 100
      //
      // Per the cassowary incremental add alorithm, we'd add an aritificial variable A:
      //
      //   A = 100 - 10 - sX - sXX
      //     = 90 - sX - sXX
      
      slackX = [NSString stringWithFormat:@"%@X", VPLLinearExpressionSlackVariablePrefix];
      slackXX = [NSString stringWithFormat:@"%@XX", VPLLinearExpressionSlackVariablePrefix];
      slackA = [NSString stringWithFormat:@"%@A", VPLLinearExpressionSlackVariablePrefix];
      
      VPLLinearExpression * xLessThan10Expr = [VPLLinearExpression expressionWithConstantValue:10
                                                                               variableNames:@[ slackX ]
                                                                        variableCoefficients:@[ @(1) ]];
      
      VPLLinearExpression * slackAExpr = [VPLLinearExpression expressionWithConstantValue:90
                                                                          variableNames:@[ slackX, slackXX ]
                                                                   variableCoefficients:@[ @(-1), @(-1) ]];

      originalTableau = [VPLTableau tableauWithEquations:@{
                                                         @"x" : xLessThan10Expr,
                                                         slackA : slackAExpr
                                                        }];

      // We'll minimize (90 - sX - sXX) with the following tableau:
      //
      //   Z = 90 - sX - sXX
      //   A = 90 - sX - sXX
      //   x = 10 + sX
      //
      // The first pass through simplex will pick sX as the entry value since it's negative. It will pick A as the
      // exit variable, since that is the only pivotable row (Z and x are unrestricted).
      //
      // Beginning the pivot, we'll remove A's row, and change the subject of that row to sX
      //
      //   A = 90 - sX - sXX
      //   A - 90 + sXX = -sX
      //   sX = 90 - A - sXX
      //
      // Substitute this for all sX columns and we get
      //
      //   Z = 90 - (90 - A - sXX) - sXX
      //     = A
      //
      //   x = 10 + (90 - A - sXX)
      //     = 100 - A - sXX
      //
      // And a final tableau of:
      //
      //  Z = A
      //  x = 100 - A - sXX
      //  sX = 90 - A - sXX
      //
      
      objectiveVariableName = [NSString stringWithFormat:@"%@Z", VPLLinearExpressionObjectiveVariablePrefix];
      result = [originalTableau tableauByMinimizingExpression:slackAExpr
                                        objectiveVariableName:objectiveVariableName];
    });
    
    
    afterEach(^{
      slackA = nil;
      slackX = nil;
      slackXX = nil;
      objectiveVariableName = nil;
      
      originalTableau = nil;
      result = nil;
    });
    
    it(@"returns a tableau with the objective variable name", ^{
      expect(result.rowVariableNames).to.equal(VPLSortedVariables(objectiveVariableName, @"x", slackX));
    });
    
    it(@"minimizes the tableau for the given expression", ^{
      VPLLinearExpression * objectiveExpr = [VPLLinearExpression expressionWithConstantValue:0
                                                                             variableNames:@[ slackA ]
                                                                      variableCoefficients:@[ @(1) ]];
      expect([result expressionForRow:objectiveVariableName]).to.equal(objectiveExpr);
      
      VPLLinearExpression * xRowExpr = [VPLLinearExpression expressionWithConstantValue:100
                                                                        variableNames:@[ slackA, slackXX ]
                                                                 variableCoefficients:@[ @(-1), @(-1) ]];
      expect([result expressionForRow:@"x"]).to.equal(xRowExpr);
      
      VPLLinearExpression * slackXRowExpr = [VPLLinearExpression expressionWithConstantValue:90
                                                                             variableNames:@[ slackA, slackXX ]
                                                                      variableCoefficients:@[ @(-1), @(-1) ]];
      expect([result expressionForRow:slackX]).to.equal(slackXRowExpr);
    });
    
  });
  
  describe(@"- tableauByRemovingColumnVariable:", ^{
    
    __block VPLTableau * originalTableau;
    __block VPLTableau * result;
    
    beforeEach(^{
      NSDictionary * equations = @{
        @"x" : [VPLLinearExpression expressionFromString:@"95 - 0.5a - b"],
        @"y" : [VPLLinearExpression expressionFromString:@"100       - b"],
        @"z" : [VPLLinearExpression expressionFromString:@"90 -    a - b"],
      };
      
      originalTableau = [VPLTableau tableauWithEquations:equations];
      result = [originalTableau tableauByRemovingColumnVariable:@"a"];
    });
    
    afterEach(^{
      originalTableau = nil;
      result = nil;
    });
    
    it(@"removes the variable from all row expressions", ^{
      expect([result expressionForRow:@"x"]).to.equal([VPLLinearExpression expressionFromString:@"95 - b"]);
      expect([result expressionForRow:@"y"]).to.equal([VPLLinearExpression expressionFromString:@"100 - b"]);
      expect([result expressionForRow:@"z"]).to.equal([VPLLinearExpression expressionFromString:@"90 - b"]);
    });
    
  });
  
});

SpecEnd