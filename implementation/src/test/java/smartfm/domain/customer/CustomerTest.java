package smartfm.domain.customer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.InvalidDataException;

@DisplayName("Customer Domain Package Tests")
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
  @DisplayName("Should initialize customer with active status and valid attributes")
  void testCustomerInitialization() {
    assertEquals("CUST-001", customer.getId());
    assertEquals("Alice Smith", customer.getFullName());
    assertEquals("Female", customer.getGender());
    assertEquals(LocalDate.of(1990, 5, 12), customer.getDateOfBirth());
    assertEquals("+61412345678", customer.getPhone());
    assertEquals("alice.smith@example.com", customer.getEmail());
    assertEquals("123 Collins St, Melbourne VIC 3000", customer.getAddress());
    assertEquals(CustomerStatus.ACTIVE, customer.getStatus());
    assertNotNull(customer.getRegistrationDate());
    assertEquals(0, customer.getOrderIds().size());
  }

  @Test
  @DisplayName("Should record customer order history accurately")
  void testRecordOrder() {
    customer.recordOrder("ORD-101");
    customer.recordOrder("ORD-102");

    assertEquals(2, customer.getOrderIds().size());
    assertEquals("ORD-101", customer.getOrderIds().get(0));
    assertEquals("ORD-102", customer.getOrderIds().get(1));
  }

  @Test
  @DisplayName("Should update customer status")
  void testUpdateStatus() {
    customer.setStatus(CustomerStatus.SUSPENDED);
    assertEquals(CustomerStatus.SUSPENDED, customer.getStatus());
  }

  @Test
  @DisplayName("Should validate required attributes on construction")
  void testCustomerValidation() {
    assertThrows(InvalidDataException.class, () -> new Customer(
        "CUST-002", "Bob", "Male", LocalDate.of(1985, 1, 1),
        "invalid-phone", "bob@example.com", "Address"));

    assertThrows(InvalidDataException.class, () -> new Customer(
        "CUST-003", "Bob", "Male", LocalDate.of(1985, 1, 1),
        "+61400000000", "not-an-email", "Address"));

    assertThrows(InvalidDataException.class, () -> new Customer(
        "", "Bob", "Male", LocalDate.of(1985, 1, 1),
        "+61400000000", "bob@example.com", "Address"));
  }
}
