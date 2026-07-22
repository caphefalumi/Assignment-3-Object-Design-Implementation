package smartfm.domain.billing;

/** Terminal state of an {@link Invoice} once the outstanding balance has reached zero. */
public class InvoicePaidState extends InvoiceState {

  private static final long serialVersionUID = 1L;

  @Override
  public String name() {
    return "Paid";
  }
}
