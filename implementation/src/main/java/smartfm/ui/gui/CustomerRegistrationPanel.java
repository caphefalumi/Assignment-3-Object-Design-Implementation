package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.time.LocalDate;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import smartfm.common.Validators;
import smartfm.domain.customer.Customer;

/**
 * GUI equivalent of {@code SmartFmConsoleApp.registerCustomer()}.
 * Presents an empty registration form (Assignment 3 brief requirement
 * 1: "an empty UI at the beginning of the scenario"), validates every
 * field on submit, and shows a clear success message once the account
 * is created.
 */
@SuppressWarnings({"serial", "this-escape"})
public class CustomerRegistrationPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final ValidatedField fullNameField = new ValidatedField("Full name:");
  private final JComboBox<String> genderCombo = new JComboBox<>(new String[] {"Female", "Male", "Other"});
  private final ValidatedField dobField = new ValidatedField("Date of birth (DD/MM/YYYY):");
  private final ValidatedField phoneField = new ValidatedField("Phone number:");
  private final ValidatedField emailField = new ValidatedField("Email address:");
  private final ValidatedField addressField = new ValidatedField("Address:");
  private final ResultBanner banner = new ResultBanner();

  public CustomerRegistrationPanel(GuiContext context) {
    super(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    this.context = context;
    setBackground(UiStyle.WINDOW_BG);
    setBorder(BorderFactory.createEmptyBorder(14, 14, 14, 14));

    JPanel card = new JPanel(new BorderLayout(UiStyle.GAP_MEDIUM, UiStyle.GAP_MEDIUM));
    card.setBackground(UiStyle.CARD_BG);
    card.setBorder(UiStyle.cardBorder("Register Customer Account"));

    JPanel form = buildForm();
    JScrollPane scroll = new JScrollPane(form);
    scroll.setBorder(null);
    scroll.getVerticalScrollBar().setUnitIncrement(16);
    scroll.getViewport().setBackground(UiStyle.CARD_BG);
    card.add(scroll, BorderLayout.CENTER);

    JButton submit = UiStyle.primaryButton("Register Customer");
    submit.addActionListener(e -> onSubmit());
    JButton clear = UiStyle.secondaryButton("Clear Form");
    clear.addActionListener(e -> resetForm());

    JPanel buttons = new JPanel(new java.awt.FlowLayout(java.awt.FlowLayout.RIGHT, UiStyle.GAP_MEDIUM, 0));
    buttons.setOpaque(false);
    buttons.add(clear);
    buttons.add(submit);

    JPanel south = new JPanel(new BorderLayout(0, UiStyle.GAP_SMALL));
    south.setOpaque(false);
    south.add(buttons, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);
    card.add(south, BorderLayout.SOUTH);

    add(card, BorderLayout.CENTER);
  }

  private JPanel buildForm() {
    JPanel form = new JPanel(new GridBagLayout());
    form.setBackground(UiStyle.CARD_BG);
    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(6, 0, 6, 0);
    gbc.fill = GridBagConstraints.HORIZONTAL;
    gbc.gridx = 0;
    gbc.weightx = 1.0;
    gbc.gridy = 0;

    addRow(form, gbc, fullNameField);
    addRow(form, gbc, labelledCombo("Gender:", genderCombo));
    addRow(form, gbc, dobField);
    addRow(form, gbc, phoneField);
    addRow(form, gbc, emailField);
    addRow(form, gbc, addressField);

    // Trailing filler so short forms don't stretch fields with dead
    // space; the filler (not the fields) absorbs any extra height.
    gbc.weighty = 1.0;
    gbc.fill = GridBagConstraints.BOTH;
    form.add(new JPanel() {
      { setOpaque(false); }
    }, gbc);

    return form;
  }

  private void addRow(JPanel form, GridBagConstraints gbc, java.awt.Component component) {
    form.add(component, gbc);
    gbc.gridy++;
  }

  private JPanel labelledCombo(String label, JComboBox<String> combo) {
    JPanel wrapper = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, 2));
    wrapper.setOpaque(false);
    JLabel titleLabel = new JLabel(label);
    titleLabel.setFont(UiStyle.labelFont());
    combo.setFont(UiStyle.fieldFont());
    combo.setPreferredSize(new Dimension(combo.getPreferredSize().width, 28));
    JPanel top = new JPanel(new BorderLayout(UiStyle.GAP_SMALL, 0));
    top.setOpaque(false);
    top.add(titleLabel, BorderLayout.WEST);
    top.add(combo, BorderLayout.CENTER);
    wrapper.add(top, BorderLayout.NORTH);
    // Matches the fixed-height error line reserved below every ValidatedField,
    // so combo rows line up with text-field rows in the same form.
    JLabel spacer = new JLabel(" ");
    spacer.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
    wrapper.add(spacer, BorderLayout.SOUTH);
    return wrapper;
  }

  private void onSubmit() {
    String fullName = fullNameField.validate(v -> Validators.requireNonBlank(v, "Full name", 80));
    LocalDate dob = dobField.validate(v -> Validators.requirePastOrTodayDate(v, "Date of birth"));
    String phone = phoneField.validate(v -> Validators.requirePhone(v, "Phone number"));
    String email = emailField.validate(v -> Validators.requireEmail(v, "Email"));
    String address = addressField.validate(v -> Validators.requireNonBlank(v, "Address", 160));

    if (fullName == null || dob == null || phone == null || email == null || address == null) {
      banner.error("Please correct the highlighted fields.");
      return;
    }

    String gender = (String) genderCombo.getSelectedItem();
    Customer customer = context.getOrderProcessor().registerCustomer(
        fullName, gender, dob, phone, email, address);
    context.notifyChanged();

    banner.success("customer account " + customer.getId() + " (" + fullName + ") created.");
    resetForm();
  }

  private void resetForm() {
    fullNameField.reset();
    dobField.reset();
    phoneField.reset();
    emailField.reset();
    addressField.reset();
    genderCombo.setSelectedIndex(0);
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the panel's public API.
  // ---------------------------------------------------------------

  ValidatedField fullNameField() {
    return fullNameField;
  }

  ValidatedField dobField() {
    return dobField;
  }

  ValidatedField phoneField() {
    return phoneField;
  }

  ValidatedField emailField() {
    return emailField;
  }

  ValidatedField addressField() {
    return addressField;
  }

  void clickSubmit() {
    onSubmit();
  }
}
