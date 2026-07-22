package smartfm.application;

import smartfm.domain.shipment.Shipment;

/**
 * Observer interface for the shipment-created / resources-assigned
 * event published by {@link DispatchManager} (Observer pattern,
 * Assignment 2 Section 5.2.2). {@code ShipmentTracker} registers as a
 * listener during bootstrap so no vehicle-assignment event is missed
 * once dispatch begins creating shipments.
 */
public interface ShipmentAssignedListener {

  void onShipmentAssigned(Shipment shipment);
}
