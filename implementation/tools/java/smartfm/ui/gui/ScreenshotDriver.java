package smartfm.ui.gui;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/**
 * One-off evidence-capture tool for Assignment 3 Part VI. Not part of
 * the shipped application (kept under {@code tools/}, not {@code
 * src/main/java}) - it drives the real {@link SmartFmMainFrame} and
 * its real panels through the same scenario beats as the CLI
 * transcripts in {@code transcripts/}, and saves a genuine screenshot
 * of only the application window (never the full desktop, see {@link
 * ScreenshotCapture}) after each meaningful step.
 *
 * <p>Every action below calls the exact same package-private panel
 * methods that a real mouse click or key press would trigger (e.g.
 * {@code clickSubmitOrder()}), so the screenshots are evidence of the
 * real GUI/controller integration, not of a mocked or simulated UI.
 */
public final class ScreenshotDriver {

  private static final Path DATA_FILE = Paths.get("data", "smartfm-store.dat");
  private static final Path OUTPUT_DIR = Paths.get("screenshots");

  private SmartFmMainFrame frame;
  private int shotCounter = 0;

  public static void main(String[] args) throws Exception {
    Files.deleteIfExists(DATA_FILE);
    Files.deleteIfExists(Paths.get(DATA_FILE.toString() + ".tmp"));
    // Suppress the confirm-on-exit look and feel differences across machines.
    try {
      UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    } catch (Exception ignored) {
      // Use default look and feel.
    }
    new ScreenshotDriver().run();
    System.exit(0);
  }

  private void run() throws Exception {
    onEdt(() -> {
      frame = new SmartFmMainFrame(DATA_FILE);
      frame.setVisible(true);
    });
    pause(400);

    captureHomeScreen();
    captureCustomerRegistration();
    captureOrderManagement();
    captureFleetDispatch();
    captureShipmentTracking();
    captureBillingPayment();
    captureExitConfirmation();

    onEdt(() -> frame.getContext().save());
    pause(200);
    onEdt(() -> frame.dispose());
  }

  // ---------------------------------------------------------------
  // Scenario 0: Home screen
  // ---------------------------------------------------------------

  private void captureHomeScreen() throws Exception {
    onEdt(() -> frame.tabs().setSelectedIndex(0));
    shoot("00_home_screen_empty");
  }

  // ---------------------------------------------------------------
  // Scenario 1: Customer registration
  // ---------------------------------------------------------------

  private void captureCustomerRegistration() throws Exception {
    CustomerRegistrationPanel panel = frame.customerPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(0));
    shoot("01a_customer_registration_empty");

    // Invalid input: bad phone number and bad email, submitted to trigger validation.
    onEdt(() -> {
      panel.fullNameField().setText("Nguyen Thi Mai");
      panel.dobField().setText("1995-04-10");
      panel.phoneField().setText("abc");
      panel.emailField().setText("not-an-email");
      panel.addressField().setText("120 Nguyen Trai, District 5, Ho Chi Minh City");
    });
    clickButton(panel, "Register Customer");
    shoot("01b_customer_registration_validation_errors");

    // Correct the invalid fields in place and resubmit.
    onEdt(() -> {
      panel.phoneField().setText("+84-91-2223344");
      panel.emailField().setText("mai.nguyen@coopmart.vn");
    });
    clickButton(panel, "Register Customer");
    shoot("01c_customer_registration_success");

