package smartfm.ui.gui;

import java.awt.AWTException;
import java.awt.Rectangle;
import java.awt.Robot;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;
import javax.swing.JFrame;

/**
 * Captures a screenshot of exactly one window's on-screen bounds, never
 * the full desktop. Used only by the Assignment 3 evidence-capture
 * driver ({@code ScreenshotDriver}, kept outside the shipped
 * application) to produce genuine GUI screenshots for asm3.typ Part VI
 * without risking capture of unrelated desktop content.
 */
public final class ScreenshotCapture {

  private ScreenshotCapture() {}

  /** Brings {@code frame} to the foreground and saves a screenshot of only its bounds to {@code pngPath}. */
  public static void capture(JFrame frame, Path pngPath) throws AWTException, IOException {
    frame.toFront();
    frame.requestFocus();
    try {
      Thread.sleep(200);
    } catch (InterruptedException ignored) {
      Thread.currentThread().interrupt();
    }
    Rectangle bounds = frame.getBounds();
    Robot robot = new Robot();
    BufferedImage image = robot.createScreenCapture(bounds);
    Files.createDirectories(pngPath.toAbsolutePath().getParent());
    ImageIO.write(image, "png", pngPath.toFile());
  }
}
