package smartfm.application;

import java.util.HashMap;
import java.util.Map;
import smartfm.common.InvalidDataException;
import smartfm.common.Money;
import smartfm.domain.CashPaymentStrategy;
import smartfm.domain.GatewayPaymentStrategy;
import smartfm.domain.IPaymentGateway;
import smartfm.domain.IPaymentStrategy;
import smartfm.domain.Invoice;
import smartfm.domain.Payment;
import smartfm.domain.PaymentMethod;
import smartfm.domain.Receipt;
import smartfm.domain.SimulatedGatewayAdapter;
import smartfm.infrastructure.DataStore;

/**
 * Coordinating controller managing payment settlement and receipt
 * issuance. Corresponds to the {@code PaymentProcessor} CRC card in
 * Assignment 2 Section 3 (System Control and Configuration Package).
 * Implements {@link InvoiceCreatedListener} to react to new invoices
 * (Observer pattern), routes transactions through interchangeable
 * {@link IPaymentStrategy} implementations (Strategy pattern, Assignment
 * 2 Section 5.2.1), and acts as the Factory Method for {@code Payment}
 * and {@code Receipt} (Assignment 2 Section 5.1.1).
 *
 * <p>This is one of the four controllers implemented for Assignment 3's
 * "Business Area 4: Billing and Payment". Depends on Business Area 1
 * (an invoice is only known to this controller once {@code
 * OrderProcessor} approves an order and publishes the invoice-created
 * event). As required by the Assignment 3 brief, no real banking
 * system validates these transactions: the gateway/cash strategies
 * below simulate verification and only reject non-positive amounts.
 */
public class PaymentProcessor implements InvoiceCreatedListener {

  private final DataStore store;
  private final IdGenerator paymentIds;
  private final IdGenerator receiptIds;
  private final Map<String, Invoice> knownInvoices = new HashMap<>();
  private final IPaymentGateway gateway = new SimulatedGatewayAdapter();

  public PaymentProcessor(DataStore store) {
    this.store = store;
    this.paymentIds = new IdGenerator("PAY", store.payments());
    this.receiptIds = new IdGenerator("RCT", store.receipts());
  }

  @Override
  public void onInvoiceCreated(Invoice invoice) {
    knownInvoices.put(invoice.getId(), invoice);
  }

  private IPaymentStrategy strategyFor(PaymentMethod method) {
    if (method == PaymentMethod.CASH) {
      return new CashPaymentStrategy();
    }
    return new GatewayPaymentStrategy(gateway, method);
  }

  /**
   * Steps 1-6 of Scenario 4: validates the requested amount against the
   * invoice's outstanding balance, routes the transaction through the
   * chosen strategy, and - only once settled - issues an immutable
   * {@code Receipt}.
   */
  public Receipt submitPayment(String invoiceId, double amount, PaymentMethod method) {
    Invoice invoice = store.invoices().get(invoiceId);
    if (invoice == null) {
      throw new InvalidDataException("Unknown invoice id '" + invoiceId + "'.");
    }
    if (invoice.isSettled()) {
      throw new InvalidDataException("Invoice " + invoiceId + " is already fully paid.");
    }
    if (amount > invoice.getOutstandingBalance() + 0.001) {
      throw new InvalidDataException(
          "Payment amount " + Money.format(amount) + " exceeds the outstanding balance of "
              + Money.format(invoice.getOutstandingBalance()) + " on invoice " + invoiceId + ".");
    }

    Payment payment = new Payment(paymentIds.next(), invoiceId, amount, method);
    store.payments().put(payment.getId(), payment);

    IPaymentStrategy strategy = strategyFor(method);
    boolean confirmed = strategy.process(payment.getId(), amount);
    if (!confirmed) {
      payment.fail("Gateway declined the transaction.");
      throw new InvalidDataException(
          "Payment " + payment.getId() + " was declined by the " + method + " channel.");
    }

    payment.verify();
    payment.settle();
    invoice.applyPayment(payment.getId(), amount);

    Receipt receipt = new Receipt(receiptIds.next(), payment.getId(), invoiceId, amount);
    store.receipts().put(receipt.getId(), receipt);
    payment.setReceiptId(receipt.getId());
    return receipt;
  }
}
