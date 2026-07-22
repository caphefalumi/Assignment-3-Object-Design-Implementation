package smartfm.domain;

/** Initial state of a {@link Shipment} once a vehicle and driver have been assigned. */
public class ShipmentAssignedState extends ShipmentState {

  private static final long serialVersionUID = 1L;

  @Override
  public void pickUp(Shipment shipment) {
    shipment.setState(new ShipmentPickedUpState());
  }

  @Override
  public String name() {
    return "Assigned";
  }
}
