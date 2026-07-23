package smartfm.domain.order;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Order & Consignment Domain Package Tests")
class OrderAndConsignmentTest {

  private Order order;
  private Consignment consignment1;
  private Consignment consignment2;

  @BeforeEach
  void setUp() {
    order = new Order(
        "ORD-001",
        "CUST-001",
        "SVC-EXPRESS",
        "BR-MEL",
        "BR-SYD",
        880.0,
        LocalDate.now().plusDays(1));

    consignment1 = new Consignment("CNS-001", 10.5, 0.2, false, false, "Electronics Box");
    consignment2 = new Consignment("CNS-002", 15.0, 0.5, true, false, "Glassware Set");
  }

  @Test
  @DisplayName("Should initialize order in Submitted state and validate attributes")
  void testInitialOrderState() {
    assertEquals("ORD-001", order.getId());
    assertEquals("CUST-001", order.getCustomerId());
    assertEquals("SVC-EXPRESS", order.getServiceOfferingId());
    assertEquals("BR-MEL", order.getOriginBranchId());
    assertEquals("BR-SYD", order.getDestinationBranchId());
    assertEquals(880.0, order.getDistanceKm());
    assertNotNull(order.getCreatedAt());
    assertEquals("Submitted", order.getStateName());
    assertFalse(order.isApproved());
    assertEquals(0.0, order.getTotalWeightKg());
  }

  @Test
  @DisplayName("Should validate consignment fields and calculation")
  void testConsignmentFields() {
    assertEquals("CNS-001", consignment1.getId());
    assertEquals(10.5, consignment1.getWeightKg());
    assertEquals(0.2, consignment1.getVolumeM3());
    assertFalse(consignment1.isFragile());
    assertFalse(consignment1.isRequiresRefrigeration());
    assertEquals("Electronics Box", consignment1.getDescription());
    assertTrue(consignment1.toString().contains("Electronics Box"));

    assertTrue(consignment2.isFragile());

    assertThrows(InvalidDataException.class, () -> new Consignment("CNS-INV", -5.0, 0.1, false, false, "Invalid"));
    assertThrows(InvalidDataException.class, () -> new Consignment("CNS-INV", 5.0, -0.1, false, false, "Invalid"));
  }

  @Test
  @DisplayName("Should add consignments and accurately calculate total weight")
  void testAddConsignments() {
    order.addConsignment(consignment1);
    order.addConsignment(consignment2);

    assertEquals(2, order.getConsignments().size());
    assertEquals(25.5, order.getTotalWeightKg());
  }

  @Test
  @DisplayName("Should enforce requiring consignments before processing")
  void testRequireHasConsignments() {
    InvalidDataException ex = assertThrows(InvalidDataException.class, order::requireHasConsignments);
    assertEquals("An order must have at least one consignment.", ex.getMessage());

    order.addConsignment(consignment1);
    order.requireHasConsignments();
  }

  @Test
  @DisplayName("Should manage quoted amount and invoice ID binding")
  void testQuotedAmountAndInvoiceBinding() {
    order.setQuotedAmount(350.75);
    assertEquals(350.75, order.getQuotedAmount());

    assertThrows(InvalidDataException.class, () -> order.setQuotedAmount(-10.0));

    order.setInvoiceId("INV-999");
    assertEquals("INV-999", order.getInvoiceId());
  }

  @Test
  @DisplayName("Should transition order from Submitted to Approved")
  void testOrderApproveTransition() {
    order.addConsignment(consignment1);
    order.approve();

    assertEquals("Approved", order.getStateName());
    assertTrue(order.isApproved());
  }

  @Test
  @DisplayName("Should transition order from Submitted to Cancelled")
  void testOrderCancelTransition() {
    order.addConsignment(consignment1);
    order.cancel();

    assertEquals("Cancelled", order.getStateName());
    assertFalse(order.isApproved());
  }

  @Test
  @DisplayName("Should transition order from Submitted to Rejected")
  void testOrderRejectTransition() {
    order.addConsignment(consignment1);
    order.reject("Weight limit exceeded");

    assertTrue(order.getStateName().startsWith("Rejected"));
    assertFalse(order.isApproved());
  }

  @Test
  @DisplayName("Should prevent illegal state transitions across OrderState machine")
  void testIllegalOrderStateTransitions() {
    order.addConsignment(consignment1);
    order.cancel();

    assertThrows(InvalidDataException.class, order::approve);
    assertThrows(InvalidDataException.class, () -> order.reject("Reason"));

    Order order2 = new Order("ORD-002", "CUST-001", "SVC", "BR-1", "BR-2", 100.0, LocalDate.now());
    order2.addConsignment(consignment1);
    order2.approve();

    assertThrows(InvalidDataException.class, order2::cancel);
    assertThrows(InvalidDataException.class, () -> order2.reject("Reason"));
  }
}
