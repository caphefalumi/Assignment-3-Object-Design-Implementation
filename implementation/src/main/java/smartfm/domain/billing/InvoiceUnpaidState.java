package smartfm.domain.billing;

import smartfm.common.InvalidDataException;
import smartfm.common.Money;

/** Initial state of an {@link Invoice}: nothing has been paid yet. */
public class InvoiceUnpaidState extends InvoiceState {

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
    } else {
      invoice.setState(new InvoicePartiallyPaidState());
    }
  }

  @Override
  public String name() {
    return "Unpaid";
  }
}
