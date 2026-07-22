package smartfm.domain;

import java.io.Serializable;
import smartfm.common.InvalidDataException;

/**
 * Abstract base class defining the contract for {@link Payment}
 * verification and settlement states (Gang-of-Four State pattern,
 * Assignment 2 Section 5.2.3).
 */
public abstract class PaymentState implements Serializable {

  private static final long serialVersionUID = 1L;

  public void verify(Payment payment) {
    throw new InvalidDataException("Cannot verify a payment in state " + name() + ".");
  }

  public void fail(Payment payment, String reason) {
    throw new InvalidDataException("Cannot fail a payment in state " + name() + ".");
  }

  public void settle(Payment payment) {
    throw new InvalidDataException("Cannot settle a payment in state " + name() + ".");
  }

  public abstract String name();

  @Override
  public String toString() {
    return name();
  }
}
