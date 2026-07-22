package smartfm.domain.shipment;

import java.io.Serializable;
import smartfm.common.InvalidDataException;

/**
 * Abstract base class defining the contract for {@link Shipment} transit
 * milestone states (Gang-of-Four State pattern, Assignment 2 Section
 * 5.2.3). Prevents invalid transitions such as marking a shipment
 * "Delivered" before it has been "Picked Up".
 */
public abstract class ShipmentState implements Serializable {

  private static final long serialVersionUID = 1L;

  public void pickUp(Shipment shipment) {
    throw new InvalidDataException("Cannot mark 'Picked Up' from state " + name() + ".");
  }

  public void transit(Shipment shipment) {
    throw new InvalidDataException("Cannot mark 'In Transit' from state " + name() + ".");
  }

  public void deliver(Shipment shipment) {
    throw new InvalidDataException("Cannot mark 'Delivered' from state " + name() + ".");
  }

  public abstract String name();

  @Override
  public String toString() {
    return name();
  }
}
