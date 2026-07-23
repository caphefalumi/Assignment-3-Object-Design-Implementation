package smartfm.ui.gui;

import java.awt.Color;
import java.awt.Font;
import javax.swing.JLabel;
import javax.swing.SwingConstants;

/**
 * A single-line status banner shown at the bottom of every business-area
 * panel, used to display the "Success: ..." and "[Rejected] ..."
 * messages that the CLI prints after each action. Kept as one shared
 * component so every panel presents completion/rejection feedback in
 * the same place and style (Assignment 3 brief: "successful completion
 * of the scenario").
 */
@SuppressWarnings({"serial", "this-escape"})
public class ResultBanner extends JLabel {

  private static final long serialVersionUID = 1L;

  private static final Color SUCCESS_BG = new Color(0xE9F7EF);
  private static final Color SUCCESS_FG = new Color(0x1E8449);
  private static final Color ERROR_BG = new Color(0xFDEDEC);
  private static final Color ERROR_FG = new Color(0xC0392B);
  private static final Color NEUTRAL_BG = new Color(0xF0F4F8);
  private static final Color NEUTRAL_FG = new Color(0x555555);

  public ResultBanner() {
    super("Ready.", SwingConstants.LEFT);
    setOpaque(true);
    setFont(getFont().deriveFont(Font.PLAIN, 13f));
    setBorder(javax.swing.BorderFactory.createEmptyBorder(8, 10, 8, 10));
    neutral("Ready.");
  }

  public void success(String message) {
    setBackground(SUCCESS_BG);
    setForeground(SUCCESS_FG);
    setText("Success: " + message);
  }

  public void error(String message) {
    setBackground(ERROR_BG);
    setForeground(ERROR_FG);
    setText("Rejected: " + message);
  }

  public void neutral(String message) {
    setBackground(NEUTRAL_BG);
    setForeground(NEUTRAL_FG);
    setText(message);
  }
}
