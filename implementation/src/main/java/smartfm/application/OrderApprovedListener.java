package smartfm.application;

import smartfm.domain.Order;

/**
 * Observer interface for the order-approved event published by {@link
 * OrderProcessor} (Gang-of-Four Observer pattern, Assignment 2 Section
 * 5.2.2). {@code DispatchManager} registers as a listener during
 * bootstrap so it can react to approvals without {@code OrderProcessor}
 * ever holding a direct reference to it.
 */
public interface OrderApprovedListener {

  void onOrderApproved(Order order);
}
