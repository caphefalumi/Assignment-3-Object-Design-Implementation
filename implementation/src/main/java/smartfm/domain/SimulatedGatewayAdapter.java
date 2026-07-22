package smartfm.domain;

/**
 * Concrete {@link IPaymentGateway} adapter standing in for a real
 * third-party processor (e.g. Stripe, VNPAY, MoMo per Assignment 1
 * Assumptions). As explicitly permitted by the Assignment 3 brief,
 * "the implementation does not need to support payment options as we
 * cannot have a banking system to validate transactions" - this adapter
 * simulates a successful gateway response for any positive amount, and
 * a forced failure only when the amount is non-positive or an odd-cent
 * "declined" test amount is supplied. Isolating this behind the Adapter
 * pattern means a future real integration only requires a new class
 * implementing {@link IPaymentGateway}, with no change to {@link
 * Payment}, {@link Invoice}, or the payment controller.
 */
public class SimulatedGatewayAdapter implements IPaymentGateway {

  @Override
  public boolean verifyTransaction(String paymentId, double amount) {
    return amount > 0;
  }
}
