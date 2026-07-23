package smartfm.ui.gui;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Font;
import java.util.function.Function;
import javax.swing.BorderFactory;
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
@SuppressWarnings({"serial", "this-escape"})
public class ValidatedField extends JPanel {

  private static final long serialVersionUID = 1L;

  private static final Color NORMAL_BORDER = new Color(0xCBD5E1);
  private static final Color FOCUS_BORDER = new Color(0x2563EB);
  private static final Color ERROR_BORDER = new Color(0xDC2626);
  private static final Color ERROR_TEXT_BG = new Color(0xFEF2F2);

  private final JTextField textField = new JTextField(20);
  private final JLabel errorLabel = new JLabel(" ");
  private Color activeBorder = NORMAL_BORDER;

  public ValidatedField(String labelText) {
    super(new BorderLayout(4, 2));
    setOpaque(false);
    JLabel titleLabel = new JLabel(labelText);
    titleLabel.setFont(UiStyle.labelFont());
    errorLabel.setForeground(ERROR_BORDER);
    errorLabel.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));

    textField.setFont(UiStyle.fieldFont());
    textField.setBorder(BorderFactory.createCompoundBorder(
        BorderFactory.createLineBorder(NORMAL_BORDER, 1, true),
        BorderFactory.createEmptyBorder(5, 8, 5, 8)));
    textField.addFocusListener(new java.awt.event.FocusAdapter() {
      @Override
      public void focusGained(java.awt.event.FocusEvent e) {
        applyBorder(activeBorder == ERROR_BORDER ? ERROR_BORDER : FOCUS_BORDER);
      }

      @Override
      public void focusLost(java.awt.event.FocusEvent e) {
        applyBorder(activeBorder);
      }
    });

    JPanel top = new JPanel(new BorderLayout(6, 0));
    top.setOpaque(false);
    top.add(titleLabel, BorderLayout.WEST);
    top.add(textField, BorderLayout.CENTER);

    add(top, BorderLayout.NORTH);
    add(errorLabel, BorderLayout.SOUTH);
  }

  private void applyBorder(Color color) {
    textField.setBorder(BorderFactory.createCompoundBorder(
        BorderFactory.createLineBorder(color, color == FOCUS_BORDER ? 2 : 1, true),
        BorderFactory.createEmptyBorder(5, 8, 5, 8)));
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
    activeBorder = NORMAL_BORDER;
    applyBorder(NORMAL_BORDER);
  }

  private void showError(String message) {
    errorLabel.setText(message);
    textField.setBackground(ERROR_TEXT_BG);
    activeBorder = ERROR_BORDER;
    applyBorder(ERROR_BORDER);
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
