package smartfm.ui;

import java.nio.file.Path;
import java.nio.file.Paths;
import smartfm.ui.gui.SmartFmMainFrame;

/**
 * Entry point for the SmartFM application.
 * Launches the graphical (Swing) desktop interface.
 */
public final class Launcher {

  private Launcher() {}

  public static void main(String[] args) {
    Path dataFile = Paths.get("data", "smartfm.db");
    SmartFmMainFrame.launch(dataFile);
  }
}
