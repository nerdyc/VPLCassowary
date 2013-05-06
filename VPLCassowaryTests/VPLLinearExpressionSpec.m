#import "VPLSpecHelper.h"
#import "VPLLinearExpression.h"

SpecBegin(VPLLinearExpression)

describe(@"VPLLinearExpression", ^{
  
  __block VPLLinearExpression * expression;
  
  afterEach(^{
    expression = nil;
  });
  
  // ===== INITIALIZATION ==============================================================================================
#pragma mark - Initialization
  
  describe(@"+ expressionWithConstant:", ^{
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionWithConstantValue:4.0f];
    });
    
    it(@"returns a constant expression with no terms", ^{
      expect(expression.constantValue).to.equal(4.0f);
      expect([expression isConstant]).to.beTruthy();
    });
    
  });

  describe(@"+ expressionWithConstant:variableNames:variableCoefficients:", ^{
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionWithConstantValue:3.0f
                                                     variableNames:@[ @"a", @"b", @"c" ]
                                              variableCoefficients:@[ @(3.5), @(1.25), @(0.2) ]];
    });
    
    it(@"returns an expression over the given variables", ^{
      expect(expression.variableTerms).to.equal((@{
                                                 
                                                 @"a" : @(3.5),
                                                 @"b" : @(1.25),
                                                 @"c" : @(0.2),
                                                 
                                                 }));
    });
    
    it(@"returns an expression with the constant value", ^{
      expect(expression.constantValue).to.equal(3.0f);
    });
    
  });
  
  describe(@"+ expressionFromString:error:", ^{
    
    // CONSTANTS:
    
    describe(@"when the string is an unsigned constant", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"4"];
      });
      
      it(@"should return a contant expression", ^{
        expect(expression.variableTerms).to.equal(@{});
        expect(expression.constantValue).to.equal(4.0f);
      });
      
    });
    
    describe(@"when the string is a negative constant", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"-4"];
      });
      
      it(@"should return a constant expression", ^{
        expect(expression.variableTerms).to.equal(@{});
        expect(expression.constantValue).to.equal(-4.0f);
      });
      
    });
    
    describe(@"when the string is a positive constant", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"+4"];
      });
      
      it(@"should return an expression with a single constant term", ^{
        expect(expression.variableTerms).to.equal(@{});
        expect(expression.constantValue).to.equal(4.0f);
      });
      
    });
    
    // NAKED VARIABLES:
    
    describe(@"when the string is an unsigned variable", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(1.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a negative variable", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"-x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(-1.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a positive variable", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"+x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(1.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    // VARIABLES WITH INTEGER COEFFICIENTS:
    
    describe(@"when the string is an unsigned variable with an integer coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"3x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(3.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a negative variable with an integer coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"-2x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(-2.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a positive variable with an integer coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"+16x"];
      });
      
      it(@"should return an expression with a single variable", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(16.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    // VARIABLES WITH FLOATING-POINT COEFFICIENTS:
    
    describe(@"when the string is an unsigned variable with a floating-point coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"3.0x"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(3.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a negative variable with a floating-point coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"-14.0centerX"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"centerX" : @(-14.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a positive variable with a floating-point coefficient", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"+1.25y"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"y" : @(1.25) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    // VARIABLES WITH FLOATING-POINT COEFFICIENTS AND EXPLICIT MULTIPLIER:
    
    describe(@"when the string is an unsigned variable with a floating-point coefficient and multiplication symbol", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"3.0 * x"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(3) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a negative variable with a floating-point coefficient and multiplication symbol", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"-14.0*centerX"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"centerX" : @(-14.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string is a positive variable with a floating-point coefficient and multiplication symbol", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"+1.25 *y"];
      });
      
      it(@"should return an expression with a single variable term", ^{
        expect(expression.variableTerms).to.equal((@{ @"y" : @(1.25) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    // EXPRESSIONS WITH A CONSTANT
    
    describe(@"when the string has multiple constant values", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"1.25 - 3.25"];
      });
      
      it(@"should return a constant expression with the terms combined", ^{
        expect(expression.constantValue).to.equal(-2.0);
        expect(expression.variableTerms).to.equal(@{});
      });
      
    });
    
    describe(@"when the string has multiple variable values", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"1.25x - 3.25y"];
      });
      
      it(@"should return an expression with a multiple variable terms", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(1.25), @"y" : @(-3.25) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    
    describe(@"when the string has multiple variable values of the same name", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"1.25x - 3.25x"];
      });
      
      it(@"should return an expression with combined coefficients", ^{
        expect(expression.variableTerms).to.equal((@{ @"x" : @(-2.0) }));
        expect(expression.constantValue).to.equal(0.0);
      });
      
    });
    
    describe(@"when the string has multiple variable and constant values", ^{
      
      beforeEach(^{
        expression = [VPLLinearExpression expressionFromString:@"1.25x-8+3.25*y+12.2"];
      });
      
      it(@"should return an expression with a multiple terms", ^{
        expect(expression.constantValue).to.beCloseToWithin(4.2, 0.000000001);
        expect(expression.variableTerms).to.equal((@{ @"x" : @(1.25), @"y" : @(3.25) }));
      });
      
    });
    
  });
  
  // ===== EQUALITY ====================================================================================================
