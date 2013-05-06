#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "VPLLinearExpression+SpecHelper.h"
#import "VPLSpecHelper.h"

@implementation VPLLinearExpression (SpecHelper)

+ (instancetype)expressionFromString:(NSString *)expressionString
{
  NSError * error = nil;
  VPLLinearExpression * expr = [self expressionFromString:expressionString
                                                   error:&error];
  if (expr == nil)
  {
    RAISE_SPEC_ERROR(error, @"Error creating linear expression");
  }
  return expr;
}
@end
