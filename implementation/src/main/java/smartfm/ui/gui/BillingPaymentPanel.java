package smartfm.ui.gui;

import java.awt.BorderLayout;
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
import smartfm.common.Validators;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.billing.Receipt;

/**
 * GUI panel for Business Area 4: Billing and Payment. Reuses {@link
 * smartfm.application.PaymentProcessor} unchanged. Depends on Business
 * Area 1 (an invoice only exists once an order has been approved). As
 * required by the Assignment 3 brief, no real banking transaction is
 * performed; a simulated confirmation message is shown instead.
 */
@SuppressWarnings({"serial", "this-escape"})
public class BillingPaymentPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final DefaultTableModel invoicesModel =
      new DefaultTableModel(new Object[] {"Invoice Id", "Status", "Outstanding Balance (VND)", "Total (VND)"}, 0);
  private final JTable invoicesTable = new JTable(invoicesModel);

  private final ValidatedField amountField = new ValidatedField("Payment amount (VND):");
  private final JComboBox<PaymentMethod> methodCombo = new JComboBox<>(PaymentMethod.values());
  private final ResultBanner banner = new ResultBanner();

  public BillingPaymentPanel(GuiContext context) {
    super(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    this.context = context;
    setBackground(UiStyle.WINDOW_BG);
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    UiStyle.styleTable(invoicesTable);

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildTableSection(), buildPaySection());
    split.setResizeWeight(0.55);
    split.setBorder(null);
    split.setBackground(UiStyle.WINDOW_BG);
    add(split, BorderLayout.CENTER);

    context.addChangeListener(this::refreshTable);
    refreshTable();
  }

  private JPanel buildTableSection() {
    JPanel section = new JPanel(new BorderLayout());
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Invoices (empty until Business Area 1 approves an order)"));
    JScrollPane scroll = new JScrollPane(invoicesTable);
    scroll.setBorder(BorderFactory.createLineBorder(UiStyle.CARD_BORDER));
    section.add(scroll, BorderLayout.CENTER);
    return section;
  }

  private JPanel buildPaySection() {
    JPanel section = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    section.setBackground(UiStyle.CARD_BG);
    section.setBorder(UiStyle.cardBorder("Submit a Payment"));

    JPanel form = new JPanel(new GridBagLayout());
    form.setOpaque(false);
    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(4, 0, 4, 0);
    gbc.fill = GridBagConstraints.HORIZONTAL;
    gbc.weightx = 1.0;
    gbc.gridx = 0;
    gbc.gridy = 0;
    form.add(amountField, gbc);

    JPanel methodPanel = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, 0));
    methodPanel.setOpaque(false);
    JLabel methodLabel = new JLabel("Payment method:");
    methodLabel.setFont(UiStyle.labelFont());
    methodCombo.setFont(UiStyle.fieldFont());
    methodPanel.add(methodLabel, BorderLayout.WEST);
    methodPanel.add(methodCombo, BorderLayout.CENTER);
    gbc.gridy = 1;
    form.add(methodPanel, gbc);

    JButton payBtn = UiStyle.primaryButton("Submit Payment");
    payBtn.addActionListener(e -> onSubmitPayment());

    JPanel buttonRow = new JPanel(new java.awt.FlowLayout(java.awt.FlowLayout.RIGHT, UiStyle.GAP_MEDIUM, 4));
    buttonRow.setOpaque(false);
    buttonRow.add(payBtn);

    JPanel south = new JPanel(new BorderLayout(0, UiStyle.GAP_SMALL));
    south.setOpaque(false);
    south.add(buttonRow, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);

    section.add(form, BorderLayout.NORTH);
    section.add(south, BorderLayout.SOUTH);
    return section;
  }

  private void onSubmitPayment() {
    int row = invoicesTable.getSelectedRow();
    if (row < 0) {
      banner.error("Select an invoice from the table above first.");
      return;
    }
    String invoiceId = (String) invoicesModel.getValueAt(row, 0);
    Double amount = amountField.validate(v -> Validators.parsePositiveNumber(v, "Payment amount"));
    if (amount == null) {
      banner.error("Please correct the highlighted amount field.");
      return;
    }
    PaymentMethod method = (PaymentMethod) methodCombo.getSelectedItem();
    try {
      Receipt receipt = context.getPaymentProcessor().submitPayment(invoiceId, amount, method);
      Invoice invoice = context.getStore().invoices().get(invoiceId);
      banner.success("payment processed (simulated, no real banking transaction). Receipt "
          + receipt.getId() + " issued for " + Money.format(receipt.getAmountSettled())
          + " VND. Invoice status: " + invoice.getStateName() + ".");
      amountField.reset();
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      banner.error(exc.getMessage());
    }
  }

  private void refreshTable() {
    invoicesModel.setRowCount(0);
    for (Invoice invoice : context.getStore().invoices().values()) {
      invoicesModel.addRow(new Object[] {
          invoice.getId(), invoice.getStateName(),
          Money.format(invoice.getOutstandingBalance()), Money.format(invoice.getTotalAmount())
      });
    }
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the panel's public API.
  // ---------------------------------------------------------------

  JTable invoicesTable() {
    return invoicesTable;
  }

  ValidatedField amountField() {
    return amountField;
  }

  JComboBox<PaymentMethod> methodCombo() {
    return methodCombo;
  }

  void clickSubmitPayment() {
    onSubmitPayment();
  }
}
