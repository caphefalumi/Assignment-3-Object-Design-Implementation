package smartfm.domain.billing;

/**
 * Terminal state of a {@link Payment} once settlement is complete.
 * Triggers issuance of an immutable {@link Receipt} (Assignment 2
 * Section 5.2.3).
 */
public class PaymentSettledState extends PaymentState {

  private static final long serialVersionUID = 1L;

  @Override
  public String name() {
    return "Settled";
  }
}
