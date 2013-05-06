#import "Specta.h"

#define EXP_SHORTHAND
#import "Expecta.h"

#define RAISE_SPEC_ERROR(__error__, __message__) NSAssert(__error__ == nil, @"%@: %@", __message__, [__error__ localizedDescription]);

#import "VPLLinearExpression+SpecHelper.h"