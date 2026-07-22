package smartfm.domain;

/**
 * Strategy interface defining the standard contract for interchangeable
 * payment methods (Assignment 2 Section 3, Design Pattern Abstraction
 * Package). Concrete strategies such as {@code CashPaymentStrategy} and
 * {@code GatewayPaymentStrategy} route verification differently without
 * changing {@link Payment} or {@link Invoice}.
 */
public interface IPaymentStrategy {

  /**
   * Executes and verifies a transaction for the given payment amount.
   *
   * @return {@code true} if the payment method confirms the funds.
   */
  boolean process(String paymentId, double amount);

  PaymentMethod getMethod();
}
