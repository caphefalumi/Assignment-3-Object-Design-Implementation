package smartfm.domain.customer;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import smartfm.domain.fleet.Person;

/**
 * A registered client (business or individual) contracting shipping
 * services from ABC-Trans. Corresponds to the {@code Customer} CRC card
 * in Assignment 2 Section 3 (Commercial and Ordering Package).
 */
public class Customer extends Person {

  private static final long serialVersionUID = 1L;

  private final LocalDateTime registrationDate;
  private CustomerStatus status;
  private final List<String> orderIds = new ArrayList<>();

  public Customer(
      String id,
      String fullName,
      String gender,
      LocalDate dateOfBirth,
      String phone,
      String email,
      String address) {
    super(id, fullName, gender, dateOfBirth, phone, email, address);
    this.registrationDate = LocalDateTime.now();
    this.status = CustomerStatus.ACTIVE;
  }

  public LocalDateTime getRegistrationDate() {
    return registrationDate;
  }

  public CustomerStatus getStatus() {
    return status;
  }

  public void setStatus(CustomerStatus status) {
    this.status = status;
  }

  /** Records that this customer placed a new order. Called by OrderProcessor. */
  public void recordOrder(String orderId) {
    orderIds.add(orderId);
  }

  public List<String> getOrderIds() {
    return Collections.unmodifiableList(orderIds);
  }
}
