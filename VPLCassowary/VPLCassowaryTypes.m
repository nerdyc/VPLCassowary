#import "VPLCassowaryTypes.h"

NSString * const VPLCassowaryErrorDomain = @"com.vulpinelabs.VPLCassowary";

CGFloat
CGFloatFromObject(id object)
{
  return (CGFLOAT_IS_DOUBLE ? [object doubleValue] : [object floatValue]);
}

CGFloat
CGFloatFromObjectWithDefault(id object, CGFloat defaultValue)
{
  if (object != nil)
  {
    return (CGFLOAT_IS_DOUBLE ? [object doubleValue] : [object floatValue]);
  }
  else
  {
    return defaultValue;
  }
}