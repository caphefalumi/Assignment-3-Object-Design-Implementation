package smartfm.e2e;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.application.Bootstrap;
import smartfm.application.DispatchManager;
import smartfm.application.OrderProcessor;
import smartfm.application.PaymentProcessor;
import smartfm.application.ShipmentTracker;
import smartfm.common.InvalidDataException;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.billing.Receipt;
import smartfm.domain.customer.Customer;
import smartfm.domain.customer.CustomerStatus;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;
import smartfm.infrastructure.DataStore;

@DisplayName("End-to-End System Workflow & Persistence Tests")
class SmartFmEndToEndTest {

  private Path dbPath;
  private DataStore store;
  private Bootstrap bootstrap;

  @BeforeEach
  void setUp() throws IOException {
    dbPath = Path.of("target", "test-data", "e2e-smartfm.db");
    Files.createDirectories(dbPath.getParent());
    Files.deleteIfExists(dbPath);

    store = new DataStore();
    bootstrap = new Bootstrap(store);
    bootstrap.run();
  }

  @AfterEach
  void tearDown() throws IOException {
    Files.deleteIfExists(dbPath);
  }

  @Test
  @DisplayName("Complete E2E Business Lifecycle: Registration -> Order -> Approval -> Dispatch -> Tracking -> Payment -> SQLite Persistence -> System Recovery")
  void testCompleteBusinessLifecycleAndPersistence() {
    OrderProcessor orderProcessor = bootstrap.getOrderProcessor();
    DispatchManager dispatchManager = bootstrap.getDispatchManager();
    ShipmentTracker shipmentTracker = bootstrap.getShipmentTracker();
    PaymentProcessor paymentProcessor = bootstrap.getPaymentProcessor();

    // 1. Customer Registration (UC-01)
    String customerId = "CUST-E2E-001";
    Customer customer = new Customer(
        customerId,
        "Emily Watson",
        "Female",
        LocalDate.of(1992, 4, 15),
        "+61412345678",
        "emily.watson@techcorp.com.au",
        "789 Collins St, Melbourne VIC 3000");
    store.customers().put(customer.getId(), customer);

    assertEquals(CustomerStatus.ACTIVE, customer.getStatus());
    assertTrue(store.customers().containsKey(customerId));

    // 2. Order Submission (UC-02)
    Consignment consignment1 = new Consignment("CNS-E2E-1", 120.0, 1.2, true, false, "Precision Instruments");
    Consignment consignment2 = new Consignment("CNS-E2E-2", 80.0, 0.8, false, true, "Temperature-Controlled Samples");

    Order order = orderProcessor.submitOrder(
        customerId,
        "SVC-CLD",  // Cold Chain Transport
        "BR-HCM",   // HCMC Branch
        "BR-HAN",   // Hanoi Branch
        1720.0,     // 1720 km
        LocalDate.now().plusDays(2),
        List.of(consignment1, consignment2));

    assertNotNull(order);
    assertEquals("Submitted", order.getStateName());
    assertEquals(200.0, order.getTotalWeightKg(), 0.01);
    assertTrue(order.getQuotedAmount() > 0);

    // 3. Order Approval & Observer Invoice Generation
    orderProcessor.approveOrder(order.getId());

    assertEquals("Approved", order.getStateName());
    assertNotNull(order.getInvoiceId());

    String invoiceId = order.getInvoiceId();
    Invoice invoice = store.invoices().get(invoiceId);
    assertNotNull(invoice);
    assertEquals("Unpaid", invoice.getStateName());
    assertEquals(order.getQuotedAmount(), invoice.getOutstandingBalance(), 0.01);

    // 4. Resource Allocation & Dispatch (UC-03)
    List<Vehicle> availableVehicles = dispatchManager.findAvailableVehicles("BR-HCM", 200.0, 2.0);
    List<Driver> availableDrivers = dispatchManager.findAvailableDrivers("BR-HCM");

    assertFalse(availableVehicles.isEmpty());
    assertFalse(availableDrivers.isEmpty());

    Vehicle selectedVehicle = availableVehicles.get(0);
    Driver selectedDriver = availableDrivers.get(0);

    Shipment shipment = dispatchManager.assignShipment(
        order.getId(),
        selectedVehicle.getId(),
        selectedDriver.getId());

    assertNotNull(shipment);
    assertEquals("Assigned", shipment.getStateName());
    assertEquals(VehicleStatus.DISPATCHED, selectedVehicle.getStatus());
    assertEquals(DutyState.DISPATCHED, selectedDriver.getDutyState());

    // 5. Milestone Tracking & Resource Release (UC-04)
    shipmentTracker.confirmPickup(shipment.getId(), "Logistics Depot Gate 4");
    assertEquals("Picked Up", shipment.getStateName());

    shipmentTracker.confirmInTransit(shipment.getId(), "Highway Checkpoint Alpha");
    assertEquals("In Transit", shipment.getStateName());
    assertEquals("Highway Checkpoint Alpha", shipment.getLastKnownLocation());

    shipmentTracker.confirmDelivery(shipment.getId(), "Hanoi Terminal Unloading Bay 2");
    assertEquals("Delivered", shipment.getStateName());
    assertTrue(shipment.isDelivered());

    // Verify driver and vehicle released back to pool
    assertEquals(VehicleStatus.AVAILABLE, selectedVehicle.getStatus());
    assertEquals(DutyState.AVAILABLE, selectedDriver.getDutyState());

    // 6. Billing & Settlement (UC-05)
    double totalAmount = invoice.getTotalAmount();
    double partialAmount = Math.round((totalAmount / 2.0) * 100.0) / 100.0;
    double remainingAmount = Math.round((totalAmount - partialAmount) * 100.0) / 100.0;

    // Partial cash payment
    Receipt receipt1 = paymentProcessor.submitPayment(invoiceId, partialAmount, PaymentMethod.CASH);
    assertNotNull(receipt1);
    assertEquals("Partially Paid", invoice.getStateName());
    assertEquals(remainingAmount, invoice.getOutstandingBalance(), 0.01);

    // Full card payment settlement
    Receipt receipt2 = paymentProcessor.submitPayment(invoiceId, remainingAmount, PaymentMethod.CARD);
    assertNotNull(receipt2);
    assertEquals("Paid", invoice.getStateName());
    assertEquals(0.0, invoice.getOutstandingBalance(), 0.01);
    assertTrue(invoice.isSettled());

    // 7. Persistent SQLite Storage & System Recovery
    store.saveTo(dbPath);
    assertTrue(Files.exists(dbPath));

    // Restore from SQLite into a brand new DataStore session
    DataStore reloadedStore = DataStore.loadFrom(dbPath);
    Bootstrap reloadedBootstrap = new Bootstrap(reloadedStore);
    reloadedBootstrap.run();

    // Assert reloaded state integrity across all entities
    Customer reloadedCustomer = reloadedStore.customers().get(customerId);
    assertNotNull(reloadedCustomer);
    assertEquals("Emily Watson", reloadedCustomer.getFullName());

    Order reloadedOrder = reloadedStore.orders().get(order.getId());
    assertNotNull(reloadedOrder);
    assertEquals("Approved", reloadedOrder.getStateName());

    Shipment reloadedShipment = reloadedStore.shipments().get(shipment.getId());
    assertNotNull(reloadedShipment);
    assertEquals("Delivered", reloadedShipment.getStateName());
    assertEquals("Hanoi Terminal Unloading Bay 2", reloadedShipment.getLastKnownLocation());

    Invoice reloadedInvoice = reloadedStore.invoices().get(invoiceId);
    assertNotNull(reloadedInvoice);
    assertEquals("Paid", reloadedInvoice.getStateName());
    assertEquals(0.0, reloadedInvoice.getOutstandingBalance(), 0.01);

    assertEquals(2, reloadedInvoice.getPaymentIds().size());
  }

