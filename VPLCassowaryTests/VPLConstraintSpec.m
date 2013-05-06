#import "VPLSpecHelper.h"
#import "VPLConstraint.h"

SpecBegin(VPLConstraint)

describe(@"VPLConstraint", ^{
  
  __block VPLConstraint * constraint;
  
  afterEach(^{
    constraint = nil;
  });
  
  // ===== EXPRESSION ==================================================================================================
#pragma mark - Expression
  
  describe(@"- expression", ^{
    
    describe(@"when the constraint is an equality", ^{
      
      describe(@"with a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationEqual
                                                 toVariable:@"y"
                                                 multiplier:1
                                                   constant:10];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x + dX = 10 + y
          // 0 = 10 + y - x - dX
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                                variableNames:@[ @"y", @"x", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(1), @(-1), @(-1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a dummy marker variable", ^{
          expect(VPLLinearExpressionVariableIsDummy(constraint.markerVariableName)).to.beTruthy();
        });

      });
      
      describe(@"without a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationEqual
                                                 toVariable:nil
                                                 multiplier:1
                                                   constant:10];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x + dX = 10
          // 0 = 10 - x - dX
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                                variableNames:@[ @"x", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(-1), @(-1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a dummy marker variable", ^{
          expect(VPLLinearExpressionVariableIsDummy(constraint.markerVariableName)).to.beTruthy();
        });
        
      });
      
    });

    
    describe(@"when the constraint is a GTE inequality", ^{
      
      describe(@"with a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                                 toVariable:@"y"
                                                 multiplier:2
                                                   constant:10];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x >= 2y + 10
          // x - sX = 2y + 10
          // 0 = 2y + 10 - x + sX
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                                variableNames:@[ @"x", @"y", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(-1), @(2), @(1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a slack marker variable", ^{
          expect(constraint.markerVariableName).notTo.beNil();
          expect([constraint.markerVariableName hasPrefix:VPLLinearExpressionSlackVariablePrefix]).to.beTruthy();
        });
        
      });
      
      describe(@"without a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                                 toVariable:@"y"
                                                 multiplier:0
                                                   constant:-3];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x >= 0y - 3
          // x - sX = 0y - 3
          // x - sX + 3 = 0
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:3
                                                                                variableNames:@[ @"x", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(1), @(-1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a slack marker variable", ^{
          expect(constraint.markerVariableName).notTo.beNil();
          expect([constraint.markerVariableName hasPrefix:VPLLinearExpressionSlackVariablePrefix]).to.beTruthy();
        });
        
      });
      
    });
    
    describe(@"when the constraint is a LTE inequality", ^{
      
      describe(@"with a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationLessThanOrEqual
                                                 toVariable:@"y"
                                                 multiplier:-1
                                                   constant:-2];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x <= -y - 2
          // x + sX = -y - 2
          // x + sX + y + 2 = 0
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:2
                                                                                variableNames:@[ @"x", @"y", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(1), @(1), @(1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a slack marker variable", ^{
          expect(constraint.markerVariableName).notTo.beNil();
          expect([constraint.markerVariableName hasPrefix:VPLLinearExpressionSlackVariablePrefix]).to.beTruthy();
        });
        
      });
      
      describe(@"without a related variable", ^{
        
        beforeEach(^{
          constraint = [VPLConstraint constraintWithVariable:@"x"
                                                  relatedBy:VPLConstraintRelationLessThanOrEqual
                                                 toVariable:nil
                                                 multiplier:0
                                                   constant:32];
        });
        
        it(@"returns an expression 0 = c - e, where c is positive", ^{
          // x <= 32
          // x + sX = 32
          // 0 = 32 - x - sX
          
          VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:32
                                                                                variableNames:@[ @"x", constraint.markerVariableName ]
                                                                         variableCoefficients:@[ @(-1), @(-1) ]];
          expect(constraint.expression).to.equal(expectedExpr);
        });
        
        it(@"has a slack marker variable", ^{
          expect(constraint.markerVariableName).notTo.beNil();
          expect([constraint.markerVariableName hasPrefix:VPLLinearExpressionSlackVariablePrefix]).to.beTruthy();
        });
        
      });
      
    });

  });
  
});

SpecEnd