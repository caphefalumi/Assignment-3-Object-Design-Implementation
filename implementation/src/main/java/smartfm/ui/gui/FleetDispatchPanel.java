package smartfm.ui.gui;

import java.awt.BorderLayout;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;
import smartfm.common.InvalidDataException;
import smartfm.common.Money;
import smartfm.domain.Driver;
import smartfm.domain.Order;
import smartfm.domain.Shipment;
import smartfm.domain.Vehicle;

/**
 * GUI panel for Business Area 2: Fleet Dispatch. Reuses {@link
 * smartfm.application.DispatchManager} unchanged. Depends on Business
 * Area 1 (an order must already be Approved), matching the dependency
 * chain documented in asm3.typ Part V.C.
 */
public class FleetDispatchPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final DefaultTableModel approvedOrdersModel =
      new DefaultTableModel(new Object[] {"Order Id", "Origin Branch", "Total (VND)"}, 0);
  private final JTable approvedOrdersTable = new JTable(approvedOrdersModel);

  private final JComboBox<String> vehicleCombo = new JComboBox<>();
  private final JComboBox<String> driverCombo = new JComboBox<>();
  private final ResultBanner banner = new ResultBanner();

  public FleetDispatchPanel(GuiContext context) {
    super(new BorderLayout(10, 10));
    this.context = context;
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildOrdersSection(), buildAssignSection());
    split.setResizeWeight(0.6);
    add(split, BorderLayout.CENTER);

    approvedOrdersTable.getSelectionModel().addListSelectionListener(e -> refreshResourceCombos());
    context.addChangeListener(this::refreshApprovedOrdersTable);
    context.addChangeListener(this::refreshResourceCombos);
    refreshApprovedOrdersTable();
  }

  private JPanel buildOrdersSection() {
    JPanel section = new JPanel(new BorderLayout());
    section.setBorder(BorderFactory.createTitledBorder("Approved Orders Awaiting Dispatch (empty until an order is approved)"));
    section.add(new JScrollPane(approvedOrdersTable), BorderLayout.CENTER);
    return section;
  }

  private JPanel buildAssignSection() {
    JPanel section = new JPanel(new BorderLayout(6, 6));
    section.setBorder(BorderFactory.createTitledBorder("Assign Vehicle and Driver"));

    JPanel form = new JPanel(new java.awt.GridLayout(0, 1, 4, 4));
    form.add(labelled("Available vehicle at origin branch:", vehicleCombo));
    form.add(labelled("Available driver at origin branch:", driverCombo));

    JButton dispatchBtn = new JButton("Create Shipment");
    dispatchBtn.addActionListener(e -> onDispatch());

    JPanel south = new JPanel(new BorderLayout());
    south.add(dispatchBtn, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);

    section.add(form, BorderLayout.NORTH);
    section.add(south, BorderLayout.SOUTH);
    return section;
  }

  private JPanel labelled(String text, JComboBox<String> combo) {
    JPanel p = new JPanel(new BorderLayout(6, 0));
    p.add(new JLabel(text), BorderLayout.WEST);
    p.add(combo, BorderLayout.CENTER);
    return p;
  }

  private String selectedOrderId() {
    int row = approvedOrdersTable.getSelectedRow();
    return row < 0 ? null : (String) approvedOrdersModel.getValueAt(row, 0);
  }

  private void onDispatch() {
    String orderId = selectedOrderId();
    if (orderId == null) {
      banner.error("Select an approved order from the table above first.");
      return;
    }
    if (vehicleCombo.getSelectedItem() == null || driverCombo.getSelectedItem() == null) {
      banner.error("No available vehicle or driver at this order's origin branch.");
      return;
    }
    String vehicleId = idFromLabel((String) vehicleCombo.getSelectedItem());
    String driverId = idFromLabel((String) driverCombo.getSelectedItem());
    try {
      Shipment shipment = context.getDispatchManager().assignShipment(orderId, vehicleId, driverId);
      banner.success("shipment " + shipment.getId() + " created for order " + orderId
          + ". Status: " + shipment.getStateName() + ". (ShipmentTracker notified automatically.)");
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      banner.error(exc.getMessage());
    }
  }

  private void refreshApprovedOrdersTable() {
    approvedOrdersModel.setRowCount(0);
    for (Order order : context.getStore().orders().values()) {
      if (order.isApproved() && order.getInvoiceId() != null && !hasShipment(order.getId())) {
        approvedOrdersModel.addRow(new Object[] {
            order.getId(), order.getOriginBranchId(), Money.format(order.getQuotedAmount())
        });
      }
    }
  }

  private boolean hasShipment(String orderId) {
    for (Shipment shipment : context.getStore().shipments().values()) {
      if (shipment.getOrderId().equals(orderId)) {
        return true;
      }
    }
    return false;
  }

  private void refreshResourceCombos() {
    vehicleCombo.removeAllItems();
    driverCombo.removeAllItems();
    String orderId = selectedOrderId();
    if (orderId == null) {
      return;
    }
    Order order = context.getStore().orders().get(orderId);
    if (order == null) {
      return;
    }
    for (Vehicle v : context.getDispatchManager()
        .findAvailableVehicles(order.getOriginBranchId(), order.getTotalWeightKg(), 0)) {
      vehicleCombo.addItem(v.getId() + " - " + v);
    }
    for (Driver d : context.getDispatchManager().findAvailableDrivers(order.getOriginBranchId())) {
      driverCombo.addItem(d.getId() + " - " + d.getFullName());
    }
  }

  private static String idFromLabel(String label) {
    int dash = label.indexOf(" - ");
    return dash >= 0 ? label.substring(0, dash) : label;
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the panel's public API.
  // ---------------------------------------------------------------

  JTable approvedOrdersTable() {
    return approvedOrdersTable;
  }

  JComboBox<String> vehicleCombo() {
    return vehicleCombo;
  }

  JComboBox<String> driverCombo() {
    return driverCombo;
  }

  void clickDispatch() {
    onDispatch();
  }

  void refreshAll() {
    refreshApprovedOrdersTable();
    refreshResourceCombos();
  }
}
