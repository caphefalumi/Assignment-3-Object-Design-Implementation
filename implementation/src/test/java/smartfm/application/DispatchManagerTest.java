package smartfm.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;
import smartfm.infrastructure.DataStore;

@DisplayName("DispatchManager Application Controller Tests")
class DispatchManagerTest {

  private DataStore store;
  private DispatchManager dispatchManager;
  private Order approvedOrder;
  private Vehicle vehicle;
  private Driver driver;

  @BeforeEach
  void setUp() {
    store = new DataStore();
    dispatchManager = new DispatchManager(store);

    Branch branch = new Branch("BR-MEL", "Melbourne Branch", "Melbourne", "+61391234567");
    store.branches().put("BR-MEL", branch);

    approvedOrder = new Order("ORD-001", "CUST-001", "SVC-EXP", "BR-MEL", "BR-SYD", 500.0, LocalDate.now().plusDays(1));
    approvedOrder.addConsignment(new Consignment("CNS-001", 100.0, 1.0, false, false, "Cargo"));
    approvedOrder.approve();
    store.orders().put("ORD-001", approvedOrder);

    vehicle = new Vehicle("VEH-101", "REG-101", "Volvo", "3-Ton Truck", 2000.0, 10.0, "BR-MEL");
    store.vehicles().put("VEH-101", vehicle);

    driver = new Driver("DRV-201", "Dave Driver", "Male", LocalDate.of(1988, 1, 1),
        "+61412345678", "dave@example.com", "Address", "BR-MEL", "HC-LIC", LocalDate.now().plusYears(2));
    driver.setDutyState(DutyState.AVAILABLE);
    store.drivers().put("DRV-201", driver);
  }

  @Test
  @DisplayName("Should find available vehicles and drivers for branch")
  void testFindAvailableResources() {
    List<Vehicle> availableVehicles = dispatchManager.findAvailableVehicles("BR-MEL", 100.0, 1.0);
    assertEquals(1, availableVehicles.size());

    List<Driver> availableDrivers = dispatchManager.findAvailableDrivers("BR-MEL");
    assertEquals(1, availableDrivers.size());
  }

  @Test
  @DisplayName("Should successfully assign shipment and update fleet statuses")
  void testAssignShipment() {
    Shipment shipment = dispatchManager.assignShipment("ORD-001", "VEH-101", "DRV-201");

    assertNotNull(shipment);
    assertEquals("Assigned", shipment.getStateName());
    assertEquals(VehicleStatus.DISPATCHED, vehicle.getStatus());
    assertEquals(DutyState.DISPATCHED, driver.getDutyState());
    assertEquals(1, store.shipments().size());
  }

  @Test
  @DisplayName("Should reject assigning shipment to unapproved order")
  void testAssignShipmentUnapprovedOrder() {
    Order unapprovedOrder = new Order("ORD-002", "CUST-001", "SVC-EXP", "BR-MEL", "BR-SYD", 500.0, LocalDate.now().plusDays(1));
    unapprovedOrder.addConsignment(new Consignment("CNS-002", 50.0, 0.5, false, false, "Cargo"));
    store.orders().put("ORD-002", unapprovedOrder);

    assertThrows(InvalidDataException.class,
        () -> dispatchManager.assignShipment("ORD-002", "VEH-101", "DRV-201"));
  }
}
