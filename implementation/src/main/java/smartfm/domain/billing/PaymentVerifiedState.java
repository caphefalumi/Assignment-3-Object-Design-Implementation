package smartfm.domain.billing;

/** State of a {@link Payment} once the gateway (or cash handler) has confirmed the funds. */
public class PaymentVerifiedState extends PaymentState {

  private static final long serialVersionUID = 1L;

  @Override
  public void settle(Payment payment) {
    payment.setState(new PaymentSettledState());
  }

  @Override
  public String name() {
    return "Verified";
  }
}
