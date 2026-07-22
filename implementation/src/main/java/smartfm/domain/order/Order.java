package smartfm.domain.order;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import smartfm.common.InvalidDataException;
import smartfm.common.Money;
import smartfm.common.Validators;

/**
 * The commercial contract and service request submitted by a customer.
 * Corresponds to the {@code Order} CRC card in Assignment 2 Section 3
 * (Commercial and Ordering Package). Delegates lifecycle transitions to
 * an {@link OrderState} instance (State pattern).
 */
public class Order implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String customerId;
  private final String serviceOfferingId;
  private final String originBranchId;
  private final String destinationBranchId;
  private final double distanceKm;
  private final LocalDate requestedPickupDate;
  private final LocalDateTime createdAt;
  private final List<Consignment> consignments = new ArrayList<>();
  private OrderState state;
  private double quotedAmount;
  private String invoiceId;

  public Order(
      String id,
      String customerId,
      String serviceOfferingId,
      String originBranchId,
      String destinationBranchId,
      double distanceKm,
      LocalDate requestedPickupDate) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.customerId = Validators.requireNonBlank(customerId, "Customer id", 20);
    this.serviceOfferingId = Validators.requireNonBlank(serviceOfferingId, "Service offering id", 20);
    this.originBranchId = Validators.requireNonBlank(originBranchId, "Origin branch id", 20);
    this.destinationBranchId = Validators.requireNonBlank(destinationBranchId, "Destination branch id", 20);
    this.distanceKm = Validators.requirePositive(distanceKm, "Distance");
    this.requestedPickupDate = requestedPickupDate;
    this.createdAt = LocalDateTime.now();
    this.state = new OrderSubmittedState();
  }

  public String getId() {
    return id;
  }

  public String getCustomerId() {
    return customerId;
  }

  public String getServiceOfferingId() {
    return serviceOfferingId;
  }

  public String getOriginBranchId() {
    return originBranchId;
  }

  public String getDestinationBranchId() {
    return destinationBranchId;
  }

  public double getDistanceKm() {
    return distanceKm;
  }

  public LocalDate getRequestedPickupDate() {
    return requestedPickupDate;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  /** An order must have at least one consignment before it can be submitted (Assn 2 A6). */
  public void addConsignment(Consignment consignment) {
    if (consignment == null) {
      throw new InvalidDataException("Consignment cannot be null.");
    }
    consignments.add(consignment);
  }

  public List<Consignment> getConsignments() {
    return Collections.unmodifiableList(consignments);
  }

  public double getTotalWeightKg() {
    return consignments.stream().mapToDouble(Consignment::getWeightKg).sum();
  }

  public void requireHasConsignments() {
    if (consignments.isEmpty()) {
      throw new InvalidDataException("An order must have at least one consignment.");
    }
  }

  public String getStateName() {
    return state.name();
  }

  /** Package-visible mutator used exclusively by {@link OrderState} subclasses. */
  void setState(OrderState state) {
    this.state = state;
  }

  public void approve() {
    state.approve(this);
  }

  public void reject(String reason) {
    state.reject(this, reason);
  }

  public void cancel() {
    state.cancel(this);
  }

  public boolean isApproved() {
    return state instanceof OrderApprovedState;
  }

  public double getQuotedAmount() {
    return quotedAmount;
  }

  public void setQuotedAmount(double quotedAmount) {
    this.quotedAmount = Validators.requireNonNegative(quotedAmount, "Quoted amount");
  }

  public String getInvoiceId() {
    return invoiceId;
  }

  public void setInvoiceId(String invoiceId) {
    this.invoiceId = invoiceId;
  }

  @Override
  public String toString() {
    return "Order " + id + " [" + state.name() + "] total=" + Money.format(quotedAmount) + " VND";
  }
}
