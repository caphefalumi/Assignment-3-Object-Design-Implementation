package smartfm.domain;

/** State of a {@link Shipment} while it is actively en route to the destination. */
public class ShipmentInTransitState extends ShipmentState {

  private static final long serialVersionUID = 1L;

  @Override
  public void deliver(Shipment shipment) {
    shipment.setState(new ShipmentDeliveredState());
  }

  @Override
  public String name() {
    return "In Transit";
  }
}
