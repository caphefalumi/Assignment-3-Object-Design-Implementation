package smartfm.common;

import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Formats currency amounts and timestamps consistently across the
 * console UI and exception messages. Java prints large {@code double}
 * values (e.g. amounts above 10 million VND) in scientific notation by
 * default, which is unreadable to an end user; this helper renders a
 * fixed, comma-grouped, two-decimal representation instead, and trims
 * {@link LocalDateTime#toString()}'s variable-precision nanoseconds
 * down to whole seconds for the same readability reason.
 */
public final class Money {

  private static final ThreadLocal<DecimalFormat> FORMAT =
      ThreadLocal.withInitial(() -> new DecimalFormat("#,##0.00"));

  private static final DateTimeFormatter TIMESTAMP_FORMAT =
      DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

  private Money() {}

  public static String format(double amount) {
    return FORMAT.get().format(amount);
  }

  public static String formatTimestamp(LocalDateTime timestamp) {
    return timestamp.format(TIMESTAMP_FORMAT);
  }
}
