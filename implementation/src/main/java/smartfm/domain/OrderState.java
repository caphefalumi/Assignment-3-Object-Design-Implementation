package smartfm.domain;

import java.io.Serializable;
import smartfm.common.InvalidDataException;

/**
 * Abstract base class defining the contract for {@link Order} lifecycle
 * states (Gang-of-Four State pattern, Assignment 2 Section 5.2.3).
 * Concrete subclasses encapsulate state-specific transition rules so
 * that {@code Order} never needs an if/else chain over a status flag.
 */
public abstract class OrderState implements Serializable {

  private static final long serialVersionUID = 1L;

  public void approve(Order order) {
    throw new InvalidDataException(
        "Cannot approve an order in state " + name() + ".");
  }

  public void reject(Order order, String reason) {
    throw new InvalidDataException(
        "Cannot reject an order in state " + name() + ".");
  }

  public void cancel(Order order) {
    throw new InvalidDataException(
        "Cannot cancel an order in state " + name() + ".");
  }

  public abstract String name();

  @Override
  public String toString() {
    return name();
  }
}
