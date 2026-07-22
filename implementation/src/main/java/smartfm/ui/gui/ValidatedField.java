package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Color;
import java.util.function.Function;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import smartfm.common.InvalidDataException;

/**
 * A labelled text field paired with an inline error label, used across
 * every GUI panel so that input validation is presented consistently
 * (Assignment 3 brief: "label/mention each of the input requirements
 * clearly and provide appropriate validation on inputs").
 *
 * <p>Unlike the CLI's blocking "retry until valid" loop ({@code
 * ConsoleIO.readValidated}), a GUI cannot block the event thread while
 * waiting for corrected input. Instead, {@link #validate(Function)} is
 * called on demand (typically when a "Submit" button is pressed); on
 * failure the field is highlighted and the specific {@link
 * InvalidDataException} message is shown immediately below it, and the
 * user corrects the same field in place and re-submits, which is the
 * GUI equivalent of the CLI's in-place retry.
 */
public class ValidatedField extends JPanel {

  private static final long serialVersionUID = 1L;

  private final JTextField textField = new JTextField(20);
  private final JLabel errorLabel = new JLabel(" ");

  public ValidatedField(String labelText) {
    super(new BorderLayout(4, 2));
    JLabel titleLabel = new JLabel(labelText);
    errorLabel.setForeground(new Color(0xC0392B));
    errorLabel.setFont(errorLabel.getFont().deriveFont(11f));

    JPanel top = new JPanel(new BorderLayout(6, 0));
    top.add(titleLabel, BorderLayout.WEST);
    top.add(textField, BorderLayout.CENTER);

    add(top, BorderLayout.NORTH);
    add(errorLabel, BorderLayout.SOUTH);
  }

  public String getRawText() {
    return textField.getText();
  }

  public void setText(String text) {
    textField.setText(text);
  }

  public JTextField getTextField() {
    return textField;
  }

  public void clearError() {
    errorLabel.setText(" ");
    textField.setBackground(Color.WHITE);
  }

  private void showError(String message) {
    errorLabel.setText(message);
    textField.setBackground(new Color(0xFDEDEC));
  }

  /**
   * Runs {@code validator} against the current text. Returns the parsed
   * value on success (and clears any previous error), or {@code null}
   * and displays the {@link InvalidDataException} message on failure.
   */
  public <T> T validate(Function<String, T> validator) {
    try {
      T value = validator.apply(textField.getText());
      clearError();
      return value;
    } catch (InvalidDataException exc) {
      showError(exc.getMessage());
      return null;
    }
  }

  public void reset() {
    textField.setText("");
    clearError();
  }
}
