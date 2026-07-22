package smartfm.domain;

import smartfm.common.InvalidDataException;
import smartfm.common.Money;

/** State of an {@link Invoice} once a partial payment has reduced the balance, but not to zero. */
public class InvoicePartiallyPaidState extends InvoiceState {

  private static final long serialVersionUID = 1L;

  @Override
  public void applyPayment(Invoice invoice, double amount) {
    if (amount > invoice.getOutstandingBalance() + 0.001) {
      throw new InvalidDataException(
          "Payment amount " + Money.format(amount) + " exceeds outstanding balance "
              + Money.format(invoice.getOutstandingBalance()) + ".");
    }
    invoice.reduceOutstandingBalance(amount);
    if (invoice.getOutstandingBalance() <= 0.001) {
      invoice.setState(new InvoicePaidState());
    }
  }

  @Override
  public String name() {
    return "Partially Paid";
  }
}
