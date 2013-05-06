#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLLinearExpression.h"

// ===== ERRORS ========================================================================================================

NSString * const VPLLinearExpressionErrorDomain = @"VPLLinearExpression";

// ===== CONSTANTS =====================================================================================================

NSString * const VPLLinearExpressionDummyVariablePrefix      = @"^";        // ^ dunce hat!
NSString * const VPLLinearExpressionSlackVariablePrefix      = @"$";        // $lack
NSString * const VPLLinearExpressionObjectiveVariablePrefix  = @"@";   // @rtificial

BOOL
VPLLinearExpressionVariableIsRestricted(NSString * variableName)
{
  return ([variableName hasPrefix:VPLLinearExpressionDummyVariablePrefix]
          || [variableName hasPrefix:VPLLinearExpressionSlackVariablePrefix]);
}

BOOL
VPLLinearExpressionVariableIsUnrestricted(NSString * variableName)
{
  return !VPLLinearExpressionVariableIsRestricted(variableName);
}

BOOL
VPLLinearExpressionVariableIsDummy(NSString * variableName)
{
  return [variableName hasPrefix:VPLLinearExpressionDummyVariablePrefix];
}

BOOL
VPLLinearExpressionVariableIsObjective(NSString * variableName)
{
  return [variableName hasPrefix:VPLLinearExpressionObjectiveVariablePrefix];
}

BOOL
VPLLinearExpressionVariableIsSlack(NSString * variableName)
{
  return [variableName hasPrefix:VPLLinearExpressionSlackVariablePrefix];
}

BOOL
VPLLinearExpressionVariableIsExternal(NSString * variableName)
{
  return !(VPLLinearExpressionVariableIsSlack(variableName)
           || VPLLinearExpressionVariableIsDummy(variableName)
           || VPLLinearExpressionVariableIsObjective(variableName));
}

BOOL
VPLLinearExpressionVariableIsPivotable(NSString * variableName)
{
  return VPLLinearExpressionVariableIsSlack(variableName);
}

CGFloat
CGFloatFromObjectValue(id obj)
{
  return (CGFLOAT_IS_DOUBLE ? [obj doubleValue] : [obj floatValue]);
}

@implementation VPLLinearExpression

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)initWithConstantValue:(CGFloat)constantValue
{
  return [self initWithConstantValue:constantValue
                       variableNames:@[]
                variableCoefficients:@[]];
}

- (id)initWithConstantValue:(CGFloat)constantValue
              variableNames:(NSArray *)variableNames
       variableCoefficients:(NSArray *)variableCoefficients
{
  NSMutableDictionary * variableTerms = [[NSMutableDictionary alloc] initWithCapacity:[variableNames count]];
  [variableNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
    NSNumber * coefficient = [variableCoefficients objectAtIndex:idx];
    NSNumber * existingCoefficient = [variableTerms objectForKey:obj];
    if (existingCoefficient != nil)
    {
      coefficient = @( [existingCoefficient doubleValue] + [coefficient doubleValue] );
    }
    
    [variableTerms setObject:coefficient
                      forKey:obj];
  }];
  
  return [self initWithConstantValue:constantValue
                       variableTerms:variableTerms];
}

- (id)initWithConstantValue:(CGFloat)constantValue
              variableTerms:(NSDictionary *)variableTerms
{
  self = [super init];
  if (self != nil)
  {
    _constantValue = constantValue;
    _variableTerms = variableTerms;
  }
  return self;
}

+ (instancetype)expressionWithConstantValue:(CGFloat)constantValue
{
  return [[self alloc] initWithConstantValue:constantValue];
}

+ (instancetype)expressionWithConstantValue:(CGFloat)constantValue
                              variableNames:(NSArray *)variableNames
                       variableCoefficients:(NSArray *)variableCoefficients
{
  return [[self alloc] initWithConstantValue:constantValue
                               variableNames:variableNames
                        variableCoefficients:variableCoefficients];
}

static NSString *
NSStringForResultGroup(NSString * string, NSTextCheckingResult * result, NSUInteger captureGroupIndex)
{
  NSRange range = [result rangeAtIndex:captureGroupIndex];
  if (range.location == NSNotFound) return nil;
  
  return [string substringWithRange:range];
}