#pragma mark - Equality
  
  describe(@"- isEqualToExpression:", ^{
    
    describe(@"when provided equal constant expressions", ^{
      
      it(@"should return YES", ^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"4 + 2"];
        VPLLinearExpression * otherExpression = [VPLLinearExpression expressionFromString:@"2 + 4"];
        
        expect([expression isEqualToExpression:otherExpression]).to.beTruthy();
      });
      
    });
    
    describe(@"when provided different constant expressions", ^{
      
      it(@"should return NO", ^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"2 + 1"];
        VPLLinearExpression * otherExpression = [VPLLinearExpression expressionFromString:@"2 + 2"];
        
        expect([expression isEqualToExpression:otherExpression]).to.beFalsy();
      });
      
    });
    
    describe(@"when provided equal variable expressions", ^{
      
      it(@"should return YES", ^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"4x + 2y"];
        VPLLinearExpression * otherExpression = [VPLLinearExpression expressionFromString:@"4x + 2y"];
        
        expect([expression isEqualToExpression:otherExpression]).to.beTruthy();
      });
      
    });
    
    describe(@"when provided equal variable expressions with a different order", ^{
      
      it(@"should return YES", ^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"4y + 2x"];
        VPLLinearExpression * otherExpression = [VPLLinearExpression expressionFromString:@"2x + 4y"];
        
        expect([expression isEqualToExpression:otherExpression]).to.beTruthy();
      });
      
    });
    
    describe(@"when provided different variable expressions", ^{
      
      it(@"should return YES", ^{
        VPLLinearExpression * expression = [VPLLinearExpression expressionFromString:@"2x + 4y"];
        VPLLinearExpression * otherExpression = [VPLLinearExpression expressionFromString:@"4x + 2y"];
        
        expect([expression isEqualToExpression:otherExpression]).to.beFalsy();
      });
      
    });
    
  });

  // ===== VARIABLES ===================================================================================================
#pragma mark - Variables
  
  describe(@"- containsVariable:", ^{
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"2x + 10"];
    });
    
    it(@"returns YES when the variable exists", ^{
      expect([expression containsVariable:@"x"]).to.beTruthy();
    });

    it(@"returns NO when the variable doesn't exist", ^{
      expect([expression containsVariable:@"y"]).to.beFalsy();
    });

  });
  
  describe(@"- variableNamesPassingTest:", ^{
    
    __block NSArray * variableNames;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"a + babba + abby + 10"];
      variableNames = [expression variableNamesPassingTest:^(NSString *variableName,
                                                             NSNumber *coefficient,
                                                             BOOL *stop) {
        
        return [variableName hasPrefix:@"a"];
        
      }];
    });
    
    it(@"returns an array of variable names that the block accepted", ^{
      expect(variableNames).to.equal(VPLSortedVariables(@"a", @"abby"));
    });
    
  });
  
  // ===== SUBSTITUTION ================================================================================================
