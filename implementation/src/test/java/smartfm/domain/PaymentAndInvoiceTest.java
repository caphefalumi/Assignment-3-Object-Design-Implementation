package smartfm.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;
import smartfm.domain.billing.CashPaymentStrategy;
import smartfm.domain.billing.GatewayPaymentStrategy;
import smartfm.domain.billing.IPaymentGateway;
import smartfm.domain.billing.IPaymentStrategy;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.billing.SimulatedGatewayAdapter;

@DisplayName("Payment & Invoice Domain Tests")
class PaymentAndInvoiceTest {

  private Invoice invoice;

  @BeforeEach
  void setUp() {
    invoice = new Invoice("INV-001", "ORD-001", 500.0, LocalDate.now().plusDays(30));
  }

  @Test
  @DisplayName("Should initialize invoice as Unpaid with full balance outstanding")
  void testInitialInvoiceState() {
    assertEquals("Unpaid", invoice.getStateName());
    assertEquals(500.0, invoice.getOutstandingBalance(), 0.01);
    assertFalse(invoice.isSettled());
  }

  @Test
  @DisplayName("Should transition to Partially Paid on partial payment")
  void testPartialPayment() {
    invoice.applyPayment("PAY-001", 200.0);

    assertEquals("Partially Paid", invoice.getStateName());
    assertEquals(300.0, invoice.getOutstandingBalance(), 0.01);
    assertFalse(invoice.isSettled());
    assertEquals(1, invoice.getPaymentIds().size());
  }

  @Test
  @DisplayName("Should transition to Paid on full settlement")
  void testFullPayment() {
    invoice.applyPayment("PAY-001", 200.0);
    invoice.applyPayment("PAY-002", 300.0);

    assertEquals("Paid", invoice.getStateName());
    assertEquals(0.0, invoice.getOutstandingBalance(), 0.01);
    assertTrue(invoice.isSettled());
    assertEquals(2, invoice.getPaymentIds().size());
  }

  @Test
  @DisplayName("Should reject payments exceeding outstanding balance")
  void testOverpaymentRejection() {
    InvalidDataException ex = assertThrows(
        InvalidDataException.class,
        () -> invoice.applyPayment("PAY-001", 600.0));
    assertTrue(ex.getMessage().contains("exceeds outstanding balance"));
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
