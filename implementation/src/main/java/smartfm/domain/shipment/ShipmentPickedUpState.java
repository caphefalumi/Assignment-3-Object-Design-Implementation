package smartfm.domain.shipment;

/** State of a {@link Shipment} once the driver has collected the consignments. */
public class ShipmentPickedUpState extends ShipmentState {

  private static final long serialVersionUID = 1L;

  @Override
  public void transit(Shipment shipment) {
    shipment.setState(new ShipmentInTransitState());
  }

  @Override
  public String name() {
    return "Picked Up";
  }
}