  @Test
  @DisplayName("E2E Boundary & Error Validation: Invalid Transitions, Overpayments & Unapproved Dispatch Rejections")
  void testValidationAndBoundaryGuardsInE2ESequence() {
    OrderProcessor orderProcessor = bootstrap.getOrderProcessor();
    DispatchManager dispatchManager = bootstrap.getDispatchManager();
    PaymentProcessor paymentProcessor = bootstrap.getPaymentProcessor();

    // Customer validation failure
    assertThrows(InvalidDataException.class, () -> new Customer(
        "CUST-ERR", "John", "Male", LocalDate.of(1990, 1, 1),
        "invalid-phone", "john@example.com", "Address"));

    // Submitting order for existing customer
    Customer validCustomer = new Customer(
        "CUST-E2E-001", "Valid User", "Male", LocalDate.of(1990, 1, 1),
        "+61412345678", "valid@example.com", "Address");
    store.customers().put("CUST-E2E-001", validCustomer);

    Consignment consignment = new Consignment("CNS-ERR", 50.0, 0.5, false, false, "Goods");
    Order order = orderProcessor.submitOrder(
        "CUST-E2E-001", "SVC-STD", "BR-HCM", "BR-HAN",
        500.0, LocalDate.now().plusDays(1), List.of(consignment));

    // Attempting to dispatch an UNAPPROVED order must fail
    assertThrows(InvalidDataException.class, () -> dispatchManager.assignShipment(
        order.getId(), "VHC-0001", "DRV-0001"));

    // Approve order and attempt overpayment
    orderProcessor.approveOrder(order.getId());
    String invoiceId = order.getInvoiceId();
    Invoice invoice = store.invoices().get(invoiceId);

    assertThrows(InvalidDataException.class, () -> paymentProcessor.submitPayment(
        invoiceId, invoice.getTotalAmount() + 500.0, PaymentMethod.CASH));
  }
}
