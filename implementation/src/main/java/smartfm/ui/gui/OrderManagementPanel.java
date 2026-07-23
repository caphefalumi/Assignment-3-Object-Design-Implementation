package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
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
@SuppressWarnings({"serial", "this-escape"})
public class OrderManagementPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final JComboBox<String> customerCombo = new JComboBox<>();
  private final JComboBox<String> serviceCombo = new JComboBox<>();
  private final JComboBox<String> originCombo = new JComboBox<>();
  private final JComboBox<String> destinationCombo = new JComboBox<>();
  private final ValidatedField distanceField = new ValidatedField("Distance (km):");
  private final ValidatedField pickupDateField = new ValidatedField("Pickup date (DD/MM/YYYY):");

  private final ValidatedField consignmentDescField = new ValidatedField("Description:");
  private final ValidatedField consignmentWeightField = new ValidatedField("Weight (kg):");
  private final ValidatedField consignmentVolumeField = new ValidatedField("Volume (m3):");
  private final JCheckBox fragileCheck = new JCheckBox("Fragile");
  private final JCheckBox coldCheck = new JCheckBox("Requires refrigeration");

  private final DefaultTableModel consignmentTableModel =
      new DefaultTableModel(new Object[] {"Description", "Weight (kg)", "Volume (m3)", "Fragile", "Refrigerated"}, 0);
  private final JTable consignmentTable = new JTable(consignmentTableModel);
  private final List<Consignment> pendingConsignments = new ArrayList<>();

  // Monotonically increasing across every order placed in this window
  // session (seeded from however many consignments already exist in
  // the store, e.g. after reloading a saved database). Consignment ids
  // must be globally unique because DataStore persists them in one
  // top-level "consignments" SQLite table shared by all orders; a
  // counter that reset to 1 for every new order (as this used to do)
  // collides with a previous order's "CSG-1" as soon as a second order
  // is submitted in the same session.
  private int consignmentSequence;

  private final ResultBanner orderBanner = new ResultBanner();

  private final DefaultTableModel pendingOrdersModel =
      new DefaultTableModel(new Object[] {"Order Id", "Customer", "Total (VND)", "Weight (kg)"}, 0);
  private final JTable pendingOrdersTable = new JTable(pendingOrdersModel);
  private final JTextField reasonField = new JTextField(24);
  private final ResultBanner actionBanner = new ResultBanner();

  private final JButton approveBtn = UiStyle.primaryButton("Approve Selected");
  private final JButton rejectBtn = UiStyle.dangerButton("Reject Selected");
  private final JButton cancelBtn = UiStyle.secondaryButton("Cancel Selected (change of mind)");

  public OrderManagementPanel(GuiContext context) {
    super(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    this.context = context;
    setBackground(UiStyle.WINDOW_BG);
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    UiStyle.styleTable(consignmentTable);
    UiStyle.styleTable(pendingOrdersTable);

    JPanel mainContainer = new JPanel();
    mainContainer.setOpaque(false);
    mainContainer.setLayout(new BoxLayout(mainContainer, BoxLayout.Y_AXIS));
    mainContainer.add(buildPlaceOrderSection());
    mainContainer.add(Box.createVerticalStrut(UiStyle.GAP_MEDIUM));
    mainContainer.add(buildManageOrdersSection());

    JScrollPane scrollPane = new JScrollPane(mainContainer);
    scrollPane.setBorder(null);
    scrollPane.getViewport().setBackground(UiStyle.WINDOW_BG);
    scrollPane.getVerticalScrollBar().setUnitIncrement(16);
    add(scrollPane, BorderLayout.CENTER);

    pendingOrdersTable.getSelectionModel().addListSelectionListener(e -> updateActionButtonsEnabled());
    updateActionButtonsEnabled();

    for (Order order : context.getStore().orders().values()) {
      consignmentSequence += order.getConsignments().size();
    }

    context.addChangeListener(this::refreshComboBoxes);
    context.addChangeListener(this::refreshPendingOrdersTable);
    refreshComboBoxes();
    refreshPendingOrdersTable();
  }

  // ---------------------------------------------------------------
  // Place a Shipment Order (empty form below)
  // ---------------------------------------------------------------

  private JPanel buildPlaceOrderSection() {
    JPanel section = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Place a Shipment Order"));

    // Header grid: 2 columns, laid out with GridBagLayout so rows keep a
    // consistent compact height instead of stretching to fill space.
    JPanel headerGrid = new JPanel(new GridBagLayout());
    headerGrid.setOpaque(false);
    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(4, 0, 4, UiStyle.GAP_MEDIUM);
    gbc.fill = GridBagConstraints.HORIZONTAL;
    gbc.weightx = 0.5;
    gbc.gridx = 0;
    gbc.gridy = 0;
    headerGrid.add(labelled("Customer:", customerCombo), gbc);
    gbc.gridx = 1;
    gbc.insets = new Insets(4, 0, 4, 0);
    headerGrid.add(labelled("Service offering:", serviceCombo), gbc);

    gbc.gridx = 0;
    gbc.gridy = 1;
    gbc.insets = new Insets(4, 0, 4, UiStyle.GAP_MEDIUM);
    headerGrid.add(labelled("Origin branch:", originCombo), gbc);
    gbc.gridx = 1;
    gbc.insets = new Insets(4, 0, 4, 0);
    headerGrid.add(labelled("Destination branch:", destinationCombo), gbc);

    gbc.gridx = 0;
    gbc.gridy = 2;
    gbc.insets = new Insets(4, 0, 4, UiStyle.GAP_MEDIUM);
    headerGrid.add(distanceField, gbc);
    gbc.gridx = 1;
    gbc.insets = new Insets(4, 0, 4, 0);
    headerGrid.add(pickupDateField, gbc);

    // Consignment form section
    JPanel consignmentForm = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, UiStyle.GAP_SMALL));
    consignmentForm.setOpaque(false);
    consignmentForm.setBorder(UiStyle.cardBorder("Add Consignment Item"));

    JPanel consignmentFields = new JPanel(new GridBagLayout());
    consignmentFields.setOpaque(false);
    GridBagConstraints cgbc = new GridBagConstraints();
    cgbc.insets = new Insets(4, 0, 4, UiStyle.GAP_MEDIUM);
    cgbc.fill = GridBagConstraints.HORIZONTAL;
    cgbc.weightx = 0.5;
    cgbc.gridx = 0;
    cgbc.gridy = 0;
    consignmentFields.add(consignmentDescField, cgbc);
    cgbc.gridx = 1;
    cgbc.insets = new Insets(4, 0, 4, 0);
    consignmentFields.add(consignmentWeightField, cgbc);

    cgbc.gridx = 0;
    cgbc.gridy = 1;
    cgbc.insets = new Insets(4, 0, 4, UiStyle.GAP_MEDIUM);
    consignmentFields.add(consignmentVolumeField, cgbc);

    JPanel checks = new JPanel(new FlowLayout(FlowLayout.LEFT, UiStyle.GAP_MEDIUM, 0));
    checks.setOpaque(false);
    fragileCheck.setOpaque(false);
    coldCheck.setOpaque(false);
    checks.add(fragileCheck);
    checks.add(coldCheck);
    cgbc.gridx = 1;
    cgbc.insets = new Insets(4, 0, 4, 0);
    consignmentFields.add(checks, cgbc);

    JButton addConsignment = UiStyle.secondaryButton("Add Consignment to Order");
    addConsignment.addActionListener(e -> onAddConsignment());

    JPanel consignmentBottom = new JPanel(new FlowLayout(FlowLayout.RIGHT));
    consignmentBottom.setOpaque(false);
    consignmentBottom.add(addConsignment);

    consignmentForm.add(consignmentFields, BorderLayout.CENTER);
    consignmentForm.add(consignmentBottom, BorderLayout.SOUTH);

    JPanel formContainer = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    formContainer.setOpaque(false);
    formContainer.add(headerGrid, BorderLayout.NORTH);
    formContainer.add(consignmentForm, BorderLayout.CENTER);

    // Order table and submit actions
    JPanel tableAndActions = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, UiStyle.GAP_SMALL));
    tableAndActions.setOpaque(false);
    JScrollPane consignmentScroll = new JScrollPane(consignmentTable);
    consignmentScroll.setPreferredSize(new Dimension(0, 110));
    consignmentScroll.setBorder(BorderFactory.createLineBorder(UiStyle.CARD_BORDER));
    tableAndActions.add(consignmentScroll, BorderLayout.CENTER);

    JButton submitOrder = UiStyle.primaryButton("Submit Order");
    submitOrder.addActionListener(e -> onSubmitOrder());
    JButton clearOrder = UiStyle.secondaryButton("Clear / Cancel");
    clearOrder.addActionListener(e -> resetOrderForm());

    JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT, UiStyle.GAP_MEDIUM, 4));
    buttons.setOpaque(false);
    buttons.add(clearOrder);
    buttons.add(submitOrder);

    JPanel south = new JPanel(new BorderLayout(0, UiStyle.GAP_SMALL));
    south.setOpaque(false);
    south.add(buttons, BorderLayout.NORTH);
    south.add(orderBanner, BorderLayout.SOUTH);

    tableAndActions.add(south, BorderLayout.SOUTH);

    section.add(formContainer, BorderLayout.NORTH);
    section.add(tableAndActions, BorderLayout.CENTER);
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

  private void onAddConsignment() {
    String desc = consignmentDescField.validate(v -> Validators.requireNonBlank(v, "Description", 120));
    Double weight = consignmentWeightField.validate(v -> Validators.parsePositiveNumber(v, "Weight"));
    Double volume = consignmentVolumeField.validate(v -> Validators.parsePositiveNumber(v, "Volume"));
    if (desc == null || weight == null || volume == null) {
      orderBanner.error("Please correct the highlighted consignment fields.");
      return;
    }
    consignmentSequence++;
    Consignment consignment = new Consignment(
        "CSG-" + consignmentSequence, weight, volume,
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
      context.notifyChanged();
      clearOrderFormFields();
      orderBanner.success("order " + order.getId() + " submitted. Estimated quote: "
          + Money.format(order.getQuotedAmount()) + " VND. Status: " + order.getStateName() + ".");
    } catch (InvalidDataException exc) {
      orderBanner.error(exc.getMessage());
    }
  }

  private void clearOrderFormFields() {
    distanceField.reset();
    pickupDateField.reset();
    pendingConsignments.clear();
    consignmentTableModel.setRowCount(0);
  }

  private void resetOrderForm() {
    clearOrderFormFields();
    orderBanner.neutral("Form cleared. Ready for a new order.");
  }

  // ---------------------------------------------------------------
  // View / Approve / Reject / Cancel pending orders
  // ---------------------------------------------------------------

  private JPanel buildManageOrdersSection() {
    JPanel section = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Pending Orders - Approve, Reject, or Cancel"));

    JScrollPane pendingScroll = new JScrollPane(pendingOrdersTable);
    pendingScroll.setPreferredSize(new Dimension(0, 130));
    pendingScroll.setBorder(BorderFactory.createLineBorder(UiStyle.CARD_BORDER));
    section.add(pendingScroll, BorderLayout.CENTER);

    JPanel actions = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, UiStyle.GAP_SMALL));
    actions.setOpaque(false);
    JPanel reasonPanel = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, 0));
    reasonPanel.setOpaque(false);
    JLabel reasonLabel = new JLabel("Reason (for rejection):");
    reasonLabel.setFont(UiStyle.labelFont());
    reasonField.setFont(UiStyle.fieldFont());
    reasonField.setBorder(BorderFactory.createCompoundBorder(
        BorderFactory.createLineBorder(new java.awt.Color(0xCBD5E1), 1, true),
        BorderFactory.createEmptyBorder(5, 8, 5, 8)));
    reasonPanel.add(reasonLabel, BorderLayout.WEST);
    reasonPanel.add(reasonField, BorderLayout.CENTER);

    approveBtn.addActionListener(e -> onApprove());
    rejectBtn.addActionListener(e -> onReject());
    cancelBtn.addActionListener(e -> onCancel());

    JPanel buttons = new JPanel(new FlowLayout(FlowLayout.LEFT, UiStyle.GAP_MEDIUM, 4));
    buttons.setOpaque(false);
    buttons.add(approveBtn);
    buttons.add(rejectBtn);
    buttons.add(cancelBtn);

    actions.add(reasonPanel, BorderLayout.NORTH);
    actions.add(buttons, BorderLayout.CENTER);
    actions.add(actionBanner, BorderLayout.SOUTH);

    section.add(actions, BorderLayout.SOUTH);
    return section;
  }

  /**
   * Approve/reject/cancel only make sense once a pending order row is
   * selected; disabling them otherwise (rather than only showing an
   * error banner after the click) makes the required precondition
   * visible before the user acts, per the brief's emphasis on clear
   * input guidance.
   */
  private void updateActionButtonsEnabled() {
    boolean hasSelection = selectedOrderId() != null;
    approveBtn.setEnabled(hasSelection);
    rejectBtn.setEnabled(hasSelection);
    cancelBtn.setEnabled(hasSelection);
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
          + " generated for " + Money.format(invoice.getTotalAmount()) + " VND, due " + Validators.formatDate(invoice.getDueDate())
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
    if (destinationCombo.getItemCount() > 1) {
      destinationCombo.setSelectedIndex(1);
    }
  }

  private void refreshPendingOrdersTable() {
    pendingOrdersModel.setRowCount(0);
    for (Order order : context.getOrderProcessor().listPendingOrders()) {
      pendingOrdersModel.addRow(new Object[] {
          order.getId(), order.getCustomerId(), Money.format(order.getQuotedAmount()), order.getTotalWeightKg()
      });
    }
    updateActionButtonsEnabled();
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
