package smartfm.domain.report;

/**
 * Categories of administrative and operational reports supported by the system.
 * Corresponds to Assumption A13 in Assignment 2 Section 1.3.
 */
public enum ReportCategory {
  FINANCIAL("Financial & Revenue Summary"),
  FLEET("Fleet & Dispatch Utilization"),
  BRANCH("Branch Operations Summary"),
  ORDER_SUMMARY("Order & Commercial Summary");

  private final String displayName;

  ReportCategory(String displayName) {
    this.displayName = displayName;
  }

  public String getDisplayName() {
    return displayName;
  }

  @Override
  public String toString() {
    return displayName;
  }
}
