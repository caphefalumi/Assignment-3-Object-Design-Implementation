package smartfm.ui.gui;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;
import javax.swing.JFrame;

/**
 * Saves a rendered image of exactly one SmartFM window, never the desktop.
 *
 * <p>The evidence driver uses this class instead of {@code Robot} screen
 * capture. Rendering the Swing frame directly means that another desktop
 * window cannot appear in an evidence image even if the operating system
 * changes focus while the scenarios are running.
 */
public final class ScreenshotCapture {

  private ScreenshotCapture() {}

  /**
   * Renders {@code frame} into a PNG containing only the application window.
   * The method is called on the Swing event-dispatch thread by the driver.
   */
  public static void capture(JFrame frame, Path pngPath) throws IOException {
    int width = Math.max(1, frame.getWidth());
    int height = Math.max(1, frame.getHeight());
    BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
    Graphics2D graphics = image.createGraphics();
    try {
      frame.printAll(graphics);
    } finally {
      graphics.dispose();
    }
    Files.createDirectories(pngPath.toAbsolutePath().getParent());
    ImageIO.write(image, "png", pngPath.toFile());
  }
}
