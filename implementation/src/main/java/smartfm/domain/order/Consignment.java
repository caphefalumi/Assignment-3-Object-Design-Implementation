package smartfm.domain.order;

import java.io.Serializable;
import smartfm.common.Validators;

/**
 * A specific package or set of goods included within a single order.
 * Corresponds to the {@code Consignment} CRC card in Assignment 2
 * Section 3 (Commercial and Ordering Package).
 */
public class Consignment implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private double weightKg;
  private double volumeM3;
  private boolean fragile;
  private boolean requiresRefrigeration;
  private String description;

  public Consignment(
      String id,
      double weightKg,
      double volumeM3,
      boolean fragile,
      boolean requiresRefrigeration,
      String description) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.weightKg = Validators.requirePositive(weightKg, "Consignment weight");
    this.volumeM3 = Validators.requirePositive(volumeM3, "Consignment volume");
    this.fragile = fragile;
    this.requiresRefrigeration = requiresRefrigeration;
    this.description = Validators.requireNonBlank(description, "Description", 120);
  }

  public String getId() {
    return id;
  }

  public double getWeightKg() {
    return weightKg;
  }

  public double getVolumeM3() {
    return volumeM3;
  }

  public boolean isFragile() {
    return fragile;
  }

  public boolean isRequiresRefrigeration() {
    return requiresRefrigeration;
  }

  public String getDescription() {
    return description;
  }

  @Override
  public String toString() {
    return description + " (" + weightKg + "kg, " + volumeM3 + "m3)";
  }
}
