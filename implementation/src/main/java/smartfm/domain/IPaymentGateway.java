package smartfm.domain;

/**
 * Standard interface defining the programmatic contract for executing
 * and verifying payments through external financial gateways or
 * e-wallets. Corresponds to the {@code IPaymentGateway} decoupling
 * interface in Assignment 2 Section 3. As permitted by the Assignment 3
 * brief, the implementation does not perform real banking transactions;
 * concrete adapters simulate gateway verification and always report
 * success unless the caller explicitly forces a failure for testing.
 */
public interface IPaymentGateway {

  /**
   * Attempts to verify a transaction against the external gateway.
   *
   * @return {@code true} if the (simulated) gateway confirms the funds.
   */
  boolean verifyTransaction(String paymentId, double amount);
}
