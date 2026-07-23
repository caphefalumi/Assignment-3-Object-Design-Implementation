package smartfm.domain.shipment;

import java.io.Serializable;
import java.time.LocalDateTime;
import smartfm.common.InvalidDataException;
import smartfm.common.Validators;

/**
 * The physical execution of an approved {@link Order}: manages the
 * assigned vehicle, driver, and transit milestone state. Corresponds to
 * the {@code Shipment} CRC card in Assignment 2 Section 3 (Commercial
 * and Ordering Package). Delegates lifecycle transitions to a {@link
 * ShipmentState} instance (State pattern, Assignment 2 Section 5.2.3).
 */
public class Shipment implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String orderId;
  private final String vehicleId;
  private final String driverId;
  private final LocalDateTime createdAt;
  private ShipmentState state;
  private String lastKnownLocation;

  public Shipment(String id, String orderId, String vehicleId, String driverId) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.orderId = Validators.requireNonBlank(orderId, "Order id", 20);
    this.vehicleId = Validators.requireNonBlank(vehicleId, "Vehicle id", 20);
    this.driverId = Validators.requireNonBlank(driverId, "Driver id", 20);
    this.createdAt = LocalDateTime.now();
    this.state = new ShipmentAssignedState();
    this.lastKnownLocation = "Origin branch (not yet departed)";
  }

  public String getId() {
    return id;
  }

  public String getOrderId() {
    return orderId;
  }

  public String getVehicleId() {
    return vehicleId;
  }

  public String getDriverId() {
    return driverId;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public String getStateName() {
    return state.name();
  }

  /** Package-visible mutator used exclusively by {@link ShipmentState} subclasses. */
  void setState(ShipmentState state) {
    this.state = state;
  }

  public void pickUp() {
    state.pickUp(this);
  }

  public void transit() {
    state.transit(this);
  }

  public void deliver() {
    state.deliver(this);
  }

  /** Restores a lifecycle state read by the normalized persistence gateway. */
  public void restoreState(String persistedState) {
    if (persistedState == null || persistedState.equals("Assigned")) {
      state = new ShipmentAssignedState();
    } else if (persistedState.equals("Picked Up")) {
      state = new ShipmentPickedUpState();
    } else if (persistedState.equals("In Transit")) {
      state = new ShipmentInTransitState();
    } else if (persistedState.equals("Delivered")) {
      state = new ShipmentDeliveredState();
    } else {
      throw new InvalidDataException("Unknown persisted shipment state: " + persistedState);
    }
  }

  public boolean isDelivered() {
    return state instanceof ShipmentDeliveredState;
  }

  public String getLastKnownLocation() {
    return lastKnownLocation;
  }

  /** Called by ShipmentTracker after normalising a telemetry update. */
  public void updateLocation(String location) {
    this.lastKnownLocation = Validators.requireNonBlank(location, "Location", 120);
  }

  @Override
  public String toString() {
    return "Shipment " + id + " [" + state.name() + "] @ " + lastKnownLocation;
  }
}
