package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
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
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;

/**
 * GUI panel for Business Area 2: Fleet Dispatch. Reuses {@link
 * smartfm.application.DispatchManager} unchanged. Depends on Business
 * Area 1 (an order must already be Approved), matching the dependency
 * chain documented in asm3.typ Part V.C.
 */
@SuppressWarnings({"serial", "this-escape"})
public class FleetDispatchPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final DefaultTableModel approvedOrdersModel =
      new DefaultTableModel(new Object[] {"Order Id", "Origin Branch", "Total (VND)"}, 0);
  private final JTable approvedOrdersTable = new JTable(approvedOrdersModel);

  private final JComboBox<String> vehicleCombo = new JComboBox<>();
  private final JComboBox<String> driverCombo = new JComboBox<>();
  private final ResultBanner banner = new ResultBanner();
  private final JButton dispatchBtn = UiStyle.primaryButton("Create Shipment");

  public FleetDispatchPanel(GuiContext context) {
    super(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    this.context = context;
    setBackground(UiStyle.WINDOW_BG);
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    UiStyle.styleTable(approvedOrdersTable);

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildOrdersSection(), buildAssignSection());
    split.setResizeWeight(0.55);
    split.setBorder(null);
    split.setBackground(UiStyle.WINDOW_BG);
    add(split, BorderLayout.CENTER);

    approvedOrdersTable.getSelectionModel().addListSelectionListener(e -> refreshResourceCombos());
    context.addChangeListener(this::refreshApprovedOrdersTable);
    context.addChangeListener(this::refreshResourceCombos);
    refreshApprovedOrdersTable();
  }

  private JPanel buildOrdersSection() {
    JPanel section = new JPanel(new BorderLayout());
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Approved Orders Awaiting Dispatch (empty until an order is approved)"));
    JScrollPane scroll = new JScrollPane(approvedOrdersTable);
    scroll.setBorder(BorderFactory.createLineBorder(UiStyle.CARD_BORDER));
    section.add(scroll, BorderLayout.CENTER);
    return section;
  }

  private JPanel buildAssignSection() {
    JPanel section = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Assign Vehicle and Driver"));

    JPanel form = new JPanel(new GridBagLayout());
    form.setOpaque(false);
    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(4, 0, 4, 0);
    gbc.fill = GridBagConstraints.HORIZONTAL;
    gbc.weightx = 1.0;
    gbc.gridx = 0;
    gbc.gridy = 0;
    form.add(labelled("Available vehicle at origin branch:", vehicleCombo), gbc);
    gbc.gridy = 1;
    form.add(labelled("Available driver at origin branch:", driverCombo), gbc);

    dispatchBtn.addActionListener(e -> onDispatch());

    JPanel buttonRow = new JPanel(new FlowLayout(FlowLayout.RIGHT, UiStyle.GAP_MEDIUM, 4));
    buttonRow.setOpaque(false);
    buttonRow.add(dispatchBtn);

    JPanel south = new JPanel(new BorderLayout(0, UiStyle.GAP_SMALL));
    south.setOpaque(false);
    south.add(buttonRow, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);

    section.add(form, BorderLayout.NORTH);
    section.add(south, BorderLayout.SOUTH);
    return section;
  }

  private JPanel labelled(String text, JComboBox<String> combo) {
    JPanel p = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, 0));
    p.setOpaque(false);
    JLabel label = new JLabel(text);
    label.setFont(UiStyle.labelFont());
    combo.setFont(UiStyle.fieldFont());
    p.add(label, BorderLayout.WEST);
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
    for (Vehicle v : context.getDispatchManager().findAvailableVehicles(order)) {
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
