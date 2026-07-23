package smartfm.ui.gui;

import static org.junit.jupiter.api.Assertions.assertEquals;
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

import smartfm.common.Validators;
import smartfm.domain.customer.Customer;
import smartfm.domain.order.Order;
import smartfm.infrastructure.DataStore;

@DisplayName("GuiContext Immediate Auto-Save & Panel Persistence Tests")
class GuiContextAndPersistenceTest {

  private Path dbPath;
  private SmartFmMainFrame frame;

  @BeforeEach
  void setUp() throws Exception {
    dbPath = Path.of("target", "test-data", "autosave-gui-test.db");
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
  @DisplayName("Should automatically persist state to SQLite DB file immediately upon notifyChanged()")
  void testImmediateAutoSaveOnNotifyChanged() throws Exception {
    GuiContext context = frame.getContext();

    // Verify SQLite DB file exists on disk right after constructor initialization
    assertTrue(Files.exists(dbPath));

    // Register a customer via CustomerRegistrationPanel
    CustomerRegistrationPanel customerPanel = frame.customerPanel();
    onEdt(() -> {
      customerPanel.fullNameField().setText("AutoSave Customer");
      customerPanel.dobField().setText("10/04/1990");
      customerPanel.phoneField().setText("+84901234567");
      customerPanel.emailField().setText("autosave@example.com");
      customerPanel.addressField().setText("456 AutoSave Way");
      customerPanel.clickSubmit(); // calls context.notifyChanged() internally
    });

    // Read directly from disk without closing the window or calling context.save()
    DataStore diskStore = DataStore.loadFrom(dbPath);

    assertEquals(1, diskStore.customers().size());
    Customer diskCustomer = diskStore.customers().values().iterator().next();
    assertNotNull(diskCustomer);
    assertEquals("AutoSave Customer", diskCustomer.getFullName());
  }

  @Test
  @DisplayName("Should test OrderManagementPanel 2-column layout form, consignment creation, and auto-save")
  void testOrderManagementPanelFormAndAutoSave() throws Exception {
    GuiContext context = frame.getContext();

    // Register customer first
    onEdt(() -> {
      Customer customer = context.getOrderProcessor().registerCustomer(
          "Order Test User", "Male", LocalDate.of(1992, 3, 10),
          "+84911223344", "ordertest@example.com", "789 Street");
      context.notifyChanged();
    });

    OrderManagementPanel orderPanel = frame.orderPanel();
    onEdt(() -> {
      frame.tabs().setSelectedIndex(1);
      orderPanel.customerCombo().setSelectedIndex(0);
      orderPanel.serviceCombo().setSelectedIndex(0);
      orderPanel.originCombo().setSelectedIndex(0);
      orderPanel.destinationCombo().setSelectedIndex(1);
      orderPanel.distanceField().setText("1200");
      orderPanel.pickupDateField().setText(Validators.formatDate(LocalDate.now().plusDays(1)));

      orderPanel.consignmentDescField().setText("Electronic Components");
      orderPanel.consignmentWeightField().setText("150");
      orderPanel.consignmentVolumeField().setText("1.5");
      orderPanel.clickAddConsignment();

      orderPanel.clickSubmitOrder(); // calls context.notifyChanged()
    });

    // Verify immediate persistence to disk file
    DataStore diskStore = DataStore.loadFrom(dbPath);
    assertEquals(1, diskStore.orders().size());

    Order diskOrder = diskStore.orders().values().iterator().next();
    assertEquals("Submitted", diskOrder.getStateName());
    assertEquals(150.0, diskOrder.getTotalWeightKg(), 0.01);
  }
}