    // Second customer, used later by the order/dispatch/billing scenarios.
    onEdt(() -> {
      panel.fullNameField().setText("Tran Van Long");
      panel.dobField().setText("1993-11-02");
      panel.phoneField().setText("+84-93-4445566");
      panel.emailField().setText("long.tran@winmart.vn");
      panel.addressField().setText("88 Ly Thuong Kiet, Cau Giay, Hanoi");
    });
    clickButton(panel, "Register Customer");
    shoot("01d_customer_registration_second_customer");
  }

  // ---------------------------------------------------------------
  // Scenario 2: Order management
  // ---------------------------------------------------------------

  private void captureOrderManagement() throws Exception {
    OrderManagementPanel panel = frame.orderPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(1));
    shoot("02a_order_management_empty");

    // Fill the order header fields.
    onEdt(() -> {
      panel.customerCombo().setSelectedIndex(0); // CUS-0001 Nguyen Thi Mai
      panel.serviceCombo().setSelectedItem(findItem(panel.serviceCombo(), "SVC-CLD"));
      panel.originCombo().setSelectedItem(findItem(panel.originCombo(), "BR-HCM"));
      panel.destinationCombo().setSelectedItem(findItem(panel.destinationCombo(), "BR-HAN"));
      panel.distanceField().setText("1700");
      panel.pickupDateField().setText("2026-08-05");
    });

    // Invalid consignment: negative weight, added to trigger validation.
    onEdt(() -> {
      panel.consignmentDescField().setText("Frozen seafood consignment for WinMart Hanoi");
      panel.consignmentWeightField().setText("-300");
      panel.consignmentVolumeField().setText("3.5");
    });
    clickButton(panel, "Add Consignment to Order");
    shoot("02b_order_management_invalid_weight");

    // Correct the weight and add the consignment for real.
    onEdt(() -> panel.consignmentWeightField().setText("300"));
    clickButton(panel, "Add Consignment to Order");
    shoot("02c_order_management_consignment_added");

    clickButton(panel, "Submit Order");
    shoot("02d_order_management_order_submitted");

    // Second order for the second customer, used by dispatch/billing later.
    onEdt(() -> {
      panel.customerCombo().setSelectedIndex(1); // CUS-0002 Tran Van Long
      panel.serviceCombo().setSelectedItem(findItem(panel.serviceCombo(), "SVC-STD"));
      panel.originCombo().setSelectedItem(findItem(panel.originCombo(), "BR-HCM"));
      panel.destinationCombo().setSelectedItem(findItem(panel.destinationCombo(), "BR-HAN"));
      panel.distanceField().setText("1700");
      panel.pickupDateField().setText("2026-08-10");
      panel.consignmentDescField().setText("General merchandise pallet for retail restock");
      panel.consignmentWeightField().setText("500");
      panel.consignmentVolumeField().setText("2.0");
    });
    clickButton(panel, "Add Consignment to Order");
    clickButton(panel, "Submit Order");
    shoot("02e_order_management_second_order_submitted");

    // Select the second order and cancel it (customer change of mind).
    onEdt(() -> selectTableRowContaining(panel.pendingOrdersTable(), "ORD-0002"));
    clickButton(panel, "Cancel Selected (change of mind)");
    shoot("02f_order_management_order_cancelled");

    // Select the first order and approve it, generating an invoice.
    onEdt(() -> selectTableRowContaining(panel.pendingOrdersTable(), "ORD-0001"));
    clickButton(panel, "Approve Selected");
    shoot("02g_order_management_order_approved");
  }

  // ---------------------------------------------------------------
  // Scenario 3: Fleet dispatch
  // ---------------------------------------------------------------

  private void captureFleetDispatch() throws Exception {
    FleetDispatchPanel panel = frame.dispatchPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(2));
    shoot("03a_fleet_dispatch_approved_order_listed");

    // Invalid dispatch attempt: no order row selected at all yet.
    clickButton(panel, "Create Shipment");
    shoot("03b_fleet_dispatch_no_order_selected_rejected");

    // Selecting the order auto-populates the vehicle/driver combos (each
    // JComboBox auto-selects its first item once populated), so this is
    // the natural next step rather than a separate "no vehicle" state.
    onEdt(() -> selectTableRowContaining(panel.approvedOrdersTable(), "ORD-0001"));
    shoot("03c_fleet_dispatch_order_selected_resources_available");

    clickButton(panel, "Create Shipment");
    shoot("03d_fleet_dispatch_shipment_created");
  }

  // ---------------------------------------------------------------
  // Scenario 4: Shipment tracking
  // ---------------------------------------------------------------

  private void captureShipmentTracking() throws Exception {
    ShipmentTrackingPanel panel = frame.trackingPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(3));
    shoot("04a_shipment_tracking_assigned");

    // Invalid transition: attempt delivery before pickup.
    onEdt(() -> {
      selectTableRowContaining(panel.shipmentsTable(), "SHP-0001");
      panel.locationField().setText("WinMart Hanoi warehouse dock");
    });
    clickButton(panel, "Confirm Delivery");
    shoot("04b_shipment_tracking_invalid_transition_rejected");

    onEdt(() -> panel.locationField().setText("Origin branch dock, Ho Chi Minh City"));
    clickButton(panel, "Confirm Pickup");
    shoot("04c_shipment_tracking_picked_up");

    onEdt(() -> {
      selectTableRowContaining(panel.shipmentsTable(), "SHP-0001");
      panel.locationField().setText("Highway 1A, near Da Nang");
    });
    clickButton(panel, "Confirm In Transit");
    shoot("04d_shipment_tracking_in_transit");

    onEdt(() -> {
      selectTableRowContaining(panel.shipmentsTable(), "SHP-0001");
      panel.locationField().setText("WinMart Hanoi warehouse, delivered and signed for");
    });
    clickButton(panel, "Confirm Delivery");
    shoot("04e_shipment_tracking_delivered");
  }

  // ---------------------------------------------------------------
  // Scenario 5: Billing and payment
  // ---------------------------------------------------------------

  private void captureBillingPayment() throws Exception {
    BillingPaymentPanel panel = frame.billingPanel();
    onEdt(() -> frame.tabs().setSelectedIndex(4));
    shoot("05a_billing_payment_outstanding_invoice");

    onEdt(() -> {
      selectTableRowContaining(panel.invoicesTable(), "INV-0001");
      panel.amountField().setText("30000000");
      panel.methodCombo().setSelectedItem(smartfm.domain.PaymentMethod.CARD);
    });
    clickButton(panel, "Submit Payment");
    shoot("05b_billing_payment_exceeds_balance_rejected");

    onEdt(() -> {
      selectTableRowContaining(panel.invoicesTable(), "INV-0001");
      panel.amountField().setText("10000000");
      panel.methodCombo().setSelectedItem(smartfm.domain.PaymentMethod.CASH);
    });
    clickButton(panel, "Submit Payment");
    shoot("05c_billing_payment_partial_success");

    onEdt(() -> {
      selectTableRowContaining(panel.invoicesTable(), "INV-0001");
      panel.amountField().setText("12290000");
      panel.methodCombo().setSelectedItem(smartfm.domain.PaymentMethod.CARD);
    });
    clickButton(panel, "Submit Payment");
    shoot("05d_billing_payment_settled");
  }

  private void captureExitConfirmation() throws Exception {
    onEdt(() -> frame.tabs().setSelectedIndex(0));
    shoot("06_final_state_before_exit");
  }

  // ---------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------

  private void clickButton(java.awt.Container container, String text) throws Exception {
    javax.swing.JButton button = findButton(container, text);
    if (button == null) {
      throw new IllegalStateException("Button not found: " + text);
    }
    onEdt(button::doClick);
    pause(150);
  }

  private static javax.swing.JButton findButton(java.awt.Container container, String text) {
    for (java.awt.Component c : container.getComponents()) {
      if (c instanceof javax.swing.JButton && text.equals(((javax.swing.JButton) c).getText())) {
        return (javax.swing.JButton) c;
      }
      if (c instanceof java.awt.Container) {
        javax.swing.JButton found = findButton((java.awt.Container) c, text);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  private static void selectTableRowContaining(javax.swing.JTable table, String value) {
    for (int row = 0; row < table.getRowCount(); row++) {
      Object cell = table.getValueAt(row, 0);
      if (cell != null && cell.toString().equals(value)) {
        table.setRowSelectionInterval(row, row);
        return;
      }
    }
  }

  private static String findItem(javax.swing.JComboBox<String> combo, String idPrefix) {
    for (int i = 0; i < combo.getItemCount(); i++) {
      String item = combo.getItemAt(i);
      if (item != null && item.startsWith(idPrefix)) {
        return item;
      }
    }
    return combo.getItemCount() > 0 ? combo.getItemAt(0) : null;
  }

  private void shoot(String name) throws Exception {
    pause(120);
    Path path = OUTPUT_DIR.resolve(name + ".png");
    onEdt(() -> {
      try {
        ScreenshotCapture.capture(frame, path);
      } catch (java.io.IOException exception) {
        throw new java.io.UncheckedIOException(exception);
      }
    });
    shotCounter++;
    System.out.println(shotCounter + ". Captured " + path);
  }

  private static void onEdt(Runnable action) throws Exception {
    if (SwingUtilities.isEventDispatchThread()) {
      action.run();
    } else {
      SwingUtilities.invokeAndWait(action);
    }
  }

  private static void pause(long millis) {
    try {
      Thread.sleep(millis);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }
}
