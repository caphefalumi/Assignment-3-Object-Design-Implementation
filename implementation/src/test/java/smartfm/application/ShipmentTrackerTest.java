package smartfm.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.shipment.ManualTelemetrySource;
import smartfm.domain.shipment.Shipment;
import smartfm.infrastructure.DataStore;

@DisplayName("ShipmentTracker Application Controller Tests")
class ShipmentTrackerTest {

  private DataStore store;
  private ManualTelemetrySource telemetrySource;
  private ShipmentTracker tracker;
  private Shipment shipment;
  private Vehicle vehicle;
  private Driver driver;

  @BeforeEach
  void setUp() {
    store = new DataStore();
    telemetrySource = new ManualTelemetrySource();
    tracker = new ShipmentTracker(store, telemetrySource);

    vehicle = new Vehicle("VEH-101", "REG-101", "Volvo", "3-Ton Truck", 3000.0, 15.0, "BR-MEL");
    vehicle.setStatus(VehicleStatus.DISPATCHED);
    store.vehicles().put("VEH-101", vehicle);

    driver = new Driver("DRV-201", "Dave Driver", "Male", LocalDate.of(1988, 1, 1),
        "+61412345678", "dave@example.com", "Address", "BR-MEL", "HC-LIC", LocalDate.now().plusYears(2));
    driver.setDutyState(DutyState.DISPATCHED);
    store.drivers().put("DRV-201", driver);

    shipment = new Shipment("SHP-001", "ORD-001", "VEH-101", "DRV-201");
    store.shipments().put("SHP-001", shipment);
  }

  @Test
  @DisplayName("Should update shipment milestone through pickup, transit, and delivery")
  void testConfirmDeliveryReleasesResources() {
    tracker.confirmPickup("SHP-001", "Depot Gate A");
    assertEquals("Picked Up", shipment.getStateName());
    assertEquals("Depot Gate A", shipment.getLastKnownLocation());

    tracker.confirmInTransit("SHP-001", "M1 Highway KM 50");
    assertEquals("In Transit", shipment.getStateName());

    tracker.confirmDelivery("SHP-001", "Sydney Destination Depot");
    assertEquals("Delivered", shipment.getStateName());
    assertTrue(shipment.isDelivered());

    assertEquals(VehicleStatus.AVAILABLE, vehicle.getStatus());
    assertEquals(DutyState.AVAILABLE, driver.getDutyState());
  }
}
