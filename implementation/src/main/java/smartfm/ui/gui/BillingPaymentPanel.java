package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.GridLayout;
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
    super(new BorderLayout(10, 10));
    this.context = context;
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildTableSection(), buildPaySection());
    split.setResizeWeight(0.6);
    add(split, BorderLayout.CENTER);

    context.addChangeListener(this::refreshTable);
    refreshTable();
  }

  private JPanel buildTableSection() {
    JPanel section = new JPanel(new BorderLayout());
    section.setBorder(BorderFactory.createTitledBorder("Invoices (empty until Business Area 1 approves an order)"));
    section.add(new JScrollPane(invoicesTable), BorderLayout.CENTER);
    return section;
  }

  private JPanel buildPaySection() {
    JPanel section = new JPanel(new BorderLayout(6, 6));
    section.setBorder(BorderFactory.createTitledBorder("Submit a Payment"));

    JPanel form = new JPanel(new GridLayout(0, 1, 4, 4));
    form.add(amountField);
    JPanel methodPanel = new JPanel(new BorderLayout(6, 0));
    methodPanel.add(new JLabel("Payment method:"), BorderLayout.WEST);
    methodPanel.add(methodCombo, BorderLayout.CENTER);
    form.add(methodPanel);

    JButton payBtn = new JButton("Submit Payment");
    payBtn.addActionListener(e -> onSubmitPayment());

    JPanel south = new JPanel(new BorderLayout());
    south.add(payBtn, BorderLayout.NORTH);
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
