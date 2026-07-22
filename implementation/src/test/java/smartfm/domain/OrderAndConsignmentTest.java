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
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;

@DisplayName("Order & Consignment Domain Tests")
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
  @DisplayName("Should initialize order in Submitted state")
  void testInitialOrderState() {
    assertEquals("Submitted", order.getStateName());
    assertFalse(order.isApproved());
    assertEquals(0.0, order.getTotalWeightKg());
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
  @DisplayName("Should prevent approving a cancelled order")
  void testInvalidStateTransitionApproveCancelledOrder() {
    order.addConsignment(consignment1);
    order.cancel();

    InvalidDataException ex = assertThrows(InvalidDataException.class, order::approve);
    assertTrue(ex.getMessage().contains("Cannot approve"));
  }

  @Test
  @DisplayName("Should prevent cancelling an approved order")
  void testInvalidStateTransitionCancelApprovedOrder() {
    order.addConsignment(consignment1);
    order.approve();

    InvalidDataException ex = assertThrows(InvalidDataException.class, order::cancel);
    assertTrue(ex.getMessage().contains("Cannot cancel"));
  }
}
