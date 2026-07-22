package smartfm.application;

import smartfm.domain.Invoice;

/**
 * Observer interface for the invoice-created event published by {@link
 * OrderProcessor} (Observer pattern, Assignment 2 Section 5.2.2). {@code
 * PaymentProcessor} registers as a listener during bootstrap so every
 * generated invoice is known to the payment workflow before a customer
 * can submit a payment against it.
 */
public interface InvoiceCreatedListener {

  void onInvoiceCreated(Invoice invoice);
}
