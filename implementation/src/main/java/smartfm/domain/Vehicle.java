package smartfm.domain;

import java.io.Serializable;
import smartfm.common.Validators;

/**
 * A commercial delivery vehicle owned by ABC-Trans and managed by a
 * local branch. Corresponds to the {@code Vehicle} CRC card in
 * Assignment 2 Section 3 (Fleet and Resources Package).
 */
public class Vehicle implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private String licensePlate;
  private String make;
  private String cargoType;
  private double maxWeightCapacityKg;
  private double maxVolumeCapacityM3;
  private VehicleStatus status;
  private String branchId;

  public Vehicle(
      String id,
      String licensePlate,
      String make,
      String cargoType,
      double maxWeightCapacityKg,
      double maxVolumeCapacityM3,
      String branchId) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.licensePlate = Validators.requireNonBlank(licensePlate, "License plate", 15);
    this.make = Validators.requireNonBlank(make, "Make", 40);
    this.cargoType = Validators.requireNonBlank(cargoType, "Cargo type", 40);
    this.maxWeightCapacityKg = Validators.requirePositive(maxWeightCapacityKg, "Max weight capacity");
    this.maxVolumeCapacityM3 = Validators.requirePositive(maxVolumeCapacityM3, "Max volume capacity");
    this.branchId = Validators.requireNonBlank(branchId, "Branch id", 20);
    this.status = VehicleStatus.AVAILABLE;
  }

  public String getId() {
    return id;
  }

  public String getLicensePlate() {
    return licensePlate;
  }

  public String getMake() {
    return make;
  }

  public String getCargoType() {
    return cargoType;
  }

  public double getMaxWeightCapacityKg() {
    return maxWeightCapacityKg;
  }

  public double getMaxVolumeCapacityM3() {
    return maxVolumeCapacityM3;
  }

  public VehicleStatus getStatus() {
    return status;
  }

  public void setStatus(VehicleStatus status) {
    this.status = status;
  }

  public boolean isAvailable() {
    return status == VehicleStatus.AVAILABLE;
  }

  public String getBranchId() {
    return branchId;
  }

  /** Validates a candidate consignment against this vehicle's payload limits. */
  public boolean canCarry(double weightKg, double volumeM3) {
    return weightKg <= maxWeightCapacityKg && volumeM3 <= maxVolumeCapacityM3;
  }

  @Override
  public String toString() {
    return licensePlate + " (" + cargoType + ", " + status + ")";
  }
}
