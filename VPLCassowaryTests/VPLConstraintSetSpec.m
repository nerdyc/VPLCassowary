#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLSpecHelper.h"
#import "VPLConstraintSet.h"
#import "VPLConstraint.h"
#import "VPLTableau.h"

SpecBegin(VPLConstraintSet)

describe(@"VPLConstraintSet", ^{
  
  __block VPLConstraintSet * constraintSet;
  
  afterEach(^{
    constraintSet = nil;
  });
  
  describe(@"- addConstraint:", ^{
    
    describe(@"when there are no constraints", ^{
      
      __block VPLConstraint * xGTE10;
      
      beforeEach(^{
        constraintSet = [[VPLConstraintSet alloc] init];
        
        xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                            relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                           toVariable:nil
                                           multiplier:0
                                             constant:10];
        
        [constraintSet addConstraint:xGTE10];
      });
      
      afterEach(^{
        xGTE10 = nil;
      });
      
      it(@"adds the constraint directly to the tableau", ^{
        // Converting the constraint to augmented simplex form, we add a slack variable
        //
        //   x >= 10
        //   x - sX = 10
        //
        // Since x is an unrestricted variable, we can solve for it and add it directly to the tableau:
        //
        //   x = 10 + sX
        
        VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                              variableNames:@[ xGTE10.markerVariableName ]
                                                                       variableCoefficients:@[ @(1.0f) ]];
        
        expect([constraintSet.tableau equations]).to.equal(@{ @"x" : expectedExpr });
        
      });
      
    });
    
    describe(@"when the constraint contains an unrestricted variable", ^{
      
      __block VPLConstraint * xGTE10;
      __block VPLConstraint * yEQx;
      
      beforeEach(^{
        constraintSet = [[VPLConstraintSet alloc] init];
        
        // x >= 10
        xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                            relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                           toVariable:nil
                                           multiplier:0
                                             constant:10];
        
        [constraintSet addConstraint:xGTE10];
        
        // y = x
        yEQx = [VPLConstraint constraintWithVariable:@"y"
                                          relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                         toVariable:@"x"
                                         multiplier:1
                                           constant:0];
        
        [constraintSet addConstraint:yEQx];
      });
      
      afterEach(^{
        xGTE10 = nil;
        yEQx = nil;
      });
      
      it(@"adds the constraint directly to the tableau", ^{
        // Our initial tableau was:
        //
        //  x = 10 + sX
        //
        // We're adding:
        //
        //  y = x + dY
        //  0 = x + dY - y
        //
        // We'll first replace basic variables (x) and get:
        //
        //  0 = (10 + sX) + dY - y
        //    =  10 + sX  + dY - y
        //
        // This expression has an unrestricted variable (y) so we can solve for it and add the result to the tableau:
        //
        //  0 = 10 + sX + dY - y
        //  y = 10 + sX + dY
        //
        
        VPLLinearExpression * expectedExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                              variableNames:@[ xGTE10.markerVariableName, yEQx.markerVariableName ]
                                                                       variableCoefficients:@[ @(1.0f), @(1.0f) ]];
        
        expect([constraintSet.tableau expressionForRow:@"y"]).to.equal(expectedExpr);
      });
      
    });
    
    describe(@"when the constraint contains an unknown, restricted variable w/ a negative coefficient", ^{

      __block VPLConstraint * xGTE10;
      __block VPLConstraint * xLTE100;
      
      beforeEach(^{
        constraintSet = [[VPLConstraintSet alloc] init];
        
        // x >= 10
        xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                            relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                           toVariable:nil
                                           multiplier:0
                                             constant:10];
        
        [constraintSet addConstraint:xGTE10];
        
        // x <= 100
        xLTE100 = [VPLConstraint constraintWithVariable:@"x"
                                             relatedBy:VPLConstraintRelationLessThanOrEqual
                                            toVariable:nil
                                            multiplier:0
                                              constant:100];
        
        [constraintSet addConstraint:xLTE100];
      });
      
      afterEach(^{
        xGTE10 = nil;
        xLTE100 = nil;
      });
      
      it(@"adds the constraint directly", ^{
        // Our initial tableau was:
        //
        //  x = 10 + sX
        //
        // We're adding:
        //
        //  x <= 100
        //  x + sXX = 100
        //  0 = 100 - x - sXX
        //
        // We'll first replace basic variables (x) and get:
        //
        //  0 = 100 - (10 + sX) - sXX
        //    = 100 - 10 - sX - sXX
        //    = 90 - sX - sXX
        //
        // This expression only has restricted variables, but one of them is unknown (sXX) and has a negative
        // coefficient. We can add this directly after solving for sXX:
        //
        //   0 = 90 - sX - sXX
        //   sXX = 90 - sX
        //
        // This gives us a final tableau of:
        //
        //     x = 10 + sX
        //   sXX = 90 - sX
        //
        
        VPLLinearExpression * expectedXExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                               variableNames:@[ xGTE10.markerVariableName ]
                                                                       variableCoefficients:@[ @(1.0f) ]];

        expect([constraintSet.tableau expressionForRow:@"x"]).to.equal(expectedXExpr);
        
        VPLLinearExpression * expectedSlackXExpr = [VPLLinearExpression expressionWithConstantValue:90
                                                                                    variableNames:@[ xGTE10.markerVariableName ]
                                                                             variableCoefficients:@[ @(-1.0f) ]];
        expect([constraintSet.tableau expressionForRow:xLTE100.markerVariableName]).to.equal(expectedSlackXExpr);
        
        expect(constraintSet.tableau.equations).to.equal((@{
                                                         @"x" : expectedXExpr,
                                                         xLTE100.markerVariableName : expectedSlackXExpr
                                                          }));
      });
      
    });
    
    describe(@"when the constraint consists of only dummy variables", ^{
      
      __block VPLConstraint * xEQ50;
      __block VPLConstraint * zEQ50;
      __block VPLConstraint * zEQx;
      
      beforeEach(^{
        constraintSet = [[VPLConstraintSet alloc] init];
        
        // First we add a simple equality constraint:
        //
        //   x = 50
        //   x + d1 = 50
        //   0 = 50 - x - d1
        //
        //  Giving the tableau of:
        //
        //   x = 50 - d1
        
        xEQ50 = [VPLConstraint constraintWithVariable:@"x"
                                            relatedBy:VPLConstraintRelationEqual
                                           toVariable:nil
                                           multiplier:0
                                             constant:50];
        
        [constraintSet addConstraint:xEQ50];
        
        expect([constraintSet.tableau expressionForRow:@"x"]).to.equal([VPLLinearExpression expressionWithConstantValue:50
                                                                                                         variableNames:@[ xEQ50.markerVariableName ]
                                                                                                  variableCoefficients:@[ @(-1.0) ]]);
        
        // We add z = 50 the same way
        //
        //   z = 50
        //   z + d2 = 50
        //   0 = 50 - z - d2
        //
        //  Giving the tableau of:
        //
        //   x = 50 - d1
        //   z = 50      - d2
        //
        zEQ50 = [VPLConstraint constraintWithVariable:@"z"
                                             relatedBy:VPLConstraintRelationEqual
                                            toVariable:nil
                                            multiplier:0
                                              constant:50];
        [constraintSet addConstraint:zEQ50];
        
        expect([constraintSet.tableau expressionForRow:@"z"]).to.equal([VPLLinearExpression expressionWithConstantValue:50
                                                                                                         variableNames:@[ zEQ50.markerVariableName ]
                                                                                                  variableCoefficients:@[ @(-1.0) ]]);
        
        // Now we add an equality between z and x
        //
        //  z = x
        //  z + d3 = x
        //  0 = x - z - d3
        //    = (50 - d1) - (50 - d2) - d3
        //    = 50 - d1 - 50 + d2 - d3
        //    = -d1 + d2 - d3
        //
        // Since this contains only dummy variables, and d3 in unknown, we can add d3 directly to the tableau:
        //
        //   x  = 50 - d1
        //   z  = 50 - d2
        //   d3 = - d1 + d2
        //
        
        zEQx = [VPLConstraint constraintWithVariable:@"z"
                                           relatedBy:VPLConstraintRelationEqual
                                          toVariable:@"x"
                                          multiplier:1
                                            constant:0];
        [constraintSet addConstraint:zEQx];
        
      });
      
      afterEach(^{
        xEQ50 = nil;
        zEQ50 = nil;
        zEQx = nil;
      });
      
      it(@"adds the constraint directly after solving for the new dummy variable", ^{
        VPLLinearExpression * expectedD3Expr = [VPLLinearExpression expressionWithConstantValue:0
                                                                                variableNames:@[ xEQ50.markerVariableName, zEQ50.markerVariableName ]
                                                                         variableCoefficients:@[ @(-1.0f), @(1.0f) ]];
        
        expect([constraintSet.tableau expressionForRow:zEQx.markerVariableName]).to.equal(expectedD3Expr);
        expect([constraintSet.tableau rowVariableNames]).to.equal((VPLSortedVariables(@"x", @"z", zEQx.markerVariableName)));
      });
      
    });
    
    describe(@"when an artificial variable is used", ^{
      
      describe(@"and the artificial variable is parametric after minimization", ^{
        
        // ADD x >= 10
        //
        // x - s1 = 10
        // x = 10 + s1
        //
        // ADD x >= 20
        //
        // x - s2 = 20
        // 0 = 20 - x + s2
        //   = 20 - (10 + s1) + s2
        //   = 20 - 10 - s1 + s2
        //   = 10 - s1 + s2
        //
        // Use an artificial variable, since there is no new, restricted variable we can use
        //
        //  Z = 10 - s1 + s2
        //  x = 10 + s1
        //  A = 10 - s1 + s2
        //
        // Minimize. -s1 is picked as the entry variable. A is the only row that can be selected as the exit row, so we pivot
        //
        //  A = 10 - s1 + s2
        //  0 = 10 - s1 + s2 - A
        //  s1 = 10 + s2 - A
        //
        //  Z = 10 - (10 + s2 - A) + s2
        //    = 10 - 10 - s2 + A + s2
        //    = A
        //  x = 10 + (10 + s2 - A)
        //    = 10 + 10 + s2 - A
        //    = 20 + s2 - A
        //
        // Since A is parametric we can simply remove it, ending up with the tableau:
        //
        //  x = 20 + s2
        //  s1 = 10 + s2
        
        __block VPLConstraint * xGTE10;
        __block VPLConstraint * xGTE20;
        
        beforeEach(^{
          constraintSet = [[VPLConstraintSet alloc] init];
          
          xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                              relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                             toVariable:nil
                                             multiplier:0
                                               constant:10];
          
          [constraintSet addConstraint:xGTE10];
          
          xGTE20 = [VPLConstraint constraintWithVariable:@"x"
                                              relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                             toVariable:nil
                                             multiplier:0
                                               constant:20];
          
          [constraintSet addConstraint:xGTE20];
        });
        
        afterEach(^{
          xGTE10 = nil;
          xGTE20 = nil;
        });
        
        it(@"removes the artificial variable column", ^{
          expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x", xGTE10.markerVariableName));
          expect(constraintSet.tableau.columnVariableNames).to.equal(VPLSortedVariables(xGTE20.markerVariableName));
          
          VPLLinearExpression * expectedXExpr = [VPLLinearExpression expressionWithConstantValue:20
                                                                                 variableNames:@[ xGTE20.markerVariableName ]
                                                                          variableCoefficients:@[ @(1) ]];
          
          expect([constraintSet.tableau expressionForRow:@"x"]).to.equal(expectedXExpr);

          VPLLinearExpression * expectedXMarkerExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                                 variableNames:@[ xGTE20.markerVariableName ]
                                                                          variableCoefficients:@[ @(1) ]];
          
          expect([constraintSet.tableau expressionForRow:xGTE10.markerVariableName]).to.equal(expectedXMarkerExpr);        
        });
        
      });
      
    });
    
  });
  
  // ===== REMOVING CONSTRAINTS ========================================================================================
