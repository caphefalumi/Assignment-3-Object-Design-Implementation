package smartfm.domain;

import java.time.LocalDate;
import smartfm.common.Validators;

/**
 * An authenticated internal employee of ABC-Trans with role-based system
 * credentials. Corresponds to the {@code StaffMember} CRC card in
 * Assignment 2 Section 3 (Personnel and Administration Package).
 */
public class StaffMember extends Person {

  private static final long serialVersionUID = 1L;

  private StaffRole role;
  private String homeBranchId;

  public StaffMember(
      String id,
      String fullName,
      String gender,
      LocalDate dateOfBirth,
      String phone,
      String email,
      String address,
      StaffRole role,
      String homeBranchId) {
    super(id, fullName, gender, dateOfBirth, phone, email, address);
    this.role = role;
    this.homeBranchId = Validators.requireNonBlank(homeBranchId, "Home branch id", 20);
  }

  public StaffRole getRole() {
    return role;
  }

  public void setRole(StaffRole role) {
    this.role = role;
  }

  public String getHomeBranchId() {
    return homeBranchId;
  }

  public void setHomeBranchId(String homeBranchId) {
    this.homeBranchId = Validators.requireNonBlank(homeBranchId, "Home branch id", 20);
  }

  /** RBAC check used by controllers before running a privileged operation. */
  public boolean hasRole(StaffRole required) {
    return this.role == required;
  }
}
