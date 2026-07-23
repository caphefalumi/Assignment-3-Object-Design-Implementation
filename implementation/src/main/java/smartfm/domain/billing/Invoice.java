package smartfm.domain.billing;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import smartfm.common.Money;
import smartfm.common.Validators;

/**
 * The billing document generated automatically upon order approval.
 * Corresponds to the {@code Invoice} CRC card in Assignment 2 Section 3
 * (Billing and Settlement Package). Delegates balance calculations to
 * an {@link InvoiceState} instance (State pattern).
 */
@SuppressWarnings("serial")
public class Invoice implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String orderId;
  private final double totalAmount;
  private double outstandingBalance;
  private final LocalDate dueDate;
  private final LocalDateTime createdAt;
  private InvoiceState state;
  private final List<String> paymentIds = new ArrayList<>();

  public Invoice(String id, String orderId, double totalAmount, LocalDate dueDate) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.orderId = Validators.requireNonBlank(orderId, "Order id", 20);
    this.totalAmount = Validators.requireNonNegative(totalAmount, "Total amount");
    this.outstandingBalance = this.totalAmount;
    this.dueDate = dueDate;
    this.createdAt = LocalDateTime.now();
    this.state = new InvoiceUnpaidState();
  }

  public String getId() {
    return id;
  }

  public String getOrderId() {
    return orderId;
  }

  public double getTotalAmount() {
    return totalAmount;
  }

  public double getOutstandingBalance() {
    return outstandingBalance;
  }

  public LocalDate getDueDate() {
    return dueDate;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public String getStateName() {
    return state.name();
  }

  /** Package-visible mutator used exclusively by {@link InvoiceState} subclasses. */
  void setState(InvoiceState state) {
    this.state = state;
  }

  /** Package-visible balance update used exclusively by {@link InvoiceState} subclasses. */
  void reduceOutstandingBalance(double amount) {
    this.outstandingBalance = Math.max(0.0, this.outstandingBalance - amount);
  }

  /**
   * Rejects any payment that exceeds the outstanding balance (Assignment 2
   * Section 1.3.2 boundary case), then delegates state transition logic.
   */
  public void applyPayment(String paymentId, double amount) {
    state.applyPayment(this, amount);
    paymentIds.add(paymentId);
  }

  public boolean isSettled() {
    return state instanceof InvoicePaidState;
  }

  /** Restores persisted billing state and payment links after a relational load. */
  public void restoreState(String persistedState, double persistedOutstandingBalance,
      List<String> persistedPaymentIds) {
    this.outstandingBalance = Math.max(0.0, persistedOutstandingBalance);
    this.paymentIds.clear();
    this.paymentIds.addAll(persistedPaymentIds);
    if ("Paid".equals(persistedState)) {
      state = new InvoicePaidState();
    } else if ("Partially Paid".equals(persistedState)) {
      state = new InvoicePartiallyPaidState();
    } else {
      state = new InvoiceUnpaidState();
    }
  }

  public List<String> getPaymentIds() {
    return Collections.unmodifiableList(paymentIds);
  }

  @Override
  public String toString() {
    return "Invoice " + id + " [" + state.name() + "] balance=" + Money.format(outstandingBalance)
        + "/" + Money.format(totalAmount) + " VND";
  }
}
