package smartfm.domain.fleet;

import java.time.LocalDate;
import smartfm.common.InvalidDataException;
import smartfm.common.Validators;

/**
 * A licensed driver employed by ABC-Trans and assigned to a home branch.
 * Subclass of {@link StaffMember} (Assignment 2 Simplification #1: Driver
 * remains distinct because of unique operational attributes).
 */
public class Driver extends StaffMember {

  private static final long serialVersionUID = 1L;

  private String licenseNumber;
  private LocalDate licenseExpiry;
  private DutyState dutyState;
  private double cumulativeShiftHours;

  public Driver(
      String id,
      String fullName,
      String gender,
      LocalDate dateOfBirth,
      String phone,
      String email,
      String address,
      String homeBranchId,
      String licenseNumber,
      LocalDate licenseExpiry) {
    super(id, fullName, gender, dateOfBirth, phone, email, address, StaffRole.DRIVER, homeBranchId);
    this.licenseNumber = Validators.requireNonBlank(licenseNumber, "License number", 20);
    this.licenseExpiry = licenseExpiry;
    this.dutyState = DutyState.OFF_DUTY;
    this.cumulativeShiftHours = 0.0;
  }

  public String getLicenseNumber() {
    return licenseNumber;
  }

  public LocalDate getLicenseExpiry() {
    return licenseExpiry;
  }

  public boolean isLicenseValid() {
    return licenseExpiry != null && !licenseExpiry.isBefore(LocalDate.now());
  }

  public DutyState getDutyState() {
    return dutyState;
  }

  public void setDutyState(DutyState dutyState) {
    this.dutyState = dutyState;
  }

  public boolean isAvailable() {
    return dutyState == DutyState.AVAILABLE;
  }

  public double getCumulativeShiftHours() {
    return cumulativeShiftHours;
  }

  /** Tracks and records cumulative driving duration, per the CRC card responsibility. */
  public void addShiftHours(double hours) {
    if (hours < 0) {
      throw new InvalidDataException("Shift hours cannot be negative.");
    }
    this.cumulativeShiftHours += hours;
  }
}
