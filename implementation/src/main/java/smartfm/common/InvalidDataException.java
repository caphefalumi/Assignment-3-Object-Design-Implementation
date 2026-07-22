package smartfm.common;

/**
 * Thrown when a domain class rejects data that fails its own validation
 * rules (e.g. a blank required field, a non-positive weight, a payment
 * that exceeds an invoice's outstanding balance, or an out-of-order
 * lifecycle transition such as marking a shipment "Delivered" before it
 * has been "Picked Up").
 *
 * <p>Kept as a single, shared checked-free runtime exception rather than
 * one exception type per class, matching Assignment 2 Section 1.3.2.
 */
public class InvalidDataException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  public InvalidDataException(String message) {
    super(message);
  }
}