+ (instancetype)expressionFromString:(NSString *)expressionString
                               error:(NSError * __autoreleasing *)error
{
  static NSString * termPattern = @"\\s*"
                                   "([+-])?"
                                   "\\s*"
                                   "("
                                      "("
                                        "(\\d+(?:\\.\\d+)?)"
                                        "(?:\\s*\\*\\s*)?"
                                        "([a-zA-Z]+)?"
                                      ")"
                                      "|"
                                      "([a-zA-Z]+)"
                                    ")"
                                    "\\s*";
  
  static NSRegularExpression * termExpression = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSError * error = nil;
    termExpression = [NSRegularExpression regularExpressionWithPattern:termPattern
                                                               options:0
                                                                 error:&error];
    NSAssert(termExpression != nil,
             @"Failed to parse expression pattern: %@",
             [error localizedDescription]);
  });
  
  NSMutableArray * variableNames = [[NSMutableArray alloc] init];
  NSMutableArray * variableCoefficients = [[NSMutableArray alloc] init];
  CGFloat constantValue = 0.0f;
  
  NSUInteger currentOffset = 0;
  while (currentOffset < [expressionString length])
  {
    // read the next term
    NSTextCheckingResult * match = [termExpression firstMatchInString:expressionString
                                                              options:0
                                                                range:NSMakeRange(currentOffset, [expressionString length]-currentOffset)];
    
    if (match == nil || match.range.location != currentOffset)
    {
      if (error != NULL)
      {
        NSString * unexpectedString = [expressionString substringFromIndex:currentOffset];
        NSString * localizedString = [NSString stringWithFormat:@"Encountered unexpected text in linear expression: %@", unexpectedString];
        *error = [NSError errorWithDomain:VPLLinearExpressionErrorDomain
                                     code:VPLLinearExpressionParseError
                                 userInfo:@{ NSLocalizedDescriptionKey : localizedString }];
      }
      return nil;
    }
    
    NSString * signString                   = NSStringForResultGroup(expressionString, match, 1);
    NSString * constantOrCoefficientString  = NSStringForResultGroup(expressionString, match, 4);
    NSString * coefficientVariableName      = NSStringForResultGroup(expressionString, match, 5);
    NSString * nakedVariableName            = NSStringForResultGroup(expressionString, match, 6);
    
    // process any sign symbol
    CGFloat constantOrCoefficientValue = 1.0;
    if (signString != nil)
    {
      if ([signString isEqualToString:@"-"])
      {
        constantOrCoefficientValue = -1.0;
      }
    }
    
    // process the contant or coefficient
    if (constantOrCoefficientString != nil)
    {
      constantOrCoefficientValue *= [constantOrCoefficientString doubleValue];
    }
    
    // process the variable name
    NSString * variableName = (coefficientVariableName != nil ? coefficientVariableName : nakedVariableName);
    if (variableName != nil)
    {
      NSUInteger variableIndex = [variableNames indexOfObject:variableName];
      if (variableIndex == NSNotFound)
      {
        [variableNames addObject:variableName];
        [variableCoefficients addObject:@(constantOrCoefficientValue)];
      }
      else
      {
        // add the coefficients
        NSNumber * variableCoefficient = variableCoefficients[variableIndex];
        CGFloat combinedCoefficient = [variableCoefficient doubleValue] + constantOrCoefficientValue;
        variableCoefficients[variableIndex] = @(combinedCoefficient);
      }
    }
    else
    {
      constantValue += constantOrCoefficientValue;
    }
    
    currentOffset = match.range.location + match.range.length;
  }

  return [[VPLLinearExpression alloc] initWithConstantValue:constantValue
                                             variableNames:variableNames
                                      variableCoefficients:variableCoefficients];
}

// ===== EQUALITY ======================================================================================================
#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
  if (object == self) return YES;
  if (object == nil) return NO;
  if (![object isKindOfClass:[VPLLinearExpression class]]) return NO;

  return [self isEqualToExpression:object];
}

- (BOOL)isEqualToExpression:(VPLLinearExpression *)otherExpression
{
  if (otherExpression == self) return YES;
  if (otherExpression == nil) return NO;
  
  if (self.constantValue != otherExpression.constantValue) return NO;
  if (![self.variableTerms isEqualToDictionary:otherExpression.variableTerms]) return NO;
  
  return YES;
}

