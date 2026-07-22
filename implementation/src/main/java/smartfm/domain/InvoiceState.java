package smartfm.domain;

import java.io.Serializable;
import smartfm.common.InvalidDataException;

/**
 * Abstract base class defining the contract for {@link Invoice} billing
 * states (Gang-of-Four State pattern, Assignment 2 Section 5.2.3).
 * Concrete subclasses manage state-specific balance calculations.
 */
public abstract class InvoiceState implements Serializable {

  private static final long serialVersionUID = 1L;

  public void applyPayment(Invoice invoice, double amount) {
    throw new InvalidDataException("Cannot apply a payment to an invoice in state " + name() + ".");
  }

  public abstract String name();

  @Override
  public String toString() {
    return name();
  }
}
