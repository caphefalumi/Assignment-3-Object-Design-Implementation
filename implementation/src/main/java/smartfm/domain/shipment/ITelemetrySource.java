package smartfm.domain.shipment;

/**
 * Standard interface defining the programmatic contract for receiving
 * and normalising GPS tracking telemetry from third-party hardware
 * devices (Assignment 2 Section 3, decoupling interface). Isolates
 * {@code ShipmentTracker} from any one GPS vendor's protocol.
 */
public interface ITelemetrySource {

  /**
   * Supplies a manually entered location when the source needs an input value.
   * Hardware-backed sources can ignore it because they already receive their own feed.
   */
  default void stageLocation(String shipmentId, String rawLocation) {
    // External telemetry sources do not require a manually staged location.
  }

  /** Returns a normalised, human-readable location string for the given shipment. */
  String readLocation(String shipmentId);
}