- (NSUInteger)hash
{
  NSUInteger result = 1;
  NSUInteger prime = 31;
  
  result = prime * result + [self.variableTerms hash];
  
  return result;
}

// ===== NSCopying =====================================================================================================
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

// ===== NSObject ======================================================================================================
#pragma mark - NSObject

- (NSString *)description
{
  NSMutableString * description = [[NSMutableString alloc] init];
  if (self.constantValue != 0.0 || [self isConstant])
  {
    [description appendFormat:@"%f", self.constantValue];
  }
  
  if ([self isParametric])
  {
    [self.variableTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      
      NSString * variableName = key;
      CGFloat variableCoefficient = (CGFLOAT_IS_DOUBLE ? [obj doubleValue] : [obj floatValue]);
      
      if ([description length] > 0)
      {
        if (variableCoefficient < 0)
        {
          [description appendString:@" - "];
          variableCoefficient = -(variableCoefficient);
        }
        else
        {
          [description appendString:@" + "];
        }
      }
      
      if (variableCoefficient == 1.0)
      {
        [description appendFormat:@"%@", variableName];
      }
      else
      {
        [description appendFormat:@"%f%@", variableCoefficient, variableName];
      }
      
    }];
  }

  return description;
}

// ===== CONSTANT VALUE ================================================================================================
#pragma mark - Constant Value

- (BOOL)isConstant
{
  return ![self isParametric];
}

// ===== VARIABLES =====================================================================================================
#pragma mark - Variables

- (BOOL)isParametric
{
  return [self.variableTerms count] > 0;
}

- (BOOL)containsVariable:(NSString *)variableName
{
  return [self.variableTerms objectForKey:variableName] != nil;
}

- (CGFloat)coefficientForVariable:(NSString *)variableName
{
  NSNumber * number = self.variableTerms[variableName];
  if (CGFLOAT_IS_DOUBLE)
  {
    return [number doubleValue];
  }
  else
  {
    return [number floatValue];
  }
}

- (NSArray *)unrestrictedVariableNames
{
  return [self variableNamesPassingTest:^BOOL(NSString *variableName, NSNumber *coefficient, BOOL *stop) {
    
    return VPLLinearExpressionVariableIsUnrestricted(variableName);
    
  }];
}

- (NSArray *)variableNamesPassingTest:(BOOL(^)(NSString *, NSNumber *, BOOL *))block
{
  NSMutableArray * variableNames = [[NSMutableArray alloc] init];
  [self.variableTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    BOOL matched = block(key, obj, stop);
    if (matched)
    {
      [variableNames addObject:key];
    }
    
  }];
  
  [variableNames sortUsingSelector:@selector(compare:)];
  return variableNames;
}

// ===== OPERATIONS ====================================================================================================
#pragma mark - Operations

- (VPLLinearExpression *)expressionByNegatingExpression
{
  return [self expressionByMultiplying:-1.0];
}

- (VPLLinearExpression *)expressionByMultiplying:(CGFloat)multiplier
{
  if (multiplier == 1.0) return self;
  if ([self isConstant] && self.constantValue == 0.0) return self;
  if (multiplier == 0.0) return [[[self class] alloc] initWithConstantValue:0];
  
  CGFloat multipliedConstant = self.constantValue * multiplier;

  NSMutableDictionary * multipliedTerms = [[NSMutableDictionary alloc] initWithCapacity:[self.variableTerms count]];
  [self.variableTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    CGFloat multipliedCoefficient = CGFloatFromObjectValue(obj) * multiplier;
    if (multipliedCoefficient != 0.0)
    {
      [multipliedTerms setObject:@(multipliedCoefficient)
                          forKey:key];
    }
    
  }];
  
  return [[[self class] alloc] initWithConstantValue:multipliedConstant
                                       variableTerms:multipliedTerms];
  
}

