package smartfm.ui;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Scanner;
import smartfm.ui.gui.SmartFmMainFrame;

/**
 * Single entry point for the SmartFM Assignment 3 implementation.
 * Starts the graphical (Swing) interface by default, satisfying the
 * assignment brief's requirement for a working user interface, or the
 * original textual (CLI) interface when {@code --cli} is passed, so
 * both interfaces documented in asm3.typ remain runnable from the same
 * jar / classpath without needing two separate main classes.
 */
public final class Launcher {

  private Launcher() {}

  public static void main(String[] args) {
    boolean useCli = args.length > 0 && ("--cli".equalsIgnoreCase(args[0]) || "-cli".equalsIgnoreCase(args[0]));
    Path dataFile = Paths.get("data", "smartfm-store.dat");

    if (useCli) {
      Scanner scanner = new Scanner(System.in);
      new SmartFmConsoleApp(scanner).run();
    } else {
      SmartFmMainFrame.launch(dataFile);
    }
  }
}
