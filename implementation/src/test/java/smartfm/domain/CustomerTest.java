package smartfm.domain;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Customer Domain Tests")
class CustomerTest {

  private Customer customer;

  @BeforeEach
  void setUp() {
    customer = new Customer(
        "CUST-001",
        "Alice Smith",
        "Female",
        LocalDate.of(1990, 5, 12),
        "+61412345678",
        "alice.smith@example.com",
        "123 Collins St, Melbourne VIC 3000");
  }

  @Test
  @DisplayName("Should initialize customer with active status and empty order history")
  void testCustomerInitialization() {
    assertEquals("CUST-001", customer.getId());
    assertEquals("Alice Smith", customer.getFullName());
    assertEquals(CustomerStatus.ACTIVE, customer.getStatus());
    assertEquals(0, customer.getOrderIds().size());
  }

  @Test
  @DisplayName("Should record customer orders")
  void testRecordOrder() {
    customer.recordOrder("ORD-101");
    customer.recordOrder("ORD-102");

    assertEquals(2, customer.getOrderIds().size());
    assertEquals("ORD-101", customer.getOrderIds().get(0));
    assertEquals("ORD-102", customer.getOrderIds().get(1));
  }

  @Test
  @DisplayName("Should allow updating customer status")
  void testUpdateStatus() {
    customer.setStatus(CustomerStatus.SUSPENDED);
    assertEquals(CustomerStatus.SUSPENDED, customer.getStatus());
  }
}
