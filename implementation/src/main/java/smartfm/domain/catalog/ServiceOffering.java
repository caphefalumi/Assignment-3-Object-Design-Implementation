package smartfm.domain.catalog;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import smartfm.common.Validators;

/**
 * A defined logistics service tier available at one or more branches
 * (e.g. Cold Chain, Express, Standard Freight). Corresponds to the
 * {@code ServiceOffering} CRC card in Assignment 2 Section 3 (Service
 * and Pricing Catalog Package).
 */
@SuppressWarnings("serial")
public class ServiceOffering implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private String name;
  private String description;
  private final List<String> coveredBranchIds = new ArrayList<>();
  private String pricingTariffId;

  public ServiceOffering(String id, String name, String description) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.name = Validators.requireNonBlank(name, "Service name", 60);
    this.description = Validators.requireNonBlank(description, "Description", 200);
  }

  public String getId() {
    return id;
  }

  public String getName() {
    return name;
  }

  public String getDescription() {
    return description;
  }

  public void addCoveredBranch(String branchId) {
    if (!coveredBranchIds.contains(branchId)) {
      coveredBranchIds.add(branchId);
    }
  }

  public List<String> getCoveredBranchIds() {
    return Collections.unmodifiableList(coveredBranchIds);
  }

  public boolean isAvailableAt(String branchId) {
    return coveredBranchIds.contains(branchId);
  }

  public String getPricingTariffId() {
    return pricingTariffId;
  }

  public void setPricingTariffId(String pricingTariffId) {
    this.pricingTariffId = pricingTariffId;
  }

  @Override
  public String toString() {
    return name;
  }
}
