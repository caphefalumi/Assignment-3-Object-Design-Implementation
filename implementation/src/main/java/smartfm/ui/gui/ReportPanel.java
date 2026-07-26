package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.GridLayout;
import java.awt.Insets;
import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;
import java.time.LocalDate;
import java.util.Map;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.SwingConstants;
import javax.swing.table.DefaultTableModel;
import smartfm.common.Validators;
import smartfm.domain.fleet.Branch;
import smartfm.domain.report.Report;
import smartfm.domain.report.ReportCategory;

/**
 * Modern Executive Report Generation GUI Panel implementing Task T12 ("Generate Reports").
 * Features dynamic KPI metric cards, structured data table view, formatted text document view,
 * date range filtering, and clipboard export options.
 */
@SuppressWarnings({"serial", "this-escape"})
public class ReportPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final JComboBox<ReportCategory> categoryCombo = new JComboBox<>(ReportCategory.values());
  private final JComboBox<String> branchCombo = new JComboBox<>();
  private final JTextField startDateField = new JTextField(10);
  private final JTextField endDateField = new JTextField(10);

  // 4 Dynamic Executive KPI Cards
  private final KpiCard kpiCard1 = new KpiCard("Total Quoted Revenue", "$0.00", "Approved Orders");
  private final KpiCard kpiCard2 = new KpiCard("Total Billed Amount", "$0.00", "Issued Invoices");
  private final KpiCard kpiCard3 = new KpiCard("Revenue Collected", "$0.00", "Settled Payments");
  private final KpiCard kpiCard4 = new KpiCard("Outstanding Balance", "$0.00", "Pending Receivables");

  private final JTable metricsTable;
  private final DefaultTableModel tableModel;
  private final JTextArea reportTextArea;
  private final ResultBanner banner = new ResultBanner();

  public ReportPanel(GuiContext context) {
    super(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    this.context = context;
    setBackground(UiStyle.WINDOW_BG);
    setBorder(BorderFactory.createEmptyBorder(14, 14, 14, 14));

    JPanel card = new JPanel(new BorderLayout(0, UiStyle.GAP_MEDIUM));
    card.setBackground(UiStyle.CARD_BG);
    card.setBorder(UiStyle.cardBorder("Executive Management & Operational Reports"));

    // Top control bar
    JPanel controls = buildControlBar();
    card.add(controls, BorderLayout.NORTH);

    // Center content area: KPI Cards + Tabbed Details (Table / Text)
    JPanel centerPanel = new JPanel(new BorderLayout(0, UiStyle.GAP_MEDIUM));
    centerPanel.setOpaque(false);

    // 4 KPI Cards Panel
    JPanel kpiGrid = new JPanel(new GridLayout(1, 4, UiStyle.GAP_MEDIUM, 0));
    kpiGrid.setOpaque(false);
    kpiGrid.add(kpiCard1);
    kpiGrid.add(kpiCard2);
    kpiGrid.add(kpiCard3);
    kpiGrid.add(kpiCard4);
    centerPanel.add(kpiGrid, BorderLayout.NORTH);

    // Tabbed Detail Views
    JTabbedPane reportTabs = new JTabbedPane();
    reportTabs.setFont(UiStyle.labelFont().deriveFont(Font.BOLD));

    // Tab 1: Structured Metrics Table
    tableModel = new DefaultTableModel(new String[] {"Category / Metric Name", "Value"}, 0) {
      private static final long serialVersionUID = 1L;
      @Override
      public boolean isCellEditable(int row, int column) {
        return false;
      }
    };
    metricsTable = new JTable(tableModel);
    UiStyle.styleTable(metricsTable);

    JScrollPane tableScroll = new JScrollPane(metricsTable);
    tableScroll.setBorder(BorderFactory.createEmptyBorder(4, 4, 4, 4));
    tableScroll.getViewport().setBackground(UiStyle.CARD_BG);
    reportTabs.addTab("Structured Metrics Table", tableScroll);

    // Tab 2: Formatted Executive Summary Document
    reportTextArea = new JTextArea();
    reportTextArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
    reportTextArea.setEditable(false);
    reportTextArea.setBackground(new Color(0xF8FAFC));
    reportTextArea.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

    JScrollPane textScroll = new JScrollPane(reportTextArea);
    textScroll.setBorder(BorderFactory.createEmptyBorder(4, 4, 4, 4));
    reportTabs.addTab("Executive Document Summary", textScroll);

    centerPanel.add(reportTabs, BorderLayout.CENTER);
    card.add(centerPanel, BorderLayout.CENTER);

    // Bottom bar with copy button and result banner
    JPanel south = new JPanel(new BorderLayout(0, UiStyle.GAP_SMALL));
    south.setOpaque(false);

    JButton copyBtn = UiStyle.secondaryButton("Copy Document Text");
    copyBtn.addActionListener(e -> onCopyText());
    JPanel rightBtn = new JPanel(new FlowLayout(FlowLayout.RIGHT, 0, 0));
    rightBtn.setOpaque(false);
    rightBtn.add(copyBtn);

    south.add(rightBtn, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);

    card.add(south, BorderLayout.SOUTH);

    add(card, BorderLayout.CENTER);

    context.addChangeListener(() -> {
      refreshBranches();
      onGenerate();
    });
    refreshBranches();
    onGenerate();
  }

  private JPanel buildControlBar() {
    JPanel container = new JPanel(new GridBagLayout());
    container.setOpaque(false);
    container.setBorder(BorderFactory.createEmptyBorder(4, 4, 10, 4));

    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(4, 6, 4, 6);
    gbc.fill = GridBagConstraints.HORIZONTAL;

    // Row 0: Report Type & Branch Scope
    gbc.gridx = 0;
    gbc.gridy = 0;
    gbc.weightx = 0;
    JLabel catLabel = new JLabel("Report Type:");
    catLabel.setFont(UiStyle.labelFont());
    container.add(catLabel, gbc);

    gbc.gridx = 1;
    gbc.weightx = 0.5;
    categoryCombo.setFont(UiStyle.fieldFont());
    categoryCombo.setPreferredSize(new Dimension(220, 28));
    categoryCombo.addActionListener(e -> onGenerate());
    container.add(categoryCombo, gbc);

    gbc.gridx = 2;
    gbc.weightx = 0;
    JLabel branchLabel = new JLabel("Branch Scope:");
    branchLabel.setFont(UiStyle.labelFont());
    container.add(branchLabel, gbc);

    gbc.gridx = 3;
    gbc.weightx = 0.5;
    branchCombo.setFont(UiStyle.fieldFont());
    branchCombo.setPreferredSize(new Dimension(220, 28));
    branchCombo.addActionListener(e -> onGenerate());
    container.add(branchCombo, gbc);

    // Row 1: Start Date, End Date, Generate & All Time Buttons
    gbc.gridx = 0;
    gbc.gridy = 1;
    gbc.weightx = 0;
    JLabel startLabel = new JLabel("Start Date (DD/MM/YYYY):");
    startLabel.setFont(UiStyle.labelFont());
    container.add(startLabel, gbc);

    gbc.gridx = 1;
    gbc.weightx = 0.5;
    startDateField.setFont(UiStyle.fieldFont());
    startDateField.setPreferredSize(new Dimension(120, 28));
    container.add(startDateField, gbc);

    gbc.gridx = 2;
    gbc.weightx = 0;
    JLabel endLabel = new JLabel("End Date (DD/MM/YYYY):");
    endLabel.setFont(UiStyle.labelFont());
    container.add(endLabel, gbc);

    gbc.gridx = 3;
    gbc.weightx = 0.5;
    JPanel dateRight = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 0));
    dateRight.setOpaque(false);
    endDateField.setFont(UiStyle.fieldFont());
    endDateField.setPreferredSize(new Dimension(120, 28));
    dateRight.add(endDateField);

    JButton generateBtn = UiStyle.primaryButton("Generate Report");
    generateBtn.addActionListener(e -> onGenerate());

    JButton resetBtn = UiStyle.secondaryButton("All Time");
    resetBtn.addActionListener(e -> {
      startDateField.setText("");
      endDateField.setText("");
      onGenerate();
    });

    dateRight.add(generateBtn);
    dateRight.add(resetBtn);

    container.add(dateRight, gbc);

    return container;
  }

  private void refreshBranches() {
    String selected = (String) branchCombo.getSelectedItem();
    branchCombo.removeAllItems();
    branchCombo.addItem("All Branches");
    for (Branch b : context.getStore().branches().values()) {
      branchCombo.addItem(b.getId() + " - " + b.getName());
    }
    if (selected != null) {
      branchCombo.setSelectedItem(selected);
    }
  }

  private void onGenerate() {
    ReportCategory cat = (ReportCategory) categoryCombo.getSelectedItem();
    String branchSel = (String) branchCombo.getSelectedItem();
    String branchId = null;
    if (branchSel != null && branchSel.contains(" - ")) {
      branchId = branchSel.split(" - ")[0].trim();
    }

    LocalDate start = null;
    LocalDate end = null;

    String startRaw = startDateField.getText().trim();
    if (!startRaw.isEmpty()) {
      try {
        start = Validators.requireValidDate(startRaw, "Start date");
      } catch (Exception exc) {
        banner.error("Start date error: " + exc.getMessage());
        return;
      }
    }

    String endRaw = endDateField.getText().trim();
    if (!endRaw.isEmpty()) {
      try {
        end = Validators.requireValidDate(endRaw, "End date");
      } catch (Exception exc) {
        banner.error("End date error: " + exc.getMessage());
        return;
      }
    }

    Report report = context.getReportProcessor().generateReport(cat, branchId, start, end);
    Map<String, String> m = report.getMetrics();

    tableModel.setRowCount(0);
    for (Map.Entry<String, String> entry : m.entrySet()) {
      tableModel.addRow(new Object[] {entry.getKey(), entry.getValue()});
    }

    // Update Executive KPI Cards based on Report Category
    updateKpiCards(cat, m);

    reportTextArea.setText(report.getContent());
    reportTextArea.setCaretPosition(0);

    banner.success("Report " + report.getId() + " generated (" + report.getTitle() + ").");
  }

  private void updateKpiCards(ReportCategory cat, Map<String, String> m) {
    if (cat == ReportCategory.FLEET) {
      kpiCard1.setValues("Registered Vehicles", m.getOrDefault("Total Vehicles", "0"), "Fleet Size");
      kpiCard2.setValues("Fleet Capacity", m.getOrDefault("Total Capacity (Kg)", "0") + " Kg", "Payload Limit");
      kpiCard3.setValues("Active Drivers", m.getOrDefault("Available Drivers", "0"), "Available On Duty");
      kpiCard4.setValues("Delivered Shipments", m.getOrDefault("Delivered Shipments", "0"), "Completed Deliveries");
    } else if (cat == ReportCategory.BRANCH) {
      kpiCard1.setValues("Branch Scope", m.getOrDefault("Branch Scope", "All"), "Selected Location");
      kpiCard2.setValues("Allocated Vehicles", m.getOrDefault("Assigned Vehicles", "0"), "Local Fleet");
      kpiCard3.setValues("Originating Orders", m.getOrDefault("Originating Orders", "0"), "Outbound Packages");
      kpiCard4.setValues("Branch Revenue", m.getOrDefault("Branch Quoted Revenue", "0 VND"), "Quoted Volume");
    } else if (cat == ReportCategory.ORDER_SUMMARY) {
      kpiCard1.setValues("Total Orders", m.getOrDefault("Total Orders", "0"), "All Submissions");
      kpiCard2.setValues("Approved Orders", m.getOrDefault("Approved Orders", "0"), "Processed Orders");
      kpiCard3.setValues("Registered Customers", m.getOrDefault("Total Customers", "0"), "Accounts");
      kpiCard4.setValues("Freight Weight", m.getOrDefault("Total Freight Weight (Kg)", "0") + " Kg", "Total Cargo Weight");
    } else {
      // Financial default
      kpiCard1.setValues("Quoted Revenue", m.getOrDefault("Total Quoted Revenue", "0 VND"), "Approved Orders");
      kpiCard2.setValues("Invoiced Amount", m.getOrDefault("Total Invoiced Amount", "0 VND"), "Billed Invoices");
      kpiCard3.setValues("Revenue Collected", m.getOrDefault("Total Revenue Collected", "0 VND"), "Settled Payments");
      kpiCard4.setValues("Outstanding Balance", m.getOrDefault("Outstanding Receivables", "0 VND"), "Unpaid Balance");
    }
  }

  private void onCopyText() {
    String text = reportTextArea.getText();
    if (text == null || text.trim().isEmpty()) {
      banner.error("No report text to copy.");
      return;
    }
    try {
      Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new StringSelection(text), null);
      banner.success("Report text copied to clipboard.");
    } catch (Exception exc) {
      banner.error("Failed to copy report text: " + exc.getMessage());
    }
  }

  // Helper inner component for KPI Cards
  private static class KpiCard extends JPanel {
    private static final long serialVersionUID = 1L;

    private final JLabel titleLabel = new JLabel();
    private final JLabel valueLabel = new JLabel();
    private final JLabel subtitleLabel = new JLabel();

    KpiCard(String title, String value, String subtitle) {
      super(new BorderLayout(0, 4));
      setBackground(new Color(0xF8FAFC));
      setBorder(BorderFactory.createCompoundBorder(
          BorderFactory.createLineBorder(new Color(0xE2E8F0), 1, true),
          BorderFactory.createEmptyBorder(10, 12, 10, 12)));

      titleLabel.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
      titleLabel.setForeground(UiStyle.TEXT_MUTED);

      valueLabel.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 14));
      valueLabel.setForeground(UiStyle.PRIMARY);
      valueLabel.setHorizontalAlignment(SwingConstants.LEFT);

      subtitleLabel.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 10));
      subtitleLabel.setForeground(UiStyle.TEXT_MUTED);

      add(titleLabel, BorderLayout.NORTH);
      add(valueLabel, BorderLayout.CENTER);
      add(subtitleLabel, BorderLayout.SOUTH);

      setValues(title, value, subtitle);
    }

    void setValues(String title, String value, String subtitle) {
      titleLabel.setText(title);
      valueLabel.setText(value);
      subtitleLabel.setText(subtitle);
    }
  }

  // Accessors for driver / testing
  JComboBox<ReportCategory> categoryCombo() {
    return categoryCombo;
  }

  void clickGenerate() {
    onGenerate();
  }
}
