package smartfm.domain;

import java.io.Serializable;
import smartfm.common.Validators;

/**
 * The pricing formulas and rates governing a {@link ServiceOffering}
 * under specific cargo and distance conditions. Corresponds to the
 * {@code PricingTariff} CRC card in Assignment 2 Section 3 (Service and
 * Pricing Catalog Package). Acts as the concrete {@link IPricingStrategy}
 * for the Strategy pattern described in Assignment 2 Section 5.2.1.
 */
public class PricingTariff implements IPricingStrategy, Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String serviceOfferingId;
  private double baseRate;
  private double perKmRate;
  private double perKgRate;
  private double peakMultiplier;

  public PricingTariff(
      String id,
      String serviceOfferingId,
      double baseRate,
      double perKmRate,
      double perKgRate,
      double peakMultiplier) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.serviceOfferingId = Validators.requireNonBlank(serviceOfferingId, "Service offering id", 20);
    this.baseRate = Validators.requireNonNegative(baseRate, "Base rate");
    this.perKmRate = Validators.requireNonNegative(perKmRate, "Per-km rate");
    this.perKgRate = Validators.requireNonNegative(perKgRate, "Per-kg rate");
    this.peakMultiplier = peakMultiplier <= 0 ? 1.0 : peakMultiplier;
  }

  public String getId() {
    return id;
  }

  public String getServiceOfferingId() {
    return serviceOfferingId;
  }

  public double getBaseRate() {
    return baseRate;
  }

  public double getPerKmRate() {
    return perKmRate;
  }

  public double getPerKgRate() {
    return perKgRate;
  }

  public double getPeakMultiplier() {
    return peakMultiplier;
  }

  /**
   * Calculates a shipping quote for the given distance and total cargo
   * weight. Implements the {@link IPricingStrategy} contract so that
   * {@code ServiceOffering} can be extended later with alternative
   * pricing strategies (e.g. peak-hour pricing) without modification.
   */
  @Override
  public double calculateQuote(double distanceKm, double totalWeightKg, boolean isPeakPeriod) {
    Validators.requireNonNegative(distanceKm, "Distance");
    Validators.requireNonNegative(totalWeightKg, "Total weight");
    double quote = baseRate + (distanceKm * perKmRate) + (totalWeightKg * perKgRate);
    if (isPeakPeriod) {
      quote *= peakMultiplier;
    }
    return Math.round(quote * 100.0) / 100.0;
  }
}
