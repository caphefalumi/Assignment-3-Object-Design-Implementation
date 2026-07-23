package smartfm.domain.billing;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Invoice, Payment & Receipt Domain Package Tests")
class InvoicePaymentAndReceiptTest {

  private Invoice invoice;

  @BeforeEach
  void setUp() {
    invoice = new Invoice("INV-001", "ORD-001", 500.0, LocalDate.now().plusDays(30));
  }

  @Test
  @DisplayName("Should initialize invoice with Unpaid state and full outstanding balance")
  void testInitialInvoiceState() {
    assertEquals("INV-001", invoice.getId());
    assertEquals("ORD-001", invoice.getOrderId());
    assertEquals(500.0, invoice.getTotalAmount(), 0.01);
    assertEquals(500.0, invoice.getOutstandingBalance(), 0.01);
    assertNotNull(invoice.getDueDate());
    assertNotNull(invoice.getCreatedAt());
    assertEquals("Unpaid", invoice.getStateName());
    assertFalse(invoice.isSettled());
    assertTrue(invoice.toString().contains("Unpaid"));
  }

  @Test
  @DisplayName("Should transition invoice to Partially Paid on partial payment")
  void testPartialPayment() {
    invoice.applyPayment("PAY-001", 200.0);

    assertEquals("Partially Paid", invoice.getStateName());
    assertEquals(300.0, invoice.getOutstandingBalance(), 0.01);
    assertFalse(invoice.isSettled());
    assertEquals(1, invoice.getPaymentIds().size());
  }

  @Test
  @DisplayName("Should transition invoice to Paid on full settlement")
  void testFullPayment() {
    invoice.applyPayment("PAY-001", 200.0);
    invoice.applyPayment("PAY-002", 300.0);

    assertEquals("Paid", invoice.getStateName());
    assertEquals(0.0, invoice.getOutstandingBalance(), 0.01);
    assertTrue(invoice.isSettled());
    assertEquals(2, invoice.getPaymentIds().size());
  }

  @Test
  @DisplayName("Should reject payment exceeding outstanding balance")
  void testOverpaymentRejection() {
    InvalidDataException ex = assertThrows(
        InvalidDataException.class,
        () -> invoice.applyPayment("PAY-001", 600.0));
    assertTrue(ex.getMessage().contains("exceeds outstanding balance"));
  }

  @Test
  @DisplayName("Should manage Payment entity state transitions")
  void testPaymentStateLifecycle() {
    Payment payment = new Payment("PAY-100", "INV-001", 250.0, PaymentMethod.CARD);

    assertEquals("PAY-100", payment.getId());
    assertEquals("INV-001", payment.getInvoiceId());
    assertEquals(250.0, payment.getAmount(), 0.01);
    assertEquals(PaymentMethod.CARD, payment.getMethod());
    assertEquals("Pending", payment.getStateName());
    assertNull(payment.getReceiptId());

    payment.verify();
    assertEquals("Verified", payment.getStateName());

    payment.settle();
    assertEquals("Settled", payment.getStateName());

    payment.setReceiptId("RCT-100");
    assertEquals("RCT-100", payment.getReceiptId());
  }

  @Test
  @DisplayName("Should handle failed payment state")
  void testFailedPaymentState() {
    Payment payment = new Payment("PAY-ERR", "INV-001", 100.0, PaymentMethod.DIGITAL_WALLET);
    payment.fail("Declined by issuing bank");

    assertTrue(payment.getStateName().startsWith("Failed"));
  }

  @Test
  @DisplayName("Should create immutable Receipt document")
  void testReceiptCreation() {
    Receipt receipt = new Receipt("RCT-001", "PAY-100", "INV-001", 250.0);

    assertEquals("RCT-001", receipt.getId());
    assertEquals("PAY-100", receipt.getPaymentId());
    assertEquals("INV-001", receipt.getInvoiceId());
    assertEquals(250.0, receipt.getAmountSettled(), 0.01);
    assertNotNull(receipt.getIssuedAt());
    assertTrue(receipt.toString().contains("RCT-001"));
  }

  @Test
  @DisplayName("Should process cash payment strategy successfully")
  void testCashPaymentStrategy() {
    IPaymentStrategy strategy = new CashPaymentStrategy();
    boolean success = strategy.process("PAY-CASH-1", 150.0);

    assertTrue(success);
    assertEquals(PaymentMethod.CASH, strategy.getMethod());
  }

  @Test
  @DisplayName("Should process payment gateway strategy using adapter")
  void testGatewayPaymentStrategy() {
    IPaymentGateway gateway = new SimulatedGatewayAdapter();
    IPaymentStrategy strategy = new GatewayPaymentStrategy(gateway, PaymentMethod.CARD);

    boolean success = strategy.process("PAY-CARD-1", 250.0);

    assertTrue(success);
    assertEquals(PaymentMethod.CARD, strategy.getMethod());
  }
}
