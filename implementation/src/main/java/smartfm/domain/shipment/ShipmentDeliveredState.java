package smartfm.domain.shipment;

/** Terminal state of a {@link Shipment} once the consignments have been delivered. */
public class ShipmentDeliveredState extends ShipmentState {

  private static final long serialVersionUID = 1L;

  @Override
  public String name() {
    return "Delivered";
  }
}
