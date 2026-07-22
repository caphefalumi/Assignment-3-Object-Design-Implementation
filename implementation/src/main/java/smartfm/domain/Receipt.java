package smartfm.domain;

import java.io.Serializable;
import java.time.LocalDateTime;
import smartfm.common.Validators;

/**
 * An immutable proof-of-payment document generated once a {@link
 * Payment} reaches the Settled state. Corresponds to the {@code
 * Receipt} CRC card in Assignment 2 Section 3 (Billing and Settlement
 * Package). All fields are {@code final}: once constructed, a Receipt
 * cannot be edited, satisfying Assumption A8.
 */
public final class Receipt implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private final String paymentId;
  private final String invoiceId;
  private final double amountSettled;
  private final LocalDateTime issuedAt;

  public Receipt(String id, String paymentId, String invoiceId, double amountSettled) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.paymentId = Validators.requireNonBlank(paymentId, "Payment id", 20);
    this.invoiceId = Validators.requireNonBlank(invoiceId, "Invoice id", 20);
    this.amountSettled = Validators.requirePositive(amountSettled, "Amount settled");
    this.issuedAt = LocalDateTime.now();
  }

  public String getId() {
    return id;
  }

  public String getPaymentId() {
    return paymentId;
  }

  public String getInvoiceId() {
    return invoiceId;
  }

  public double getAmountSettled() {
    return amountSettled;
  }

  public LocalDateTime getIssuedAt() {
    return issuedAt;
  }

  @Override
  public String toString() {
    return "Receipt " + id + " for Payment " + paymentId + " amount=" + amountSettled
        + " issued=" + issuedAt;
  }
}