#pragma mark - Removing Constraints
  
  describe(@"- removeConstraint:", ^{
    
    describe(@"when the constraint's marker variable is basic", ^{
      
      // We'll start with a tableau for x >= 10 and x <= 100, which looks like this:
      //
      // 1. Add x >= 10
      //
      //    x >= 10
      //    x - s1 = 10
      //    0 = 10 - x + s1
      //
      // 2. x = 10 + s1 can be added directly to the tableau.
      //
      // 3. Add x <= 100
      //
      //    x <= 100
      //    x + s2 = 100
      //    0 = 100 - x - s2
      //      = 100 - (10 + s1) - s2
      //      = 90 - s1 - s2
      //
      // 4. Since s2 is a new restricted variable, add it to the tableau, giving:
      //
      //    x = 10 + s1
      //    s2 = 90 - s1
      //
      __block VPLConstraint * xGTE10;
      __block VPLConstraint * xLTE100;
      
      beforeEach(^{
        constraintSet = [[VPLConstraintSet alloc] init];
        
        xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                            relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                           toVariable:nil
                                           multiplier:0
                                             constant:10];
        [constraintSet addConstraint:xGTE10];
        
        xLTE100 = [VPLConstraint constraintWithVariable:@"x"
                                             relatedBy:VPLConstraintRelationLessThanOrEqual
                                            toVariable:nil
                                            multiplier:0
                                              constant:100];
        [constraintSet addConstraint:xLTE100];
        
        expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x", xLTE100.markerVariableName));
        
        [constraintSet removeConstraint:xLTE100];
      });
      
      afterEach(^{
        xGTE10 = nil;
        xLTE100 = nil;
      });
      
      it(@"simply drops the marker variable's row", ^{
        expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x"));
        expect([constraintSet.tableau expressionForRow:@"x"]).to.equal((
          [VPLLinearExpression expressionWithConstantValue:10
                                            variableNames:@[ xGTE10.markerVariableName ]
                                     variableCoefficients:@[ @(1.0f) ]]
        ));
      });
      
    });
    
    describe(@"when the constraint's marker variable is parametric", ^{
      
      describe(@"and a restrictive row expression exists (e.g. a negative marker variable coefficient exists)", ^{
        
        // We'll start with a tableau for x >= 10 and x <= 100, which looks like this:
        //
        //    x = 10 + s1
        //    s2 = 90 - s1
        //
        // Removing the first constraint (x >= 10) means that its marker variable (s1) is parametric. We need to pivot it
        // into the basis to be able to remove it.
        //
        // We look for the most restrictive equation and select that row to become parametric. There's such a row -- s2.
        //
        //  s2 = 90 - s1
        //   0 = 90 - s1 - s2
        //  s1 = 90 - s2
        //
        // Replacing s1 we get:
        //
        //   x = 10 + s1
        //     = 10 + (90 - s2)
        //     = 100 - s2
        //
        // Which is our final tableau, since we simply remove s1 after that.
        //
        __block VPLConstraint * xGTE10;
        __block VPLConstraint * xLTE100;
        
        beforeEach(^{
          constraintSet = [[VPLConstraintSet alloc] init];
          
          xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                              relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                             toVariable:nil
                                             multiplier:0
                                               constant:10];
          [constraintSet addConstraint:xGTE10];
          
          xLTE100 = [VPLConstraint constraintWithVariable:@"x"
                                               relatedBy:VPLConstraintRelationLessThanOrEqual
                                              toVariable:nil
                                              multiplier:0
                                                constant:100];
          [constraintSet addConstraint:xLTE100];
          
          expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x", xLTE100.markerVariableName));
          
          [constraintSet removeConstraint:xGTE10];
        });
        
        afterEach(^{
          xGTE10 = nil;
          xLTE100 = nil;
        });
        
        it(@"pivot the marker variable into the basis and remove it", ^{
          expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x"));
          expect([constraintSet.tableau expressionForRow:@"x"]).to.equal([VPLLinearExpression expressionWithConstantValue:100
                                                                                                           variableNames:@[ xLTE100.markerVariableName ]
                                                                                                    variableCoefficients:@[ @(-1.0) ]]);
        });
        
      });
      
      describe(@"but a restrictive row expression doesn't exist (e.g. a negative marker variable coefficient doesn't exist)", ^{
        
        describe(@"if it exists in an equation for a restricted variable", ^{
          
          // The tableau for x >= 10, x >= 20 is as follows:
          //
          //  x = 20 + s2
          //  s1 = 10 + s2
          //
          // Adding x >= 30
          //
          //  x >= 30
          //  x - s3 = 30
          //  0 = 30 + s3 - x
          //    = 30 + s3 - (20 + s2)
          //    = 30 + s3 - 20 - s2
          //    = 10 + s3 - s2
          //
          // We need to use an artifical variable, since there is no new variable with a negative coefficient
          //
          //  Z = 10 + s3 - s2
          //  x = 20 + s2
          //  s1 = 10 + s2
          //  A = 10 + s3 - s2
          //
          // s2 is selected as the entry variable. Since A is the only applicable row with a negative coefficient for s2, it is
          // selected as the exit row.
          //
          //  A = 10 + s3 - s2
          //  0 = 10 + s3 - s2 - A
          //  s2 = 10 + s3 - A
          //
          // Replacing s2 in the tableau...
          //
          //  Z = 10 + s3 - (10 + s3 - A)
          //    = 10 + s3 - 10 - s3 + A
          //    = A
          //  x = 20 + (10 + s3 - A)
          //    = 20 + 10 + s3 - A
          //    = 30 + s3 - A
          //  s1 = 10 + (10 + s3 - A)
          //     = 10 + 10 + s3 - A
          //     = 20 + s3 - A
          //
          // Since A is parametric, we can remove it, and get the following tableau:
          //
          //   x = 30 + s3
          //  s1 = 20 + s3
          //  s2 = 10 + s3
          //
          // We now REMOVE x >= 30, which has s3 as its marker variable. There are no negative coefficients in the
          // s1, or s2 rows (the restricted variables). So we simply pick the one with the smallest ratio
          // Since (s1: 20 / 1, s2: 10 / 1) s2 is the row with the smallest ratio. We use that to pivot:
          //
          //  s2 = 10 + s3
          //  0 = 10 + s3 - s2
          //  -s3 = 10 - s2
          //  s3 = -10 + s2
          //
          // Replacing s3 in the tableau:
          //
          //   x = 30 + (-10 + s2)
          //     = 30 - 10 + s2
          //     = 20 + s2
          //  s1 = 20 + (-10 + s2)
          //     = 20 - 10 + s2
          //     = 10 + s2
          //
          // Giving the tableau:
          //
          //   x = 20 + s2
          //  s1 = 10 + s2
          //  s3 = -10 + s2
          //
          // Which we then remove s3 from and get:
          //
          //   x = 20 + s2
          //  s1 = 10 + s2
          //
          
          __block VPLConstraint * xGTE10;
          __block VPLConstraint * xGTE20;
          __block VPLConstraint * xGTE30;
          
          beforeEach(^{
            constraintSet = [[VPLConstraintSet alloc] init];
            
            xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                                relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                               toVariable:nil
                                               multiplier:0
                                                 constant:10];
            
            [constraintSet addConstraint:xGTE10];
            
            xGTE20 = [VPLConstraint constraintWithVariable:@"x"
                                                relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                               toVariable:nil
                                               multiplier:0
                                                 constant:20];
            
            [constraintSet addConstraint:xGTE20];
            
            xGTE30 = [VPLConstraint constraintWithVariable:@"x"
                                                relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                               toVariable:nil
                                               multiplier:0
                                                 constant:30];
            
            [constraintSet addConstraint:xGTE30];
            
            
            [constraintSet removeConstraint:xGTE30];
          });
          
          afterEach(^{
            xGTE10 = nil;
            xGTE20 = nil;
            xGTE30 = nil;
          });
          
          it(@"pivot the marker variable into the basis using the smallest ratio", ^{
            expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x", xGTE10.markerVariableName));
            expect(constraintSet.tableau.columnVariableNames).to.equal(VPLSortedVariables(xGTE20.markerVariableName));
            
            VPLLinearExpression * expectedXExpr = [VPLLinearExpression expressionWithConstantValue:20
                                                                                   variableNames:@[ xGTE20.markerVariableName ]
                                                                            variableCoefficients:@[ @(1) ]];
            
            expect([constraintSet.tableau expressionForRow:@"x"]).to.equal(expectedXExpr);
            
            VPLLinearExpression * expectedXMarkerExpr = [VPLLinearExpression expressionWithConstantValue:10
                                                                                         variableNames:@[ xGTE20.markerVariableName ]
                                                                                  variableCoefficients:@[ @(1) ]];
            
            expect([constraintSet.tableau expressionForRow:xGTE10.markerVariableName]).to.equal(expectedXMarkerExpr);
          });
          
          
        });

        describe(@"if it only exists in equations for unrestricted variables", ^{
          
          // After adding x >= 10 we have a tableau in which our marker only appears in unrestricted rows:
          //
          // 1. Add x >= 10
          //
          //    x >= 10
          //    x - s1 = 10
          //    0 = 10 - x + s1
          //    x = 10 + s1
          //
          // 2. Add z <= x
          //
          //    z <= x
          //    z + s2 = x
          //    0 = x - z - s2
          //      = (10 + s1) - z - s2
          //
          //    z = 10 + s1 - s2
          //
          // s1 now appears only in restricted equations. We can pick any, but prefer to remove the original equation.
          // Pivoting on x:
          //
          //    x = 10 + s1
          //    s1 = -10 + x
          //
          //    z = 10 + s1 - s2
          //    z = 10 + (-10 + x) - s2
          //      = 10 - 10 + x - s2
          //      = x - s2
          //
          // This gives us a final tableau of:
          //
          //  z = x - s2
          //
          __block VPLConstraint * xGTE10;
          __block VPLConstraint * zEQx;
          
          beforeEach(^{
            constraintSet = [[VPLConstraintSet alloc] init];
            
            xGTE10 = [VPLConstraint constraintWithVariable:@"x"
                                                relatedBy:VPLConstraintRelationGreaterThanOrEqual
                                               toVariable:nil
                                               multiplier:0
                                                 constant:10];
            [constraintSet addConstraint:xGTE10];
            
            zEQx = [VPLConstraint constraintWithVariable:@"z"
                                                 relatedBy:VPLConstraintRelationEqual
                                                toVariable:@"x"
                                                multiplier:1
                                                  constant:0];
            [constraintSet addConstraint:zEQx];
            
            expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"x", @"z"));
            
            [constraintSet removeConstraint:xGTE10];
          });
          
          afterEach(^{
            xGTE10 = nil;
            zEQx = nil;
          });
          
          it(@"removes an unrestricted row containing the equation, preferring the original equation", ^{
            expect(constraintSet.tableau.rowVariableNames).to.equal(VPLSortedVariables(@"z"));
            
            VPLLinearExpression * expectedZExpr = [VPLLinearExpression expressionWithConstantValue:0
                                                                                   variableNames:@[ @"x", zEQx.markerVariableName ]
                                                                            variableCoefficients:@[ @(1.0f), @(-1.0f) ]];
            expect([constraintSet.tableau expressionForRow:@"z"]).to.equal(expectedZExpr);
          });
          
        });
        
      });
      
    });
    
  });
  
});

SpecEnd