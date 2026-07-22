package smartfm.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Shipment & Fleet Domain Tests")
class ShipmentAndFleetTest {

  private Shipment shipment;
  private Vehicle vehicle;
  private Driver driver;

  @BeforeEach
  void setUp() {
    shipment = new Shipment("SHP-001", "ORD-001", "VEH-101", "DRV-201");

    vehicle = new Vehicle("VEH-101", "VH-REG-888", "Volvo", "3-Ton Truck", 3000.0, 15.0, "BR-MEL");
    driver = new Driver(
        "DRV-201",
        "Bob Driver",
        "Male",
        LocalDate.of(1985, 3, 20),
        "+61498765432",
        "bob.driver@example.com",
        "456 Depot Rd, Melbourne VIC 3000",
        "BR-MEL",
        "LIC-CLASS-HC",
        LocalDate.now().plusYears(2));
  }

  @Test
  @DisplayName("Should initialize shipment in Assigned state")
  void testInitialShipmentState() {
    assertEquals("Assigned", shipment.getStateName());
    assertFalse(shipment.isDelivered());
    assertTrue(shipment.getLastKnownLocation().contains("Origin branch"));
  }

  @Test
  @DisplayName("Should transition through complete shipment lifecycle")
  void testShipmentLifecycle() {
    shipment.pickUp();
    assertEquals("Picked Up", shipment.getStateName());

    shipment.transit();
    assertEquals("In Transit", shipment.getStateName());

    shipment.updateLocation("M1 Highway KM 120");
    assertEquals("M1 Highway KM 120", shipment.getLastKnownLocation());

    shipment.deliver();
    assertEquals("Delivered", shipment.getStateName());
    assertTrue(shipment.isDelivered());
  }

  @Test
  @DisplayName("Should prevent invalid state jumps in shipment lifecycle")
  void testInvalidShipmentStateTransitions() {
    InvalidDataException ex = assertThrows(InvalidDataException.class, shipment::deliver);
    assertTrue(ex.getMessage().contains("Cannot mark 'Delivered'"));

    shipment.pickUp();

    InvalidDataException ex2 = assertThrows(InvalidDataException.class, shipment::deliver);
    assertTrue(ex2.getMessage().contains("Cannot mark 'Delivered'"));
  }

  @Test
  @DisplayName("Should manage driver duty states and vehicle availability")
  void testFleetStateManagement() {
    assertEquals(DutyState.OFF_DUTY, driver.getDutyState());
    driver.setDutyState(DutyState.AVAILABLE);
    assertEquals(DutyState.AVAILABLE, driver.getDutyState());

    driver.setDutyState(DutyState.DISPATCHED);
    assertEquals(DutyState.DISPATCHED, driver.getDutyState());

    assertEquals(VehicleStatus.AVAILABLE, vehicle.getStatus());
    vehicle.setStatus(VehicleStatus.DISPATCHED);
    assertEquals(VehicleStatus.DISPATCHED, vehicle.getStatus());
  }
}
