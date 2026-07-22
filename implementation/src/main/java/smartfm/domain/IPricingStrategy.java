package smartfm.domain;

/**
 * Strategy interface for interchangeable pricing/tariff calculation
 * policies. Corresponds to Assignment 2 Section 3 (Design Pattern
 * Abstraction Package). Concrete strategies (e.g. {@link PricingTariff},
 * or a future {@code PeakPricingStrategy}) can be swapped in without
 * changing {@code ServiceOffering} or {@code Order}.
 */
public interface IPricingStrategy {

  double calculateQuote(double distanceKm, double totalWeightKg, boolean isPeakPeriod);
}
