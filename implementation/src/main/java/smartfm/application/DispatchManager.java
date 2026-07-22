package smartfm.application;

import java.util.ArrayList;
import java.util.List;
import smartfm.common.InvalidDataException;
import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;
import smartfm.infrastructure.DataStore;

/**
 * Coordinating controller managing vehicle and driver assignment for
 * approved orders. Corresponds to the {@code DispatchManager} CRC card
 * in Assignment 2 Section 3 (System Control and Configuration Package).
 * Implements {@link OrderApprovedListener} to react to order approvals
 * (Observer pattern) and acts as the Factory Method for {@code
 * Shipment} (Assignment 2 Section 5.1.1).
 *
 * <p>This is one of the four controllers implemented for Assignment 3's
 * "Business Area 2: Fleet Dispatch". Depends on Business Area 1 (an
 * order must already be Approved before a shipment can be created;
 * Assumption A6), which is the "dependency between implemented areas"
 * the Assignment 3 brief asks groups to consider explicitly.
 */
public class DispatchManager implements OrderApprovedListener {

  private final DataStore store;
  private final IdGenerator shipmentIds;
  private final List<ShipmentAssignedListener> shipmentAssignedListeners = new ArrayList<>();

  public DispatchManager(DataStore store) {
    this.store = store;
    this.shipmentIds = new IdGenerator("SHP", store.shipments());
  }

  /** Registered by ShipmentTracker during bootstrap (Observer pattern). */
  public void addShipmentAssignedListener(ShipmentAssignedListener listener) {
    shipmentAssignedListeners.add(listener);
  }

  /**
   * Reacts to the order-approved event: this default implementation
   * does not auto-dispatch, since real dispatch requires an explicit
   * vehicle/driver choice made through {@link #assignShipment}. Kept as
   * a no-op override to document the Observer wiring described in
   * Assignment 2 Section 6 (bootstrap), Step 6.
   */
  @Override
  public void onOrderApproved(Order order) {
    // Intentionally left for the dispatcher to act on via assignShipment();
    // logged by the CLI so the observer notification is visible to the user.
  }

  /** Returns vehicles at {@code branchId} that are AVAILABLE and can carry the given cargo. */
  public List<Vehicle> findAvailableVehicles(String branchId, double weightKg, double volumeM3) {
    List<Vehicle> candidates = new ArrayList<>();
    for (Vehicle vehicle : store.vehicles().values()) {
      if (vehicle.getBranchId().equals(branchId)
          && vehicle.isAvailable()
          && vehicle.canCarry(weightKg, volumeM3)) {
        candidates.add(vehicle);
      }
    }
    return candidates;
  }

  /** Returns drivers at {@code branchId} who are currently AVAILABLE. */
  public List<Driver> findAvailableDrivers(String branchId) {
    List<Driver> candidates = new ArrayList<>();
    for (Driver driver : store.drivers().values()) {
      if (driver.getHomeBranchId().equals(branchId) && driver.isAvailable() && driver.isLicenseValid()) {
        candidates.add(driver);
      }
    }
    return candidates;
  }

  /**
   * Step 3-6 of Scenario 2: binds a chosen vehicle and driver to an
   * approved order and creates the {@code Shipment} (Factory Method).
   */
  public Shipment assignShipment(String orderId, String vehicleId, String driverId) {
    Order order = store.orders().get(orderId);
    if (order == null) {
      throw new InvalidDataException("Unknown order id '" + orderId + "'.");
    }
    if (!order.isApproved()) {
      throw new InvalidDataException(
          "Order " + orderId + " must be Approved before a shipment can be created (currently "
              + order.getStateName() + ").");
    }
    Vehicle vehicle = store.vehicles().get(vehicleId);
    Driver driver = store.drivers().get(driverId);
    if (vehicle == null) {
      throw new InvalidDataException("Unknown vehicle id '" + vehicleId + "'.");
    }
    if (driver == null) {
      throw new InvalidDataException("Unknown driver id '" + driverId + "'.");
    }
    if (!vehicle.isAvailable()) {
      throw new InvalidDataException("Vehicle " + vehicleId + " is not available.");
    }
    if (!driver.isAvailable()) {
      throw new InvalidDataException("Driver " + driverId + " is not available.");
    }
    if (!vehicle.canCarry(order.getTotalWeightKg(), 0)) {
      throw new InvalidDataException(
          "Vehicle " + vehicleId + " cannot carry the order's total weight of "
              + order.getTotalWeightKg() + "kg.");
    }

    Shipment shipment = new Shipment(shipmentIds.next(), order.getId(), vehicleId, driverId);
    store.shipments().put(shipment.getId(), shipment);

    vehicle.setStatus(VehicleStatus.DISPATCHED);
    driver.setDutyState(DutyState.DISPATCHED);

    Branch branch = store.branches().get(order.getOriginBranchId());
    if (branch == null) {
      throw new InvalidDataException("Unknown origin branch id '" + order.getOriginBranchId() + "'.");
    }

    for (ShipmentAssignedListener listener : shipmentAssignedListeners) {
      listener.onShipmentAssigned(shipment);
    }
    return shipment;
  }
}
