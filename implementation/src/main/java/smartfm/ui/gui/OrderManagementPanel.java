package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.DefaultTableModel;
import smartfm.common.InvalidDataException;
import smartfm.common.Money;
import smartfm.common.Validators;
import smartfm.domain.billing.Invoice;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Branch;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;

/**
 * GUI panel for Business Area 1: Order Management. Reuses {@link
 * smartfm.application.OrderProcessor} unchanged; this class only
 * translates Swing widget events into the same controller calls the
 * CLI's {@code orderManagementMenu()} makes.
 *
 * <p>Covers the full workflow required by the Assignment 3 brief: an
 * empty order form, consignment capture with add/remove, submission
 * with validation, viewing the pending queue, approval (which
 * generates an invoice), rejection with a reason, and cancellation
 * (customer change of mind).
 */
public class OrderManagementPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final JComboBox<String> customerCombo = new JComboBox<>();
  private final JComboBox<String> serviceCombo = new JComboBox<>();
  private final JComboBox<String> originCombo = new JComboBox<>();
  private final JComboBox<String> destinationCombo = new JComboBox<>();
  private final ValidatedField distanceField = new ValidatedField("Distance (km):");
  private final ValidatedField pickupDateField = new ValidatedField("Pickup date (YYYY-MM-DD):");

  private final ValidatedField consignmentDescField = new ValidatedField("Description:");
  private final ValidatedField consignmentWeightField = new ValidatedField("Weight (kg):");
  private final ValidatedField consignmentVolumeField = new ValidatedField("Volume (m3):");
  private final javax.swing.JCheckBox fragileCheck = new javax.swing.JCheckBox("Fragile");
  private final javax.swing.JCheckBox coldCheck = new javax.swing.JCheckBox("Requires refrigeration");

  private final DefaultTableModel consignmentTableModel =
      new DefaultTableModel(new Object[] {"Description", "Weight (kg)", "Volume (m3)", "Fragile", "Refrigerated"}, 0);
  private final JTable consignmentTable = new JTable(consignmentTableModel);
  private final List<Consignment> pendingConsignments = new ArrayList<>();

  private final ResultBanner orderBanner = new ResultBanner();

  private final DefaultTableModel pendingOrdersModel =
      new DefaultTableModel(new Object[] {"Order Id", "Customer", "Total (VND)", "Weight (kg)"}, 0);
  private final JTable pendingOrdersTable = new JTable(pendingOrdersModel);
  private final JTextField reasonField = new JTextField(24);
  private final ResultBanner actionBanner = new ResultBanner();

  public OrderManagementPanel(GuiContext context) {
    super(new BorderLayout(10, 10));
    this.context = context;
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildPlaceOrderSection(), buildManageOrdersSection());
    split.setResizeWeight(0.55);
    add(split, BorderLayout.CENTER);

    context.addChangeListener(this::refreshComboBoxes);
    context.addChangeListener(this::refreshPendingOrdersTable);
    refreshComboBoxes();
    refreshPendingOrdersTable();
  }

  // ---------------------------------------------------------------
  // Place a Shipment Order (empty form below)
  // ---------------------------------------------------------------

  private JPanel buildPlaceOrderSection() {
    JPanel section = new JPanel(new BorderLayout(6, 6));
    section.setBorder(BorderFactory.createTitledBorder("Place a Shipment Order (empty form below)"));

    JPanel top = new JPanel(new GridLayout(0, 1, 4, 4));
    top.add(labelled("Customer:", customerCombo));
    top.add(labelled("Service offering:", serviceCombo));
    top.add(labelled("Origin branch:", originCombo));
    top.add(labelled("Destination branch:", destinationCombo));
    top.add(distanceField);
    top.add(pickupDateField);

    JPanel consignmentForm = new JPanel(new GridLayout(0, 1, 4, 4));
    consignmentForm.setBorder(BorderFactory.createTitledBorder("Add Consignment"));
    consignmentForm.add(consignmentDescField);
    consignmentForm.add(consignmentWeightField);
    consignmentForm.add(consignmentVolumeField);
    JPanel checks = new JPanel();
    checks.add(fragileCheck);
    checks.add(coldCheck);
    consignmentForm.add(checks);
    JButton addConsignment = new JButton("Add Consignment to Order");
    addConsignment.addActionListener(e -> onAddConsignment());
    consignmentForm.add(addConsignment);

    JPanel middle = new JPanel(new BorderLayout(6, 6));
    middle.add(top, BorderLayout.NORTH);
    middle.add(consignmentForm, BorderLayout.CENTER);

    JButton submitOrder = new JButton("Submit Order");
    submitOrder.addActionListener(e -> onSubmitOrder());
    JButton clearOrder = new JButton("Clear / Cancel");
    clearOrder.addActionListener(e -> resetOrderForm());
    JPanel buttons = new JPanel();
    buttons.add(submitOrder);
    buttons.add(clearOrder);

    JPanel south = new JPanel(new BorderLayout());
    south.add(buttons, BorderLayout.NORTH);
    south.add(orderBanner, BorderLayout.SOUTH);

    section.add(middle, BorderLayout.NORTH);
    section.add(new JScrollPane(consignmentTable), BorderLayout.CENTER);
    section.add(south, BorderLayout.SOUTH);
    return section;
  }

  private JPanel labelled(String text, JComboBox<String> combo) {
    JPanel p = new JPanel(new BorderLayout(6, 0));
    p.add(new JLabel(text), BorderLayout.WEST);
    p.add(combo, BorderLayout.CENTER);
    return p;
  }

  private void onAddConsignment() {
    String desc = consignmentDescField.validate(v -> Validators.requireNonBlank(v, "Description", 120));
    Double weight = consignmentWeightField.validate(v -> Validators.parsePositiveNumber(v, "Weight"));
    Double volume = consignmentVolumeField.validate(v -> Validators.parsePositiveNumber(v, "Volume"));
    if (desc == null || weight == null || volume == null) {
      orderBanner.error("Please correct the highlighted consignment fields.");
      return;
    }
    Consignment consignment = new Consignment(
        "CSG-" + (pendingConsignments.size() + 1), weight, volume,
        fragileCheck.isSelected(), coldCheck.isSelected(), desc);
    pendingConsignments.add(consignment);
    consignmentTableModel.addRow(new Object[] {
        desc, weight, volume, fragileCheck.isSelected() ? "Yes" : "No", coldCheck.isSelected() ? "Yes" : "No"
    });
    consignmentDescField.reset();
    consignmentWeightField.reset();
    consignmentVolumeField.reset();
    fragileCheck.setSelected(false);
    coldCheck.setSelected(false);
    orderBanner.neutral(pendingConsignments.size() + " consignment(s) added to this order so far.");
  }

  private void onSubmitOrder() {
    if (customerCombo.getSelectedItem() == null || serviceCombo.getSelectedItem() == null
        || originCombo.getSelectedItem() == null || destinationCombo.getSelectedItem() == null) {
      orderBanner.error("Register a customer and ensure reference data is loaded first.");
      return;
    }
    Double distance = distanceField.validate(v -> Validators.parsePositiveNumber(v, "Distance"));
    LocalDate pickupDate = pickupDateField.validate(v -> Validators.requireTodayOrFuture(v, "Pickup date"));
    if (distance == null || pickupDate == null) {
      orderBanner.error("Please correct the highlighted fields.");
      return;
    }
    if (pendingConsignments.isEmpty()) {
      orderBanner.error("An order must have at least one consignment. Use 'Add Consignment to Order' above.");
      return;
    }

    String customerId = idFromLabel((String) customerCombo.getSelectedItem());
    String serviceId = idFromLabel((String) serviceCombo.getSelectedItem());
    String originId = idFromLabel((String) originCombo.getSelectedItem());
    String destinationId = idFromLabel((String) destinationCombo.getSelectedItem());

    try {
      Order order = context.getOrderProcessor().submitOrder(
          customerId, serviceId, originId, destinationId, distance, pickupDate,
          new ArrayList<>(pendingConsignments));
      orderBanner.success("order " + order.getId() + " submitted. Estimated quote: "
          + Money.format(order.getQuotedAmount()) + " VND. Status: " + order.getStateName() + ".");
      context.notifyChanged();
      resetOrderForm();
    } catch (InvalidDataException exc) {
      orderBanner.error(exc.getMessage());
    }
  }

  private void resetOrderForm() {
    distanceField.reset();
    pickupDateField.reset();
    pendingConsignments.clear();
    consignmentTableModel.setRowCount(0);
    orderBanner.neutral("Form cleared. Ready for a new order.");
  }

  // ---------------------------------------------------------------
  // View / Approve / Reject / Cancel pending orders
  // ---------------------------------------------------------------

  private JPanel buildManageOrdersSection() {
    JPanel section = new JPanel(new BorderLayout(6, 6));
    section.setBorder(BorderFactory.createTitledBorder("Pending Orders - Approve, Reject, or Cancel"));

    section.add(new JScrollPane(pendingOrdersTable), BorderLayout.CENTER);

    JPanel actions = new JPanel(new BorderLayout(6, 6));
    JPanel reasonPanel = new JPanel(new BorderLayout(6, 0));
    reasonPanel.add(new JLabel("Reason (for rejection):"), BorderLayout.WEST);
    reasonPanel.add(reasonField, BorderLayout.CENTER);

    JButton approveBtn = new JButton("Approve Selected");
    approveBtn.addActionListener(e -> onApprove());
    JButton rejectBtn = new JButton("Reject Selected");
    rejectBtn.addActionListener(e -> onReject());
    JButton cancelBtn = new JButton("Cancel Selected (change of mind)");
    cancelBtn.addActionListener(e -> onCancel());

    JPanel buttons = new JPanel();
    buttons.add(approveBtn);
    buttons.add(rejectBtn);
    buttons.add(cancelBtn);

    actions.add(reasonPanel, BorderLayout.NORTH);
    actions.add(buttons, BorderLayout.CENTER);
    actions.add(actionBanner, BorderLayout.SOUTH);

    section.add(actions, BorderLayout.SOUTH);
    return section;
  }

  private String selectedOrderId() {
    int row = pendingOrdersTable.getSelectedRow();
    if (row < 0) {
      return null;
    }
    return (String) pendingOrdersModel.getValueAt(row, 0);
  }

  private void onApprove() {
    String orderId = selectedOrderId();
    if (orderId == null) {
      actionBanner.error("Select an order from the table first.");
      return;
    }
    try {
      Invoice invoice = context.getOrderProcessor().approveOrder(orderId);
      actionBanner.success("order " + orderId + " approved. Invoice " + invoice.getId()
          + " generated for " + Money.format(invoice.getTotalAmount()) + " VND, due " + invoice.getDueDate()
          + ". (DispatchManager and PaymentProcessor notified automatically.)");
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      actionBanner.error(exc.getMessage());
    }
  }

  private void onReject() {
    String orderId = selectedOrderId();
    if (orderId == null) {
      actionBanner.error("Select an order from the table first.");
      return;
    }
    String reason;
    try {
      reason = Validators.requireNonBlank(reasonField.getText(), "Rejection reason", 200);
    } catch (InvalidDataException exc) {
      actionBanner.error(exc.getMessage());
      return;
    }
    try {
      context.getOrderProcessor().rejectOrder(orderId, reason);
      actionBanner.success("order " + orderId + " rejected. Reason recorded: " + reason);
      reasonField.setText("");
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      actionBanner.error(exc.getMessage());
    }
  }

  private void onCancel() {
    String orderId = selectedOrderId();
    if (orderId == null) {
      actionBanner.error("Select an order from the table first.");
      return;
    }
    try {
      context.getOrderProcessor().cancelOrder(orderId);
      actionBanner.success("order " + orderId + " cancelled at the customer's request.");
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      actionBanner.error(exc.getMessage());
    }
  }

  // ---------------------------------------------------------------
  // Refresh helpers
  // ---------------------------------------------------------------

  private void refreshComboBoxes() {
    customerCombo.removeAllItems();
    for (Customer c : context.getStore().customers().values()) {
      customerCombo.addItem(c.getId() + " - " + c.getFullName());
    }
    serviceCombo.removeAllItems();
    for (ServiceOffering s : context.getStore().serviceOfferings().values()) {
      serviceCombo.addItem(s.getId() + " - " + s.getName());
    }
    originCombo.removeAllItems();
    destinationCombo.removeAllItems();
    for (Branch b : context.getStore().branches().values()) {
      originCombo.addItem(b.getId() + " - " + b.getName());
      destinationCombo.addItem(b.getId() + " - " + b.getName());
    }
  }

  private void refreshPendingOrdersTable() {
    pendingOrdersModel.setRowCount(0);
    for (Order order : context.getOrderProcessor().listPendingOrders()) {
      pendingOrdersModel.addRow(new Object[] {
          order.getId(), order.getCustomerId(), Money.format(order.getQuotedAmount()), order.getTotalWeightKg()
      });
    }
  }

  /** Combo box items are rendered as "ID - Name"; controllers need only the ID. */
  private static String idFromLabel(String label) {
    int dash = label.indexOf(" - ");
    return dash >= 0 ? label.substring(0, dash) : label;
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the panel's public API.
  // ---------------------------------------------------------------

  JComboBox<String> customerCombo() {
    return customerCombo;
  }

  JComboBox<String> serviceCombo() {
    return serviceCombo;
  }

  JComboBox<String> originCombo() {
    return originCombo;
  }

  JComboBox<String> destinationCombo() {
    return destinationCombo;
  }

  ValidatedField distanceField() {
    return distanceField;
  }

  ValidatedField pickupDateField() {
    return pickupDateField;
  }

  ValidatedField consignmentDescField() {
    return consignmentDescField;
  }

  ValidatedField consignmentWeightField() {
    return consignmentWeightField;
  }

  ValidatedField consignmentVolumeField() {
    return consignmentVolumeField;
  }

  void clickAddConsignment() {
    onAddConsignment();
  }

  void clickSubmitOrder() {
    onSubmitOrder();
  }

  JTable pendingOrdersTable() {
    return pendingOrdersTable;
  }

  JTextField reasonField() {
    return reasonField;
  }

  void clickApprove() {
    onApprove();
  }

  void clickReject() {
    onReject();
  }

  void clickCancel() {
    onCancel();
  }
}
