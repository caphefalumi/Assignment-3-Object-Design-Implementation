package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.time.LocalDate;
import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JPanel;
import smartfm.common.Validators;
import smartfm.domain.Customer;

/**
 * GUI equivalent of {@code SmartFmConsoleApp.registerCustomer()}.
 * Presents an empty registration form (Assignment 3 brief requirement
 * 1: "an empty UI at the beginning of the scenario"), validates every
 * field on submit, and shows a clear success message once the account
 * is created.
 */
public class CustomerRegistrationPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final ValidatedField fullNameField = new ValidatedField("Full name:");
  private final JComboBox<String> genderCombo = new JComboBox<>(new String[] {"Female", "Male", "Other"});
  private final ValidatedField dobField = new ValidatedField("Date of birth (YYYY-MM-DD):");
  private final ValidatedField phoneField = new ValidatedField("Phone number:");
  private final ValidatedField emailField = new ValidatedField("Email address:");
  private final ValidatedField addressField = new ValidatedField("Address:");
  private final ResultBanner banner = new ResultBanner();

  public CustomerRegistrationPanel(GuiContext context) {
    super(new BorderLayout(10, 10));
    this.context = context;
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    JPanel form = new JPanel();
    form.setLayout(new BoxLayout(form, BoxLayout.Y_AXIS));
    form.add(fullNameField);
    form.add(labelled("Gender:", genderCombo));
    form.add(dobField);
    form.add(phoneField);
    form.add(emailField);
    form.add(addressField);

    JButton submit = new JButton("Register Customer");
    submit.addActionListener(e -> onSubmit());
    JButton clear = new JButton("Clear Form");
    clear.addActionListener(e -> resetForm());

    JPanel buttons = new JPanel();
    buttons.add(submit);
    buttons.add(clear);

    add(new javax.swing.JLabel("Register Customer Account"), BorderLayout.NORTH);
    add(form, BorderLayout.CENTER);
    JPanel south = new JPanel(new BorderLayout());
    south.add(buttons, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);
    add(south, BorderLayout.SOUTH);
  }

  private JPanel labelled(String label, JComboBox<String> combo) {
    JPanel p = new JPanel(new GridLayout(1, 2, 6, 0));
    p.add(new javax.swing.JLabel(label));
    p.add(combo);
    JPanel wrapper = new JPanel(new BorderLayout());
    wrapper.add(p, BorderLayout.NORTH);
    wrapper.add(Box.createVerticalStrut(14), BorderLayout.SOUTH);
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

    String id = "CUS-" + String.format("%04d", context.getStore().customers().size() + 1);
    String gender = (String) genderCombo.getSelectedItem();
    Customer customer = new Customer(id, fullName, gender, dob, phone, email, address);
    context.getStore().customers().put(customer.getId(), customer);
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
}
