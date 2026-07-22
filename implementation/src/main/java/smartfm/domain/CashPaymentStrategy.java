package smartfm.domain;

/**
 * Concrete {@link IPaymentStrategy} for cash collected in-branch by a
 * staff member (Assumption A12). Cash is recorded as verified
 * immediately since no external gateway round-trip is required.
 */
public class CashPaymentStrategy implements IPaymentStrategy {

  @Override
  public boolean process(String paymentId, double amount) {
    return amount > 0;
  }

  @Override
  public PaymentMethod getMethod() {
    return PaymentMethod.CASH;
  }
}
