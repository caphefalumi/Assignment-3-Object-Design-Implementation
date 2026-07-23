package smartfm.ui.gui;

import java.awt.Color;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JLabel;
import javax.swing.JTable;
import javax.swing.SwingConstants;
import javax.swing.border.Border;
import javax.swing.plaf.basic.BasicButtonUI;

/**
 * Shared visual language for every Swing GUI panel: colors, fonts,
 * spacing, and a small factory for consistently-styled buttons.
 *
 * <p>Kept as one small, dependency-free helper (pure AWT/Swing, no new
 * libraries per {@code AGENTS.md} Section 5.3) so that every panel in
 * {@code smartfm.ui.gui} looks and behaves the same way rather than
 * each panel inventing its own colors and default gray {@link
 * JButton}s. This does not change any business logic; it is purely a
 * presentation-layer concern (Assignment 2 Section 5.3.3, layered
 * architecture).
 */
final class UiStyle {

  private UiStyle() {}

  // ---------------------------------------------------------------
  // Palette
  // ---------------------------------------------------------------

  static final Color PRIMARY = new Color(0x2563EB);
  static final Color PRIMARY_HOVER = new Color(0x1D4ED8);
  static final Color PRIMARY_PRESSED = new Color(0x1E40AF);

  static final Color SECONDARY_BG = new Color(0xFFFFFF);
  static final Color SECONDARY_BORDER = new Color(0xCBD5E1);
  static final Color SECONDARY_HOVER = new Color(0xF1F5F9);

  static final Color DANGER = new Color(0xDC2626);
  static final Color DANGER_HOVER = new Color(0xB91C1C);
  static final Color DANGER_PRESSED = new Color(0x991B1B);

  static final Color TEXT_ON_DARK = new Color(0xFFFFFF);
  static final Color TEXT_PRIMARY = new Color(0x1E293B);
  static final Color TEXT_MUTED = new Color(0x64748B);
  static final Color DISABLED_BG = new Color(0xE2E8F0);
  static final Color DISABLED_FG = new Color(0x94A3B8);

  static final Color WINDOW_BG = new Color(0xF8FAFC);
  static final Color CARD_BG = new Color(0xFFFFFF);
  static final Color CARD_BORDER = new Color(0xE2E8F0);

  // ---------------------------------------------------------------
  // Spacing / fonts
  // ---------------------------------------------------------------

  static final int GAP_SMALL = 6;
  static final int GAP_MEDIUM = 10;
  static final int GAP_LARGE = 16;

  static Font sectionTitleFont() {
    return new Font(Font.SANS_SERIF, Font.BOLD, 14);
  }

  static Font labelFont() {
    return new Font(Font.SANS_SERIF, Font.PLAIN, 13);
  }

  static Font fieldFont() {
    return new Font(Font.SANS_SERIF, Font.PLAIN, 13);
  }

  static Font bannerFont() {
    return new Font(Font.SANS_SERIF, Font.PLAIN, 13);
  }

  // ---------------------------------------------------------------
  // Button factories
  // ---------------------------------------------------------------

  /** Primary call-to-action button (e.g. Submit, Approve, Create Shipment). */
  static JButton primaryButton(String text) {
    return button(text, PRIMARY, PRIMARY_HOVER, PRIMARY_PRESSED, TEXT_ON_DARK);
  }

  /** Secondary/neutral button (e.g. Clear, Cancel form, view actions). */
  static JButton secondaryButton(String text) {
    JButton b = button(text, SECONDARY_BG, SECONDARY_HOVER, SECONDARY_BORDER, TEXT_PRIMARY);
    b.setBorder(BorderFactory.createCompoundBorder(
        BorderFactory.createLineBorder(SECONDARY_BORDER, 1, true),
        BorderFactory.createEmptyBorder(8, 16, 8, 16)));
    return b;
  }

