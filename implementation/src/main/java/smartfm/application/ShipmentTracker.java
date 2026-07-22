package smartfm.application;

import java.util.HashMap;
import java.util.Map;
import smartfm.common.InvalidDataException;
import smartfm.domain.Driver;
import smartfm.domain.DutyState;
import smartfm.domain.ITelemetrySource;
import smartfm.domain.Shipment;
import smartfm.domain.Vehicle;
import smartfm.domain.VehicleStatus;
import smartfm.infrastructure.DataStore;

/**
 * Coordinating controller managing real-time transit milestone updates.
 * Corresponds to the {@code ShipmentTracker} CRC card in Assignment 2
 * Section 3 (System Control and Configuration Package). Implements
 * {@link ShipmentAssignedListener} to react to new shipments (Observer
 * pattern) and consumes location data through an {@link
 * ITelemetrySource} adapter (Adapter pattern, Assignment 2 Section
 * 5.3.2) so it never depends on a specific GPS vendor protocol.
 *
 * <p>This is one of the four controllers implemented for Assignment 3's
 * "Business Area 3: Shipment Tracking". Depends on Business Area 2
 * (a shipment must already exist and have an assigned vehicle/driver).
 */
public class ShipmentTracker implements ShipmentAssignedListener {

  private final DataStore store;
  private final ITelemetrySource telemetrySource;
  private final Map<String, Shipment> activeShipments = new HashMap<>();

  public ShipmentTracker(DataStore store, ITelemetrySource telemetrySource) {
    this.store = store;
    this.telemetrySource = telemetrySource;
  }

  @Override
  public void onShipmentAssigned(Shipment shipment) {
    activeShipments.put(shipment.getId(), shipment);
  }

  private Shipment requireTrackedShipment(String shipmentId) {
    Shipment shipment = store.shipments().get(shipmentId);
    if (shipment == null) {
      throw new InvalidDataException("Unknown shipment id '" + shipmentId + "'.");
    }
    return shipment;
  }

  /** Step 1-3 of Scenario 3: confirm pickup and advance to Picked Up. */
  public void confirmPickup(String shipmentId, String location) {
    Shipment shipment = requireTrackedShipment(shipmentId);
    shipment.pickUp();
    applyTelemetry(shipment, location);
  }

  /** Advance an already-picked-up shipment to In Transit. */
  public void confirmInTransit(String shipmentId, String location) {
    Shipment shipment = requireTrackedShipment(shipmentId);
    shipment.transit();
    applyTelemetry(shipment, location);
  }

  /** Step 3-5 of Scenario 4 (asm2) equivalent: confirm final delivery. */
  public void confirmDelivery(String shipmentId, String location) {
    Shipment shipment = requireTrackedShipment(shipmentId);
    shipment.deliver();
    applyTelemetry(shipment, location);

    // Release the vehicle and driver back to the available pool.
    Vehicle vehicle = store.vehicles().get(shipment.getVehicleId());
    if (vehicle != null) {
      vehicle.setStatus(VehicleStatus.AVAILABLE);
    }
    Driver driver = store.drivers().get(shipment.getDriverId());
    if (driver != null) {
      driver.setDutyState(DutyState.AVAILABLE);
    }
    activeShipments.remove(shipment.getId());
  }

  private void applyTelemetry(Shipment shipment, String rawLocation) {
    String normalised = telemetrySource.readLocation(shipment.getId());
    // Prefer the caller-supplied location if the adapter has nothing staged.
    shipment.updateLocation(normalised != null && !normalised.equals("Unknown")
        ? normalised : rawLocation);
  }

  public Shipment getStatus(String shipmentId) {
    return requireTrackedShipment(shipmentId);
  }
}
