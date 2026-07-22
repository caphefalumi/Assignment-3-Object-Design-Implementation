package smartfm.domain.fleet;

/**
 * Role-based access control classification for a {@link StaffMember}.
 * Assignment 2 Simplification #1: back-office roles are represented as
 * an attribute on a single StaffMember class rather than as five
 * near-empty subclasses.
 */
public enum StaffRole {
  DISPATCHER,
  BRANCH_MANAGER,
  FLEET_ADMINISTRATOR,
  HR_STAFF,
  SYSTEM_ADMINISTRATOR,
  DRIVER
}
