package smartfm.ui.gui;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;

import javax.swing.SwingUtilities;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;

@DisplayName("Swing GUI End-to-End User Flow & Integration Tests")
class SmartFmGuiEndToEndTest {

  private Path dbPath;
  private SmartFmMainFrame frame;

  @BeforeEach
  void setUp() throws Exception {
    dbPath = Path.of("target", "test-data", "gui-e2e-smartfm.db");
    Files.createDirectories(dbPath.getParent());
    Files.deleteIfExists(dbPath);

    onEdt(() -> {
      frame = new SmartFmMainFrame(dbPath);
      frame.setVisible(false); // Run headless/hidden for test suite
    });
  }

  @AfterEach
  void tearDown() throws Exception {
    if (frame != null) {
      onEdt(() -> frame.dispose());
    }
    Files.deleteIfExists(dbPath);
  }

  private void onEdt(Runnable action) throws InterruptedException, InvocationTargetException {
    if (SwingUtilities.isEventDispatchThread()) {
      action.run();
    } else {
      SwingUtilities.invokeAndWait(action);
    }
  }

  @Test
  @DisplayName("Full Swing GUI User Workflow: Registration -> Order -> Approval -> Dispatch -> Tracking -> Billing -> SQLite Persistence -> Restoration")
  void testFullGuiWorkflowAndPersistence() throws Exception {
    GuiContext context = frame.getContext();

    // ===============================================================
    // 1. Tab 0: Customer Registration Panel
    // ===============================================================
    CustomerRegistrationPanel customerPanel = frame.customerPanel();
    onEdt(() -> {
      frame.tabs().setSelectedIndex(0);

      // Attempt invalid input
      customerPanel.fullNameField().setText("GUI Customer");
      customerPanel.dobField().setText("1995-05-20");
      customerPanel.phoneField().setText("invalid-phone");
      customerPanel.emailField().setText("not-an-email");
      customerPanel.addressField().setText("123 GUI Street");
    });

    // Submitting invalid input triggers error banner without creating customer
    onEdt(customerPanel::clickSubmit);
    assertEquals(0, context.getStore().customers().size());

    // Fix invalid input
    onEdt(() -> {
      customerPanel.phoneField().setText("+84912345678");
      customerPanel.emailField().setText("gui.customer@coopmart.vn");
    });
    onEdt(customerPanel::clickSubmit);

    // Assert customer CUS-0001 created
    assertEquals(1, context.getStore().customers().size());
    Customer createdCustomer = context.getStore().customers().values().iterator().next();
    assertNotNull(createdCustomer);
    assertEquals("GUI Customer", createdCustomer.getFullName());

    // ===============================================================
    // 2. Tab 1: Order Management Panel
    // ===============================================================
    OrderManagementPanel orderPanel = frame.orderPanel();
    onEdt(() -> {
      frame.tabs().setSelectedIndex(1);

      orderPanel.customerCombo().setSelectedIndex(0); // Select CUS-0001
      orderPanel.serviceCombo().setSelectedIndex(2);  // Cold Chain
      orderPanel.originCombo().setSelectedIndex(0);   // BR-HCM
      orderPanel.destinationCombo().setSelectedIndex(1);// BR-HAN
      orderPanel.distanceField().setText("1700");
      orderPanel.pickupDateField().setText(LocalDate.now().plusDays(2).toString());

      // Attempt invalid negative consignment weight
      orderPanel.consignmentDescField().setText("Frozen Seafood Pallet");
      orderPanel.consignmentWeightField().setText("-100");
      orderPanel.consignmentVolumeField().setText("2.5");
    });

    onEdt(orderPanel::clickAddConsignment);
    assertEquals(0, orderPanel.pendingOrdersTable().getRowCount());

    // Fix consignment weight and add
    onEdt(() -> {
      orderPanel.consignmentWeightField().setText("300");
    });
    onEdt(orderPanel::clickAddConsignment);
    onEdt(orderPanel::clickSubmitOrder);

    assertEquals(1, context.getStore().orders().size());
    Order createdOrder = context.getStore().orders().values().iterator().next();
    assertEquals("Submitted", createdOrder.getStateName());

    // Select order in pending orders table and approve it
    onEdt(() -> {
      orderPanel.pendingOrdersTable().setRowSelectionInterval(0, 0);
      orderPanel.clickApprove();
    });

    assertEquals("Approved", createdOrder.getStateName());
    assertNotNull(createdOrder.getInvoiceId());
    String invoiceId = createdOrder.getInvoiceId();

    // ===============================================================
    // 3. Tab 2: Fleet Dispatch Panel
    // ===============================================================
    FleetDispatchPanel dispatchPanel = frame.dispatchPanel();
    onEdt(() -> {
      frame.tabs().setSelectedIndex(2);
      dispatchPanel.refreshAll();
      dispatchPanel.approvedOrdersTable().setRowSelectionInterval(0, 0);
      dispatchPanel.vehicleCombo().setSelectedIndex(0);
      dispatchPanel.driverCombo().setSelectedIndex(0);
      dispatchPanel.clickDispatch();
    });

    assertEquals(1, context.getStore().shipments().size());
    Shipment createdShipment = context.getStore().shipments().values().iterator().next();
    assertEquals("Assigned", createdShipment.getStateName());

    Vehicle vehicle = context.getStore().vehicles().get(createdShipment.getVehicleId());
    Driver driver = context.getStore().drivers().get(createdShipment.getDriverId());
    assertEquals(VehicleStatus.DISPATCHED, vehicle.getStatus());
    assertEquals(DutyState.DISPATCHED, driver.getDutyState());

    // ===============================================================
    // 4. Tab 3: Shipment Tracking Panel
    // ===============================================================
    ShipmentTrackingPanel trackingPanel = frame.trackingPanel();
    onEdt(() -> {
      frame.tabs().setSelectedIndex(3);
      trackingPanel.shipmentsTable().setRowSelectionInterval(0, 0);

      // Attempt illegal out-of-order transition (Deliver directly from Assigned)
      trackingPanel.locationField().setText("Hanoi Depot");
      trackingPanel.clickConfirmDelivery();
    });
    assertEquals("Assigned", createdShipment.getStateName()); // Rejected by state machine

    // Legal sequence: Pickup -> In Transit -> Delivery
    onEdt(() -> {
      trackingPanel.locationField().setText("HCM Gate 2");
      trackingPanel.clickConfirmPickup();
    });
    assertEquals("Picked Up", createdShipment.getStateName());

    onEdt(() -> {
      trackingPanel.locationField().setText("Highway M1 KM 600");
      trackingPanel.clickConfirmInTransit();
    });
    assertEquals("In Transit", createdShipment.getStateName());

    onEdt(() -> {
      trackingPanel.locationField().setText("Hanoi Distribution Bay 3");
      trackingPanel.clickConfirmDelivery();
    });
    assertEquals("Delivered", createdShipment.getStateName());
    assertTrue(createdShipment.isDelivered());

    // Verify vehicle & driver reverted to AVAILABLE
    assertEquals(VehicleStatus.AVAILABLE, vehicle.getStatus());
    assertEquals(DutyState.AVAILABLE, driver.getDutyState());

    // ===============================================================
    // 5. Tab 4: Billing & Payment Panel
    // ===============================================================
    BillingPaymentPanel billingPanel = frame.billingPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(4));

