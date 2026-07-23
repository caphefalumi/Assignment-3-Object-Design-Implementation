package smartfm.common;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDateTime;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Money & Timestamp Formatter Tests")
class MoneyTest {

  @Test
  @DisplayName("Should format monetary amounts with comma grouping and two decimal places")
  void testFormatAmount() {
    assertEquals("0.00", Money.format(0.0));
    assertEquals("100.00", Money.format(100.0));
    assertEquals("1,234.50", Money.format(1234.50));
    assertEquals("10,000,000.00", Money.format(10000000.00));
    assertEquals("150,500.75", Money.format(150500.75));
  }

  @Test
  @DisplayName("Should format LocalDateTime into dd/MM/yyyy HH:mm:ss string")
  void testFormatTimestamp() {
    LocalDateTime timestamp = LocalDateTime.of(2026, 7, 22, 14, 30, 45);
    String formatted = Money.formatTimestamp(timestamp);
    assertEquals("22/07/2026 14:30:45", formatted);
  }
}
