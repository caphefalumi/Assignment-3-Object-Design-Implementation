package smartfm.domain.fleet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Fleet & Branch Domain Package Tests")
class FleetAndBranchTest {

  private Branch branch;
  private Vehicle vehicle;
  private Driver driver;
  private StaffMember staffMember;

  @BeforeEach
  void setUp() {
    branch = new Branch("BR-MEL", "Melbourne Hub", "Melbourne", "+61391234567");

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

    staffMember = new StaffMember(
        "STF-301",
        "Sarah Manager",
        "Female",
        LocalDate.of(1980, 10, 5),
        "+61390001111",
        "sarah@example.com",
        "789 Admin St",
        StaffRole.BRANCH_MANAGER,
        "BR-MEL");
  }

  @Test
  @DisplayName("Should initialize Branch and manage registered resources")
  void testBranchOperations() {
    assertEquals("BR-MEL", branch.getId());
    assertEquals("Melbourne Hub", branch.getName());
    assertEquals("Melbourne", branch.getCity());
    assertEquals("+61391234567", branch.getContactPhone());
    assertTrue(branch.toString().contains("Melbourne Hub"));

    branch.registerVehicle("VEH-101");
    branch.registerDriver("DRV-201");
    branch.registerStaff("STF-301");
    branch.registerServiceOffering("SVC-EXP");

    assertEquals(1, branch.getVehicleIds().size());
    assertEquals(1, branch.getDriverIds().size());
    assertEquals(1, branch.getStaffIds().size());
    assertEquals(1, branch.getServiceOfferingIds().size());

    // Contact phone validation
    assertThrows(InvalidDataException.class, () -> new Branch("BR-ERR", "Invalid", "City", "invalid-phone"));
  }

  @Test
  @DisplayName("Should initialize Vehicle, enforce capacity, and update status")
  void testVehicleOperations() {
    assertEquals("VEH-101", vehicle.getId());
    assertEquals("VH-REG-888", vehicle.getLicensePlate());
    assertEquals("Volvo", vehicle.getMake());
    assertEquals("3-Ton Truck", vehicle.getCargoType());
    assertEquals(3000.0, vehicle.getMaxWeightCapacityKg());
    assertEquals(15.0, vehicle.getMaxVolumeCapacityM3());
    assertEquals("BR-MEL", vehicle.getBranchId());
    assertEquals(VehicleStatus.AVAILABLE, vehicle.getStatus());
    assertTrue(vehicle.isAvailable());

    // Payload limits check
    assertTrue(vehicle.canCarry(2500.0, 10.0));
    assertFalse(vehicle.canCarry(3500.0, 10.0)); // Over weight limit
    assertFalse(vehicle.canCarry(2500.0, 20.0)); // Over volume limit

    vehicle.setStatus(VehicleStatus.DISPATCHED);
    assertEquals(VehicleStatus.DISPATCHED, vehicle.getStatus());
    assertFalse(vehicle.isAvailable());
  }

  @Test
  @DisplayName("Should manage Driver license validity, duty state, and cumulative hours")
  void testDriverOperations() {
    assertEquals("DRV-201", driver.getId());
    assertEquals("Bob Driver", driver.getFullName());
    assertEquals("BR-MEL", driver.getHomeBranchId());
    assertEquals("LIC-CLASS-HC", driver.getLicenseNumber());
    assertNotNull(driver.getLicenseExpiry());
    assertTrue(driver.isLicenseValid());

    assertEquals(DutyState.OFF_DUTY, driver.getDutyState());
    assertFalse(driver.isAvailable());

    driver.setDutyState(DutyState.AVAILABLE);
    assertEquals(DutyState.AVAILABLE, driver.getDutyState());
    assertTrue(driver.isAvailable());

    driver.setDutyState(DutyState.DISPATCHED);
    assertEquals(DutyState.DISPATCHED, driver.getDutyState());
    assertFalse(driver.isAvailable());

    // Shift hours
    assertEquals(0.0, driver.getCumulativeShiftHours());
    driver.addShiftHours(4.5);
    driver.addShiftHours(3.5);
    assertEquals(8.0, driver.getCumulativeShiftHours());

    assertThrows(InvalidDataException.class, () -> driver.addShiftHours(-2.0));
  }

  @Test
  @DisplayName("Should initialize StaffMember with role and home branch")
  void testStaffMember() {
    assertEquals("STF-301", staffMember.getId());
    assertEquals("Sarah Manager", staffMember.getFullName());
    assertEquals(StaffRole.BRANCH_MANAGER, staffMember.getRole());
    assertEquals("BR-MEL", staffMember.getHomeBranchId());
  }
}