#pragma mark - Substitution
  
  describe(@"- expressionByNegatingExpression", ^{
    
    __block VPLLinearExpression * result;
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns a new expression with all terms negated", ^{
      expression = [VPLLinearExpression expressionFromString:@"2x + y - 10"];
      result = [expression expressionByNegatingExpression];
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"-2x - y + 10"]);
    });
    
    it(@"returns self the expression is 0", ^{
      expression = [VPLLinearExpression expressionWithConstantValue:0];
      result = [expression expressionByNegatingExpression];
      expect(result == expression).to.beTruthy();
    });
    
  });
  
  describe(@"- expressionByMultiplying:", ^{

    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"2x + y - 10"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns a new expression with all terms multiplied by the constant", ^{
      result = [expression expressionByMultiplying:10];
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"20x + 10y - 100"]);
    });
    
    it(@"returns self if multiplying by 1", ^{
      result = [expression expressionByMultiplying:1];
      expect(result == expression).to.beTruthy();
    });
    
    it(@"returns 0 expression if multiplying by 0", ^{
      result = [expression expressionByMultiplying:0];
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"0"]);
    });
    
  });
  
  describe(@"- expressionBySubstitutingExpression:forVariable:", ^{
    
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"2x + 3y - 5"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    describe(@"when the variable exists", ^{
      
      beforeEach(^{
        VPLLinearExpression * substituteExpression = [VPLLinearExpression expressionFromString:@"2z - x + 10"];
        result = [expression expressionBySubstitutingExpression:substituteExpression
                                                    forVariable:@"y"];
      });
      
      it(@"returns the expression resulting from substituting the variable", ^{
        //   2x + 3(2z -x + 10) - 5
        // = 2x + 6z - 3x + 30 - 5
        // = -x + 6z + 25
        VPLLinearExpression * expectedExpression =
          [VPLLinearExpression expressionFromString:@"-x + 6z + 25"];
        
        expect(result).to.equal(expectedExpression);
      });
      
    });
    
    describe(@"when substituting cancels out another variable", ^{
      
      beforeEach(^{
        //   2(-1.5y + z) + 3y - 5
        // = -3y + 2z + 3y - 5
        // = 2z - 5
        
        VPLLinearExpression * substituteExpression = [VPLLinearExpression expressionFromString:@"-1.5y + z"];
        result = [expression expressionBySubstitutingExpression:substituteExpression
                                                    forVariable:@"x"];

      });
      
      it(@"should remove that variable from the expression", ^{
        expect(result).to.equal([VPLLinearExpression expressionFromString:@"2z - 5"]);
      });
      
    });
    
    describe(@"when the variable doesn't exist", ^{
      
      beforeEach(^{
        VPLLinearExpression * substituteExpression = [VPLLinearExpression expressionFromString:@"10"];
        result = [expression expressionBySubstitutingExpression:substituteExpression
                                                    forVariable:@"z"];
      });
      
      it(@"returns itself", ^{
        expect(result == expression).to.beTruthy();
      });
      
    });
    
  });
  
  describe(@"- expressionBySubstitutingExpression:forVariable: (2)", ^{
    
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"90 - sX - sXX"];
      VPLLinearExpression * substituteExpr = [VPLLinearExpression expressionFromString:@"90 - sXX - sA"];
      
      result = [expression expressionBySubstitutingExpression:substituteExpr
                                                  forVariable:@"sX"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns the expression resulting from substituting the variable", ^{
      //     90 - (90 - sXX - sA) - sXX
      //   = 90 - 90 + sXX + sA - sXX
      //   = sA
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"sA"]);
    });

  });
  
  // ----- SOLVING -----------------------------------------------------------------------------------------------------
#pragma mark Solving
  
  describe(@"- expressionBySolvingForVariable:", ^{
    
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"4a + 2b - 10"];
      result = [expression expressionBySolvingForVariable:@"b"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns the solution for a given variable in the expression", ^{
      // 4a + 2b - 10 = 0
      // 2b = -4a + 10
      // b = -2a + 5
      
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"-2a + 5"]);
    });
    
  });
  
  describe(@"- expressionByChangingSubjectFromVariable:toVariable:", ^{
    
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"4a + 2b - 10"];
      result = [expression expressionByChangingSubjectFromVariable:@"c"
                                                        toVariable:@"b"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns a new expression by exchanging the old subject with the given variable", ^{
      // c = 4a + 2b - 10
      // c - 4a + 10 = 2b
      // 0.5c - 2a + 5 = b
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"0.5c - 2a + 5"]);
    });
    
  });
  
  describe(@"- expressionByRemovingVariableTerm:", ^{
    
    __block VPLLinearExpression * result;
    
    beforeEach(^{
      expression = [VPLLinearExpression expressionFromString:@"4a + 2b - 10"];
      result = [expression expressionByRemovingVariableTerm:@"b"];
    });
    
    afterEach(^{
      result = nil;
    });
    
    it(@"returns a new expression without the variable", ^{
      expect(result).to.equal([VPLLinearExpression expressionFromString:@"4a - 10"]);
    });
    
  });
  
});

SpecEnd