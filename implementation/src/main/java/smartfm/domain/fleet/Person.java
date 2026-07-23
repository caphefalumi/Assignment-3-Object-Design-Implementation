package smartfm.domain.fleet;

import java.io.Serializable;
import java.time.LocalDate;
import smartfm.common.Validators;

/**
 * Abstract base class holding demographic and contact details shared by
 * every human entity in the system ({@link Customer} and {@link
 * StaffMember}). Mirrors the {@code Person} CRC card from Assignment 2
 * Section 3 (Personnel and Administration Package).
 */
public abstract class Person implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private String fullName;
  private String gender;
  private LocalDate dateOfBirth;
  private String phone;
  private String email;
  private String address;

  protected Person(
      String id,
      String fullName,
      String gender,
      LocalDate dateOfBirth,
      String phone,
      String email,
      String address) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    setFullName(fullName);
    this.gender = gender == null ? "" : gender.trim();
    this.dateOfBirth = dateOfBirth;
    setPhone(phone);
    setEmail(email);
    setAddress(address);
  }

  public final String getId() {
    return id;
  }

  public String getFullName() {
    return fullName;
  }

  public final void setFullName(String fullName) {
    this.fullName = Validators.requireNonBlank(fullName, "Full name", 80);
  }

  public String getGender() {
    return gender;
  }

  public LocalDate getDateOfBirth() {
    return dateOfBirth;
  }

  public String getPhone() {
    return phone;
  }

  public final void setPhone(String phone) {
    this.phone = Validators.requirePhone(phone, "Phone number");
  }

  public String getEmail() {
    return email;
  }

  public final void setEmail(String email) {
    this.email = Validators.requireEmail(email, "Email");
  }

  public String getAddress() {
    return address;
  }

  public final void setAddress(String address) {
    this.address = Validators.requireNonBlank(address, "Address", 160);
  }

  @Override
  public String toString() {
    return fullName + " (" + id + ")";
  }
}
