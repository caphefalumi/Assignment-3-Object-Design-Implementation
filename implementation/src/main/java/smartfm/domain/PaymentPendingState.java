package smartfm.domain;

/** Initial state of a {@link Payment} immediately after submission. */
public class PaymentPendingState extends PaymentState {

  private static final long serialVersionUID = 1L;

  @Override
  public void verify(Payment payment) {
    payment.setState(new PaymentVerifiedState());
  }

  @Override
  public void fail(Payment payment, String reason) {
    payment.setState(new PaymentFailedState(reason));
  }

  @Override
  public String name() {
    return "Pending";
  }
}
