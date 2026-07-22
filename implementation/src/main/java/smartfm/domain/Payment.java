package smartfm.domain;

import java.io.Serializable;
import java.time.LocalDateTime;
import smartfm.common.Validators;

/**
 * Records a single monetary transaction submitted to settle an {@link
 * Invoice}'s outstanding balance. Corresponds to the {@code Payment}
 * CRC card in Assignment 2 Section 3 (Billing and Settlement Package).
 * Delegates verification state transitions to a {@link PaymentState}
 * instance (State pattern).
 */
public class Payment implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String invoiceId;
  private final double amount;
  private final PaymentMethod method;
  private final LocalDateTime timestamp;
  private PaymentState state;
  private String receiptId;

  public Payment(String id, String invoiceId, double amount, PaymentMethod method) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.invoiceId = Validators.requireNonBlank(invoiceId, "Invoice id", 20);
    this.amount = Validators.requirePositive(amount, "Payment amount");
    this.method = method;
    this.timestamp = LocalDateTime.now();
    this.state = new PaymentPendingState();
  }

  public String getId() {
    return id;
  }

  public String getInvoiceId() {
    return invoiceId;
  }

  public double getAmount() {
    return amount;
  }

  public PaymentMethod getMethod() {
    return method;
  }

  public LocalDateTime getTimestamp() {
    return timestamp;
  }

  public String getStateName() {
    return state.name();
  }

  /** Package-visible mutator used exclusively by {@link PaymentState} subclasses. */
  void setState(PaymentState state) {
    this.state = state;
  }

  public void verify() {
    state.verify(this);
  }

  public void fail(String reason) {
    state.fail(this, reason);
  }

  public void settle() {
    state.settle(this);
  }

  public boolean isSettled() {
    return state instanceof PaymentSettledState;
  }

  public String getReceiptId() {
    return receiptId;
  }

  public void setReceiptId(String receiptId) {
    this.receiptId = receiptId;
  }

  @Override
  public String toString() {
    return "Payment " + id + " [" + state.name() + "] amount=" + amount + " via " + method;
  }
}
