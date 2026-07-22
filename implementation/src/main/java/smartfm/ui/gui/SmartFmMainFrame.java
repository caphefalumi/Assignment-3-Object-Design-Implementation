package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.nio.file.Path;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JTabbedPane;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/**
 * Graphical (Swing) user interface for the SmartFM Assignment 3
 * implementation, satisfying the Assignment 3 brief's requirement for
 * "a simple user interface (graphical or textual)". Presents the same
 * five workflows as the textual {@code SmartFmConsoleApp} - customer
 * registration plus the four business areas - as tabs in a single
 * window, each backed by the exact same controller classes so that
 * both interfaces are two Boundary-layer views over one unchanged
 * Application/Domain layer (Assignment 2 Section 5.3.3, layered
 * architecture; Assignment 3 Part IV, Presentation component).
 */
public class SmartFmMainFrame extends JFrame {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;
  private JTabbedPane tabs;
  private CustomerRegistrationPanel customerPanel;
  private OrderManagementPanel orderPanel;
  private FleetDispatchPanel dispatchPanel;
  private ShipmentTrackingPanel trackingPanel;
  private BillingPaymentPanel billingPanel;

  public SmartFmMainFrame(Path dataFile) {
    super("SmartFM - Smart Fleet Management System (Assignment 3)");
    this.context = new GuiContext(dataFile);

    setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
    addWindowListener(new WindowAdapter() {
      @Override
      public void windowClosing(WindowEvent e) {
        context.save();
        dispose();
        System.exit(0);
      }
    });

    this.customerPanel = new CustomerRegistrationPanel(context);
    this.orderPanel = new OrderManagementPanel(context);
    this.dispatchPanel = new FleetDispatchPanel(context);
    this.trackingPanel = new ShipmentTrackingPanel(context);
    this.billingPanel = new BillingPaymentPanel(context);

    this.tabs = new JTabbedPane();
    tabs.addTab("Register Customer", customerPanel);
    tabs.addTab("1. Order Management", orderPanel);
    tabs.addTab("2. Fleet Dispatch", dispatchPanel);
    tabs.addTab("3. Shipment Tracking", trackingPanel);
    tabs.addTab("4. Billing and Payment", billingPanel);

    JLabel statusBar = new JLabel(" Data file: " + dataFile.toAbsolutePath());
    statusBar.setBorder(javax.swing.BorderFactory.createEmptyBorder(4, 8, 4, 8));

    setLayout(new BorderLayout());
    add(tabs, BorderLayout.CENTER);
    add(statusBar, BorderLayout.SOUTH);

    setMinimumSize(new Dimension(900, 650));
    setLocationRelativeTo(null);
  }

  public GuiContext getContext() {
    return context;
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the frame's public API.
  // ---------------------------------------------------------------

  JTabbedPane tabs() {
    return tabs;
  }

  CustomerRegistrationPanel customerPanel() {
    return customerPanel;
  }

  OrderManagementPanel orderPanel() {
    return orderPanel;
  }

  FleetDispatchPanel dispatchPanel() {
    return dispatchPanel;
  }

  ShipmentTrackingPanel trackingPanel() {
    return trackingPanel;
  }

  BillingPaymentPanel billingPanel() {
    return billingPanel;
  }

  public static void launch(Path dataFile) {
    try {
      UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    } catch (Exception ignored) {
      // Fall back to the default cross-platform look and feel.
    }
    SwingUtilities.invokeLater(() -> {
      SmartFmMainFrame frame = new SmartFmMainFrame(dataFile);
      frame.setVisible(true);
    });
  }
}
