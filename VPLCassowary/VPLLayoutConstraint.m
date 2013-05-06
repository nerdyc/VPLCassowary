#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLLayoutConstraint.h"
#import "VPLConstraint.h"

static NSString *
VPLLayoutConstraintVariableNameWithIdentifierAndAttribute(NSString * identifier, NSString * attribute)
{
  return [NSString stringWithFormat:@"%@.%@", identifier, attribute];
}

@implementation VPLLayoutConstraint

// ===== INITIALIZATION ================================================================================================
#pragma mark - Initialization

- (id)initWithSubject:(NSString *)subject
            attribute:(NSString *)attribute
         relationship:(NSString *)relationship
        relatedObject:(NSString *)relatedObject
     relatedAttribute:(NSString *)relatedAttribute
           multiplier:(CGFloat)relatedAttributeMultiplier
             constant:(CGFloat)relatedAttributeConstant
{
  self = [super init];
  if (self != nil)
  {
    _subject = subject;
    _attribute = attribute;
    _relationship = relationship;
    _relatedObject = relatedObject;
    _relatedObjectAttribute = relatedAttribute;
    _relatedObjectAttributeMultiplier = relatedAttributeMultiplier;
    _relatedObjectAttributeOffset = relatedAttributeConstant;
    
  }
  return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
  return [self initWithSubject:dictionary[@"subject"]
                     attribute:dictionary[@"attribute"]
                  relationship:dictionary[@"relationship"]
                 relatedObject:dictionary[@"relatedObject"]
              relatedAttribute:dictionary[@"relatedAttribute"]
                    multiplier:CGFloatFromObjectWithDefault(dictionary[@"relatedAttributeMultiplier"], 1.0f)
                      constant:CGFloatFromObjectWithDefault(dictionary[@"relatedAttributeConstant"], 0.0f)];
}

// ===== CONSTRAINT ====================================================================================================
#pragma mark - Constraint

@synthesize constraint = _constraint;

- (VPLConstraint *)constraint
{
  if (_constraint == nil)
  {
    // subject variable
    NSString * subjectVariable = VPLLayoutConstraintVariableNameWithIdentifierAndAttribute(self.subject,
                                                                                          self.attribute);
    
    // relation
    VPLConstraintRelation relation = VPLConstraintRelationEqual;
    if ([self.relationship isEqualToString:@">="])
    {
      relation = VPLConstraintRelationGreaterThanOrEqual;
    }
    else if ([self.relationship isEqualToString:@"<="])
    {
      relation = VPLConstraintRelationLessThanOrEqual;
    }
    
    // subject variable
    NSString * objectVariable =
      VPLLayoutConstraintVariableNameWithIdentifierAndAttribute(self.relatedObject,
                                                               self.relatedObjectAttribute);
    
    _constraint = [VPLConstraint constraintWithVariable:subjectVariable
                                             relatedBy:relation
                                            toVariable:objectVariable
                                            multiplier:self.relatedObjectAttributeMultiplier
                                              constant:self.relatedObjectAttributeOffset];
  }
  
  return _constraint;
}

@end
