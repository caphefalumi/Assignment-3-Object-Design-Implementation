package smartfm.domain.shipment;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Shipment & Telemetry Domain Package Tests")
class ShipmentAndTelemetryTest {

  private Shipment shipment;

  @BeforeEach
  void setUp() {
    shipment = new Shipment("SHP-001", "ORD-001", "VEH-101", "DRV-201");
  }

  @Test
  @DisplayName("Should initialize shipment with Assigned state and origin location")
  void testInitialShipmentState() {
    assertEquals("SHP-001", shipment.getId());
    assertEquals("ORD-001", shipment.getOrderId());
    assertEquals("VEH-101", shipment.getVehicleId());
    assertEquals("DRV-201", shipment.getDriverId());
    assertNotNull(shipment.getCreatedAt());
    assertEquals("Assigned", shipment.getStateName());
    assertFalse(shipment.isDelivered());
    assertTrue(shipment.getLastKnownLocation().contains("Origin branch"));
    assertTrue(shipment.toString().contains("SHP-001"));
  }

  @Test
  @DisplayName("Should transition cleanly through complete milestone lifecycle")
  void testShipmentLifecycle() {
    shipment.pickUp();
    assertEquals("Picked Up", shipment.getStateName());

    shipment.transit();
    assertEquals("In Transit", shipment.getStateName());

    shipment.updateLocation("Highway M1 KM 100");
    assertEquals("Highway M1 KM 100", shipment.getLastKnownLocation());

    shipment.deliver();
    assertEquals("Delivered", shipment.getStateName());
    assertTrue(shipment.isDelivered());
  }

  @Test
  @DisplayName("Should reject illegal state transitions in shipment state machine")
  void testIllegalShipmentStateTransitions() {
    // Deliver directly from Assigned -> invalid
    InvalidDataException ex1 = assertThrows(InvalidDataException.class, shipment::deliver);
    assertTrue(ex1.getMessage().contains("Cannot mark 'Delivered'"));

    // Transit directly from Assigned -> invalid
    InvalidDataException ex2 = assertThrows(InvalidDataException.class, shipment::transit);
    assertTrue(ex2.getMessage().contains("Cannot mark 'In Transit'"));

    // Move to Picked Up
    shipment.pickUp();

    // PickUp again from Picked Up -> invalid
    assertThrows(InvalidDataException.class, shipment::pickUp);

    // Move to In Transit
    shipment.transit();

    // PickUp from In Transit -> invalid
    assertThrows(InvalidDataException.class, shipment::pickUp);

    // Deliver from In Transit -> legal
    shipment.deliver();

    // Any transition from Delivered -> invalid
    assertThrows(InvalidDataException.class, shipment::pickUp);
    assertThrows(InvalidDataException.class, shipment::transit);
    assertThrows(InvalidDataException.class, shipment::deliver);
  }

  @Test
  @DisplayName("Should validate location updates")
  void testUpdateLocationValidation() {
    shipment.updateLocation("Depot Gate 2");
    assertEquals("Depot Gate 2", shipment.getLastKnownLocation());

    assertThrows(InvalidDataException.class, () -> shipment.updateLocation(""));
    assertThrows(InvalidDataException.class, () -> shipment.updateLocation(null));
  }

  @Test
  @DisplayName("Should stage and read locations from ManualTelemetrySource adapter")
  void testManualTelemetrySourceAdapter() {
    ManualTelemetrySource telemetry = new ManualTelemetrySource();

    assertEquals("Unknown", telemetry.readLocation("SHP-001"));

    telemetry.stage("GPS Lat -37.8136, Lon 144.9631");
    assertEquals("GPS Lat -37.8136, Lon 144.9631", telemetry.readLocation("SHP-001"));
  }
}
