package smartfm.domain;

/**
 * Standard interface defining the programmatic contract for receiving
 * and normalising GPS tracking telemetry from third-party hardware
 * devices (Assignment 2 Section 3, decoupling interface). Isolates
 * {@code ShipmentTracker} from any one GPS vendor's protocol.
 */
public interface ITelemetrySource {

  /** Returns a normalised, human-readable location string for the given shipment. */
  String readLocation(String shipmentId);
}