    Invoice invoice = context.getStore().invoices().get(invoiceId);

    // Attempt overpayment
    onEdt(() -> {
      billingPanel.invoicesTable().setRowSelectionInterval(0, 0);
      billingPanel.amountField().setText(String.valueOf(invoice.getTotalAmount() + 50000000));
      billingPanel.methodCombo().setSelectedItem(PaymentMethod.CASH);
      billingPanel.clickSubmitPayment();
    });
    assertEquals("Unpaid", invoice.getStateName());

    // Submit partial payment
    double partial = Math.round((invoice.getTotalAmount() / 2.0) * 100.0) / 100.0;
    double remaining = Math.round((invoice.getTotalAmount() - partial) * 100.0) / 100.0;

    onEdt(() -> {
      billingPanel.invoicesTable().setRowSelectionInterval(0, 0);
      billingPanel.amountField().setText(String.valueOf(partial));
      billingPanel.methodCombo().setSelectedItem(PaymentMethod.CASH);
      billingPanel.clickSubmitPayment();
    });
    assertEquals("Partially Paid", invoice.getStateName());

    // Submit final card payment
    onEdt(() -> {
      billingPanel.invoicesTable().setRowSelectionInterval(0, 0);
      billingPanel.amountField().setText(String.valueOf(remaining));
      billingPanel.methodCombo().setSelectedItem(PaymentMethod.CARD);
      billingPanel.clickSubmitPayment();
    });
    assertEquals("Paid", invoice.getStateName());
    assertTrue(invoice.isSettled());

    // ===============================================================
    // 6. Save SQLite database and reload in new frame
    // ===============================================================
    onEdt(() -> context.save());
    assertTrue(Files.exists(dbPath));

    onEdt(() -> frame.dispose());

    // Reload state from SQLite file
    SmartFmMainFrame reloadedFrame[] = new SmartFmMainFrame[1];
    onEdt(() -> reloadedFrame[0] = new SmartFmMainFrame(dbPath));

    GuiContext reloadedContext = reloadedFrame[0].getContext();
    assertEquals(1, reloadedContext.getStore().customers().size());
    assertEquals("GUI Customer", reloadedContext.getStore().customers().get(createdCustomer.getId()).getFullName());

    Order reloadedOrder = reloadedContext.getStore().orders().get(createdOrder.getId());
    assertEquals("Approved", reloadedOrder.getStateName());

    Shipment reloadedShipment = reloadedContext.getStore().shipments().get(createdShipment.getId());
    assertEquals("Delivered", reloadedShipment.getStateName());

    Invoice reloadedInvoice = reloadedContext.getStore().invoices().get(invoiceId);
    assertEquals("Paid", reloadedInvoice.getStateName());
    assertEquals(2, reloadedInvoice.getPaymentIds().size());

    onEdt(() -> reloadedFrame[0].dispose());
  }
}
