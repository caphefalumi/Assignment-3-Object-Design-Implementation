package smartfm.domain;

import smartfm.common.Validators;

/**
 * Concrete {@link ITelemetrySource} adapter used by the textual UI in
 * place of physical GPS hardware. A driver or dispatcher types the
 * current location in the CLI, and this adapter normalises it into the
 * same contract that a real GPS device adapter would fulfil, so {@code
 * ShipmentTracker} does not need to change when real hardware is
 * connected later (Assignment 2 Section 5.3.2, Adapter pattern).
 */
public class ManualTelemetrySource implements ITelemetrySource {

  private String pendingLocation = "Unknown";

  /** Called by the CLI immediately before invoking the tracker. */
  public void stage(String rawLocationInput) {
    this.pendingLocation = Validators.requireNonBlank(rawLocationInput, "Location", 120);
  }

  @Override
  public String readLocation(String shipmentId) {
    Validators.requireNonBlank(shipmentId, "Shipment id", 20);
    return pendingLocation;
  }
}
