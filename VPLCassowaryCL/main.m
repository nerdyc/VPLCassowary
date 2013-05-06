#import "VPLCassowaryCL.h"

int main(int argc, const char * argv[])
{
  int exitCode = 0;
  
  @autoreleasepool
  {
    NSError * error = nil;
    
    VPLCassowaryCL * cl = [[VPLCassowaryCL alloc] init];
    if (![cl perform:&error])
    {
      NSLog(@"Error: %@", [error localizedDescription]);
      exitCode = -1;
      
      NSString * prefix = @"  ";
      NSError * underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
      while (underlyingError != nil)
      {
        NSString * localizedDescription = [underlyingError localizedDescription];
        NSString * localizedRecovery = [underlyingError description];
        
        NSLog(@"%@->: %@", prefix, localizedDescription);
        NSLog(@"%@  : %@", prefix, localizedRecovery);
        
        prefix = [prefix stringByAppendingString:prefix];
        underlyingError = [underlyingError.userInfo objectForKey:NSUnderlyingErrorKey];
      }
    }
  }
  
  return exitCode;
}