  /** Destructive/high-caution button (e.g. Reject, Cancel order). */
  static JButton dangerButton(String text) {
    return button(text, DANGER, DANGER_HOVER, DANGER_PRESSED, TEXT_ON_DARK);
  }

  private static JButton button(String text, Color base, Color hover, Color pressed, Color fg) {
    JButton b = new JButton(text);
    // The platform (Windows) look and feel paints JButton backgrounds
    // natively and ignores setBackground/setForeground, which made
    // every styled button render as a blank box. Forcing the
    // cross-platform BasicButtonUI here means our colors are what
    // actually gets painted, on every OS, while every other component
    // (tables, combos, tabs, etc.) still uses the native look and feel.
    b.setUI(new BasicButtonUI());
    b.setFocusPainted(false);
    b.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 13));
    b.setForeground(fg);
    b.setBackground(base);
    b.setOpaque(true);
    b.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
    b.setBorder(BorderFactory.createEmptyBorder(8, 16, 8, 16));
    b.setContentAreaFilled(true);
    b.getModel().addChangeListener(e -> {
      javax.swing.ButtonModel model = b.getModel();
      if (!b.isEnabled()) {
        b.setBackground(DISABLED_BG);
        b.setForeground(DISABLED_FG);
      } else if (model.isPressed()) {
        b.setBackground(pressed);
        b.setForeground(fg);
      } else if (model.isRollover()) {
        b.setBackground(hover);
        b.setForeground(fg);
      } else {
        b.setBackground(base);
        b.setForeground(fg);
      }
    });
    b.addMouseListener(new MouseAdapter() {
      @Override
      public void mouseEntered(MouseEvent e) {
        if (b.isEnabled()) {
          b.setBackground(hover);
        }
      }

      @Override
      public void mouseExited(MouseEvent e) {
        if (b.isEnabled()) {
          b.setBackground(base);
        }
      }
    });
    return b;
  }

  // ---------------------------------------------------------------
  // Small layout helpers
  // ---------------------------------------------------------------

  /** A bold section heading label, used above form groups. */
  static JLabel sectionTitle(String text) {
    JLabel label = new JLabel(text);
    label.setFont(sectionTitleFont());
    label.setForeground(TEXT_PRIMARY);
    return label;
  }

  /** A muted helper/caption label, e.g. under a table title. */
  static JLabel caption(String text) {
    JLabel label = new JLabel(text);
    label.setFont(labelFont());
    label.setForeground(TEXT_MUTED);
    return label;
  }

  /** A titled "card" border consistent with the rest of the app (title left-aligned, subtle border). */
  static Border cardBorder(String title) {
    Border line = BorderFactory.createLineBorder(CARD_BORDER, 1, true);
    Border titled = BorderFactory.createTitledBorder(line, title,
        SwingConstants.LEFT, SwingConstants.TOP, sectionTitleFont(), TEXT_PRIMARY);
    return BorderFactory.createCompoundBorder(titled, BorderFactory.createEmptyBorder(8, 10, 10, 10));
  }

  /** Applies a consistent minimum/preferred height so buttons never look squashed. */
  static void applyMinButtonSize(JComponent component) {
    Dimension pref = component.getPreferredSize();
    component.setPreferredSize(new Dimension(Math.max(pref.width, 96), Math.max(pref.height, 34)));
  }

  static Component withMinButtonSize(JButton button) {
    applyMinButtonSize(button);
    return button;
  }

  /** Consistent row height, header style, and selection colors for every data table in the app. */
  static void styleTable(JTable table) {
    table.setRowHeight(26);
    table.getTableHeader().setPreferredSize(new Dimension(0, 28));
    table.getTableHeader().setFont(labelFont().deriveFont(Font.BOLD));
    table.setFont(fieldFont());
    table.setShowGrid(true);
    table.setGridColor(CARD_BORDER);
    table.setSelectionBackground(new Color(0xDCE9FB));
    table.setSelectionForeground(TEXT_PRIMARY);
    table.setFillsViewportHeight(true);
  }
}