+ (NSMutableDictionary *)combineTerms:(NSDictionary *)terms
                            withTerms:(NSDictionary *)otherTerms
{
  NSMutableDictionary * combinedTerms = [[NSMutableDictionary alloc] initWithDictionary:terms];
  [otherTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    NSNumber * coeffNumber = [terms objectForKey:key];
    if (coeffNumber == nil)
    {
      combinedTerms[key] = obj;
    }
    else
    {
      CGFloat combinedCoeff = CGFloatFromObjectValue(coeffNumber) + CGFloatFromObjectValue(obj);
      if (combinedCoeff == 0.0)
      {
        [combinedTerms removeObjectForKey:key];
      }
      else
      {
        combinedTerms[key] = @(combinedCoeff);
      }
    }
  }];
  
  return combinedTerms;
}

- (VPLLinearExpression *)expressionBySubstitutingExpression:(VPLLinearExpression *)expression
                                               forVariable:(NSString *)variableName
{
  CGFloat coeff = [self coefficientForVariable:variableName];
  if (coeff != 0.0)
  {
    VPLLinearExpression * multipliedExpression = [expression expressionByMultiplying:coeff];
    NSMutableDictionary * combinedTerms = [[self class] combineTerms:self.variableTerms
                                                           withTerms:multipliedExpression.variableTerms];
    [combinedTerms removeObjectForKey:variableName];
    
    return [[[self class] alloc] initWithConstantValue:self.constantValue + multipliedExpression.constantValue
                                         variableTerms:combinedTerms];
    
  }
  else
  {
    return self;
  }
}

- (VPLLinearExpression *)expressionBySolvingForVariable:(NSString *)solvedVariableName
{
  NSAssert([self containsVariable:solvedVariableName],
           @"[%@ %@] Cannot solve '%@' for unknown variable '%@'",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           self,
           solvedVariableName);
  
  CGFloat solvedVariableCoefficient = [self coefficientForVariable:solvedVariableName];
  
  NSMutableDictionary * solvedTerms = [[NSMutableDictionary alloc] initWithCapacity:[self.variableTerms count]-1];
  [self.variableTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    NSString * variableName = key;
    if ([variableName isEqualToString:solvedVariableName] == NO)
    {
      CGFloat variableCoefficient = CGFloatFromObjectValue(obj);
      [solvedTerms setObject:@(-(variableCoefficient / solvedVariableCoefficient))
                      forKey:variableName];
    }
    
  }];
  
  CGFloat solvedConstantValue = -(self.constantValue / solvedVariableCoefficient);
  return [[[self class] alloc] initWithConstantValue:solvedConstantValue
                                       variableTerms:solvedTerms];
}

- (VPLLinearExpression *)expressionByChangingSubjectFromVariable:(NSString *)currentSubject
                                                     toVariable:(NSString *)updatedSubject
{
  // updatedSubject = (1/cI)*currentSubject - (constant/cI) - (c1/cI)v1 + ... + (cN / cI)vN
  
  NSAssert([self containsVariable:updatedSubject],
           @"[%@ %@] destination subject (%@) must be in expression: %@",
           NSStringFromClass([self class]),
           NSStringFromSelector(_cmd),
           updatedSubject,
           self);
  
  CGFloat updatedSubjectCoeff = [self coefficientForVariable:updatedSubject];
  
  NSMutableDictionary * exchangedTerms = [[NSMutableDictionary alloc] initWithCapacity:[self.variableTerms count]];
  exchangedTerms[currentSubject] = @(1 / updatedSubjectCoeff);
  
  [self.variableTerms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    
    NSString * variableName = key;
    if (NO == [variableName isEqualToString:updatedSubject])
    {
      CGFloat variableCoeff = CGFloatFromObjectValue(obj);
      exchangedTerms[variableName] = @(-(variableCoeff / updatedSubjectCoeff));
    }
    
  }];
  
  CGFloat updatedConstant = -(self.constantValue / updatedSubjectCoeff);
  
  return [[[self class] alloc] initWithConstantValue:updatedConstant
                                       variableTerms:exchangedTerms];
}


- (VPLLinearExpression *)expressionByRemovingVariableTerm:(NSString *)variableName
{
  if (self.variableTerms[variableName] == nil) return self;
  
  NSMutableDictionary * variableTerms = [[NSMutableDictionary alloc] initWithDictionary:self.variableTerms];
  [variableTerms removeObjectForKey:variableName];
  
  return [[[self class] alloc] initWithConstantValue:self.constantValue
                                       variableTerms:variableTerms];
}

@end
