package smartfm.domain.report;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import smartfm.common.Validators;

/**
 * Represents an administrative summary report compiling system metrics across
 * domain entities (Branch, Order, Shipment, Payment, Vehicle, Driver).
 * Corresponds to the {@code Report} CRC card in Assignment 2 Section 3
 * (System Control and Configuration Package) and Assumption A13.
 */
@SuppressWarnings("serial")
public class Report implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String title;
  private final ReportCategory category;
  private final LocalDateTime generatedAt;
  private final LocalDate startDate;
  private final LocalDate endDate;
  private final Map<String, String> metrics = new LinkedHashMap<>();
  private final String content;

  public Report(
      String id,
      String title,
      ReportCategory category,
      LocalDate startDate,
      LocalDate endDate,
      Map<String, String> metrics,
      String content) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.title = Validators.requireNonBlank(title, "Title", 100);
    this.category = category != null ? category : ReportCategory.FINANCIAL;
    this.startDate = startDate;
    this.endDate = endDate;
    this.generatedAt = LocalDateTime.now();
    if (metrics != null) {
      this.metrics.putAll(metrics);
    }
    this.content = content != null ? content : "";
  }

  public String getId() {
    return id;
  }

  public String getTitle() {
    return title;
  }

  public ReportCategory getCategory() {
    return category;
  }

  public LocalDateTime getGeneratedAt() {
    return generatedAt;
  }

  public LocalDate getStartDate() {
    return startDate;
  }

  public LocalDate getEndDate() {
    return endDate;
  }

  public Map<String, String> getMetrics() {
    return Collections.unmodifiableMap(metrics);
  }

  public String getContent() {
    return content;
  }

  @Override
  public String toString() {
    return title + " (" + id + ") generated at " + generatedAt;
  }
}
