package smartfm.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Pricing Tariff Domain Tests")
class PricingTariffTest {

  private PricingTariff tariff;

  @BeforeEach
  void setUp() {
    // Base $50, $1.50 per km, $2.00 per kg, peak multiplier 1.2
    tariff = new PricingTariff("TARIFF-STD", "SVC-EXPRESS", 50.0, 1.5, 2.0, 1.2);
  }

  @Test
  @DisplayName("Should calculate standard shipping quote correctly")
  void testCalculateQuoteStandardPeriod() {
    // Distance = 100km, Weight = 20kg
    // Quote = 50 + (100 * 1.5) + (20 * 2.0) = 50 + 150 + 40 = 240.0
    double quote = tariff.calculateQuote(100.0, 20.0, false);
    assertEquals(240.0, quote, 0.01);
  }

  @Test
  @DisplayName("Should apply peak multiplier during peak periods")
  void testCalculateQuotePeakPeriod() {
    // Standard quote = 240.0, Peak = 240 * 1.2 = 288.0
    double quote = tariff.calculateQuote(100.0, 20.0, true);
    assertEquals(288.0, quote, 0.01);
  }

  @Test
  @DisplayName("Should reject negative distance or weight when calculating quote")
  void testCalculateQuoteNegativeParameters() {
    assertThrows(InvalidDataException.class, () -> tariff.calculateQuote(-10.0, 20.0, false));
    assertThrows(InvalidDataException.class, () -> tariff.calculateQuote(100.0, -5.0, false));
  }
}
