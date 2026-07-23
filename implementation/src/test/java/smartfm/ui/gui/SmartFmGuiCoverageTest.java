package smartfm.ui.gui;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JTable;
import javax.swing.SwingUtilities;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.Validators;
import smartfm.domain.customer.Customer;
import smartfm.domain.order.Order;

@DisplayName("Comprehensive GUI Component & Edge Case Coverage Tests")
class SmartFmGuiCoverageTest {

  private Path dbPath;
  private SmartFmMainFrame frame;

  @BeforeEach
  void setUp() throws Exception {
    dbPath = Path.of("target", "test-data", "gui-coverage-smartfm.db");
    Files.createDirectories(dbPath.getParent());
    Files.deleteIfExists(dbPath);

    onEdt(() -> {
      frame = new SmartFmMainFrame(dbPath);
      frame.setVisible(false);
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
  @DisplayName("Should cover OrderManagementPanel rejection, cancellation, validation, and clear form edge cases")
  void testOrderManagementPanelEdgeCases() throws Exception {
    GuiContext context = frame.getContext();
    OrderManagementPanel orderPanel = frame.orderPanel();

    // Register a customer first
    onEdt(() -> {
      context.getOrderProcessor().registerCustomer(
          "Coverage Customer", "Female", LocalDate.of(1995, 6, 15),
          "+84908887766", "coverage@example.com", "100 Coverage St");
      context.notifyChanged();
    });

    // 1. Submit order without any consignments added -> should fail validation
    onEdt(() -> {
      orderPanel.customerCombo().setSelectedIndex(0);
      orderPanel.serviceCombo().setSelectedIndex(0);
      orderPanel.originCombo().setSelectedIndex(0);
      orderPanel.destinationCombo().setSelectedIndex(1);
      orderPanel.distanceField().setText("500");
      orderPanel.pickupDateField().setText(Validators.formatDate(LocalDate.now().plusDays(1)));
      orderPanel.clickSubmitOrder();
    });
    assertEquals(0, context.getStore().orders().size());

    // 2. Add consignment and submit valid order
    onEdt(() -> {
      orderPanel.consignmentDescField().setText("Box of Books");
      orderPanel.consignmentWeightField().setText("50");
      orderPanel.consignmentVolumeField().setText("0.5");
      orderPanel.clickAddConsignment();
      orderPanel.clickSubmitOrder();
    });
    assertEquals(1, context.getStore().orders().size());

    Order order = context.getStore().orders().values().iterator().next();
    assertEquals("Submitted", order.getStateName());

    // 3. Test onReject without selection -> error banner
    onEdt(() -> orderPanel.clickReject());
    assertEquals("Submitted", order.getStateName());

    // 4. Test onReject with selection but blank rejection reason -> error banner
    onEdt(() -> {
      orderPanel.pendingOrdersTable().setRowSelectionInterval(0, 0);
      orderPanel.reasonField().setText("");
      orderPanel.clickReject();
    });
    assertEquals("Submitted", order.getStateName());

    // 5. Test onReject with selection and valid rejection reason -> order rejected
    onEdt(() -> {
      orderPanel.pendingOrdersTable().setRowSelectionInterval(0, 0);
      orderPanel.reasonField().setText("Restricted item detected");
      orderPanel.clickReject();
    });
    assertEquals("Rejected (Restricted item detected)", order.getStateName());

    // 6. Test onCancel without selection -> error banner
    onEdt(() -> orderPanel.clickCancel());

    // Create a second order and test onCancel with selection
    onEdt(() -> {
      orderPanel.customerCombo().setSelectedIndex(0);
      orderPanel.distanceField().setText("300");
      orderPanel.pickupDateField().setText(Validators.formatDate(LocalDate.now().plusDays(2)));
      orderPanel.consignmentDescField().setText("Spare Parts");
      orderPanel.consignmentWeightField().setText("80");
      orderPanel.consignmentVolumeField().setText("0.8");
      orderPanel.clickAddConsignment();
      orderPanel.clickSubmitOrder();
    });
    assertEquals(2, context.getStore().orders().size());

    // Find the second submitted order
    Order secondOrder = context.getStore().orders().values().stream()
        .filter(o -> "Submitted".equals(o.getStateName()))
        .findFirst().orElseThrow();

    // Cancel second order
    onEdt(() -> {
      orderPanel.pendingOrdersTable().setRowSelectionInterval(0, 0);
      orderPanel.clickCancel();
    });
    assertEquals("Cancelled", secondOrder.getStateName());
  }

  @Test
  @DisplayName("Should cover FleetDispatchPanel, ShipmentTrackingPanel, and BillingPaymentPanel error paths")
  void testOtherPanelsErrorPaths() throws Exception {
    FleetDispatchPanel dispatchPanel = frame.dispatchPanel();
    ShipmentTrackingPanel trackingPanel = frame.trackingPanel();
    BillingPaymentPanel billingPanel = frame.billingPanel();

    // 1. Dispatch without selecting order -> error
    onEdt(() -> dispatchPanel.clickDispatch());

    // 2. Tracking without selecting shipment -> error
    onEdt(() -> trackingPanel.clickConfirmPickup());
    onEdt(() -> trackingPanel.clickConfirmInTransit());
    onEdt(() -> trackingPanel.clickConfirmDelivery());

    // 3. Billing without selecting invoice -> error
    onEdt(() -> billingPanel.clickSubmitPayment());
  }

  @Test
  @DisplayName("Should cover ValidatedField, ResultBanner, and UiStyle helpers")
  void testUiStyleAndValidatedField() throws Exception {
    onEdt(() -> {
      // ValidatedField tests
      ValidatedField field = new ValidatedField("Test Field:");
      assertEquals("", field.getRawText());
      field.setText("123");
      assertEquals("123", field.getRawText());

      Double val = field.validate(v -> Validators.parsePositiveNumber(v, "Test"));
      assertEquals(123.0, val);

      field.setText("invalid");
      Double invalidVal = field.validate(v -> Validators.parsePositiveNumber(v, "Test"));
      assertNull(invalidVal);

      field.reset();
      assertEquals("", field.getRawText());

      // ResultBanner tests
      ResultBanner banner = new ResultBanner();
      banner.success("Success msg");
      assertTrue(banner.getText().contains("Success msg"));
      banner.error("Error msg");
      assertTrue(banner.getText().contains("Error msg"));
      banner.neutral("Neutral msg");
      assertTrue(banner.getText().contains("Neutral msg"));

      // UiStyle button tests
      JButton primary = UiStyle.primaryButton("Primary");
      JButton secondary = UiStyle.secondaryButton("Secondary");
      JButton danger = UiStyle.dangerButton("Danger");

      assertNotNull(primary);
      assertNotNull(secondary);
      assertNotNull(danger);

      JLabel secTitle = UiStyle.sectionTitle("Title");
      JLabel cap = UiStyle.caption("Caption");
      assertNotNull(secTitle);
      assertNotNull(cap);

      JTable table = new JTable();
      UiStyle.styleTable(table);
      assertEquals(26, table.getRowHeight());

      // Main frame accessors
      assertNotNull(frame.customerPanel());
      assertNotNull(frame.orderPanel());
      assertNotNull(frame.dispatchPanel());
      assertNotNull(frame.trackingPanel());
      assertNotNull(frame.billingPanel());
      assertNotNull(frame.tabs());
      assertNotNull(frame.getContext());
    });
  }
}
