#import "VPLCassowaryTypes.h"

@class VPLConstraint;
@class VPLTableau;

@interface VPLConstraintSet : NSObject

// ===== TABLEAU =======================================================================================================
#pragma mark - Tableau

@property (nonatomic, strong, readonly) VPLTableau * tableau;

// ===== CONSTRAINTS ===================================================================================================
#pragma mark - Constraints

- (BOOL)containsConstraint:(VPLConstraint *)constraint;

// ===== ADD CONSTRAINTS ===============================================================================================
#pragma mark - Add Constraints

- (void)addConstraint:(VPLConstraint *)constraint;

// ===== REMOVE CONSTRAINTS ============================================================================================
#pragma mark - Remove Constraints

- (void)removeConstraint:(VPLConstraint *)constraint;

@end
