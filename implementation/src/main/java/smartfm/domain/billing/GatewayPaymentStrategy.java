package smartfm.domain.billing;

import smartfm.common.Validators;

/**
 * Concrete {@link IPaymentStrategy} for digital card / e-wallet
 * payments. Delegates the actual verification call to an {@link
 * IPaymentGateway} adapter (Adapter pattern, Assignment 2 Section
 * 5.3.2), keeping {@code Payment} unaware of gateway protocol details.
 */
public class GatewayPaymentStrategy implements IPaymentStrategy {

  private final IPaymentGateway gateway;
  private final PaymentMethod method;

  public GatewayPaymentStrategy(IPaymentGateway gateway, PaymentMethod method) {
    if (gateway == null) {
      throw new IllegalArgumentException("gateway cannot be null");
    }
    this.gateway = gateway;
    this.method = method == null ? PaymentMethod.CARD : method;
  }

  @Override
  public boolean process(String paymentId, double amount) {
    Validators.requireNonBlank(paymentId, "Payment id", 20);
    return gateway.verifyTransaction(paymentId, amount);
  }

  @Override
  public PaymentMethod getMethod() {
    return method;
  }
}
