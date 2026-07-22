package smartfm.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.billing.Receipt;
import smartfm.infrastructure.DataStore;

@DisplayName("PaymentProcessor Application Controller Tests")
class PaymentProcessorTest {

  private DataStore store;
  private PaymentProcessor paymentProcessor;
  private Invoice invoice;

  @BeforeEach
  void setUp() {
    store = new DataStore();
    paymentProcessor = new PaymentProcessor(store);

    invoice = new Invoice("INV-001", "ORD-001", 300.0, LocalDate.now().plusDays(30));
    store.invoices().put("INV-001", invoice);
    paymentProcessor.onInvoiceCreated(invoice);
  }

  @Test
  @DisplayName("Should process cash payment, apply to invoice, and issue receipt")
  void testSubmitCashPayment() {
    Receipt receipt = paymentProcessor.submitPayment("INV-001", 300.0, PaymentMethod.CASH);

    assertNotNull(receipt);
    assertEquals("INV-001", receipt.getInvoiceId());
    assertEquals(300.0, receipt.getAmountSettled(), 0.01);
    assertEquals("Paid", invoice.getStateName());
    assertEquals(1, store.payments().size());
    assertEquals(1, store.receipts().size());
  }

  @Test
  @DisplayName("Should process partial payment via credit card")
  void testSubmitPartialCardPayment() {
    Receipt receipt = paymentProcessor.submitPayment("INV-001", 100.0, PaymentMethod.CARD);

    assertNotNull(receipt);
    assertEquals(100.0, receipt.getAmountSettled(), 0.01);
    assertEquals("Partially Paid", invoice.getStateName());
    assertEquals(200.0, invoice.getOutstandingBalance(), 0.01);
  }

  @Test
  @DisplayName("Should reject payment exceeding outstanding invoice balance")
  void testRejectOverpayment() {
    assertThrows(InvalidDataException.class,
        () -> paymentProcessor.submitPayment("INV-001", 350.0, PaymentMethod.CASH));
  }

  @Test
  @DisplayName("Should reject payment on already fully settled invoice")
  void testRejectPaymentOnSettledInvoice() {
    paymentProcessor.submitPayment("INV-001", 300.0, PaymentMethod.CASH);

    assertThrows(InvalidDataException.class,
        () -> paymentProcessor.submitPayment("INV-001", 10.0, PaymentMethod.CASH));
  }
}
