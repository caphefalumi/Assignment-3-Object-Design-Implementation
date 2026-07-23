package smartfm.domain.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Catalog & Pricing Domain Package Tests")
class ServiceCatalogAndTariffTest {

  private ServiceOffering serviceOffering;
  private PricingTariff tariff;

  @BeforeEach
  void setUp() {
    serviceOffering = new ServiceOffering("SVC-EXP", "Same-Day Express", "Expedited delivery within business hours.");
    serviceOffering.addCoveredBranch("BR-MEL");
    serviceOffering.addCoveredBranch("BR-SYD");
    serviceOffering.setPricingTariffId("TAR-EXP");

    tariff = new PricingTariff("TAR-EXP", "SVC-EXP", 50.0, 1.5, 2.0, 1.2);
  }

  @Test
  @DisplayName("Should initialize ServiceOffering and manage covered branches")
  void testServiceOfferingOperations() {
    assertEquals("SVC-EXP", serviceOffering.getId());
    assertEquals("Same-Day Express", serviceOffering.getName());
    assertEquals("Expedited delivery within business hours.", serviceOffering.getDescription());
    assertEquals("TAR-EXP", serviceOffering.getPricingTariffId());

    assertEquals(2, serviceOffering.getCoveredBranchIds().size());
    assertTrue(serviceOffering.isAvailableAt("BR-MEL"));
    assertTrue(serviceOffering.isAvailableAt("BR-SYD"));
    assertFalse(serviceOffering.isAvailableAt("BR-BNE"));

    assertTrue(serviceOffering.toString().contains("Same-Day Express"));
  }

  @Test
  @DisplayName("Should initialize PricingTariff and calculate quotes for standard and peak periods")
  void testPricingTariffOperations() {
    assertEquals("TAR-EXP", tariff.getId());
    assertEquals("SVC-EXP", tariff.getServiceOfferingId());
    assertEquals(50.0, tariff.getBaseRate());
    assertEquals(1.5, tariff.getPerKmRate());
    assertEquals(2.0, tariff.getPerKgRate());
    assertEquals(1.2, tariff.getPeakMultiplier());

    // Distance = 100km, Weight = 20kg
    // Standard Quote = 50 + (100 * 1.5) + (20 * 2.0) = 240.0
    double standardQuote = tariff.calculateQuote(100.0, 20.0, false);
    assertEquals(240.0, standardQuote, 0.01);

    // Peak Quote = 240.0 * 1.2 = 288.0
    double peakQuote = tariff.calculateQuote(100.0, 20.0, true);
    assertEquals(288.0, peakQuote, 0.01);

    // Validation checks
    assertThrows(InvalidDataException.class, () -> tariff.calculateQuote(-10.0, 20.0, false));
    assertThrows(InvalidDataException.class, () -> tariff.calculateQuote(100.0, -5.0, false));
  }

  @Test
  @DisplayName("Should execute SystemConfiguration singleton bootstrap and properties")
  void testSystemConfiguration() {
    SystemConfiguration config = SystemConfiguration.bootstrap();
    assertNotNull(config);
    assertEquals(5, config.getMaxFailedLoginAttempts());
    assertEquals(1.2, config.getDefaultPeakMultiplier());
    assertEquals(30, config.getSessionTimeoutMinutes());
  }
}
