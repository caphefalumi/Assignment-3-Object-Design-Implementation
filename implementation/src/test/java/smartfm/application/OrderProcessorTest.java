package smartfm.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.domain.catalog.PricingTariff;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Branch;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.infrastructure.DataStore;

@DisplayName("OrderProcessor Application Controller Tests")
class OrderProcessorTest {

  private DataStore store;
  private OrderProcessor orderProcessor;

  @BeforeEach
  void setUp() {
    store = new DataStore();

    Branch originBranch = new Branch("BR-MEL", "Melbourne Branch", "Melbourne", "+61391234567");
    Branch destBranch = new Branch("BR-SYD", "Sydney Branch", "Sydney", "+61291234567");
    store.branches().put("BR-MEL", originBranch);
    store.branches().put("BR-SYD", destBranch);

    Customer customer = new Customer("CUST-001", "Alice Smith", "Female",
        LocalDate.of(1990, 1, 1), "+61412345678", "alice@example.com", "123 Street");
    store.customers().put("CUST-001", customer);

    ServiceOffering offering = new ServiceOffering("SVC-EXPRESS", "Express Delivery", "Fast express delivery");
    offering.addCoveredBranch("BR-MEL");
    offering.addCoveredBranch("BR-SYD");
    offering.setPricingTariffId("TARIFF-001");
    store.serviceOfferings().put("SVC-EXPRESS", offering);

    PricingTariff tariff = new PricingTariff("TARIFF-001", "SVC-EXPRESS", 50.0, 1.5, 2.0, 1.2);
    store.pricingTariffs().put("TARIFF-001", tariff);

    orderProcessor = new OrderProcessor(store);
  }

  @Test
  @DisplayName("Should successfully submit order and calculate quoted amount")
  void testSubmitOrder() {
    Consignment consignment = new Consignment("CNS-001", 10.0, 0.1, false, false, "Books");
    Order order = orderProcessor.submitOrder(
        "CUST-001",
        "SVC-EXPRESS",
        "BR-MEL",
        "BR-SYD",
        100.0,
        LocalDate.now().plusDays(1),
        List.of(consignment));

    assertNotNull(order);
    assertEquals("Submitted", order.getStateName());
    assertEquals(220.0, order.getQuotedAmount(), 0.01);
    assertEquals(1, store.orders().size());
    assertEquals(1, store.customers().get("CUST-001").getOrderIds().size());
  }

  @Test
  @DisplayName("Should notify listeners when order is approved")
  void testApproveOrderNotifiesListeners() {
    Consignment consignment = new Consignment("CNS-001", 10.0, 0.1, false, false, "Books");
    Order order = orderProcessor.submitOrder(
        "CUST-001", "SVC-EXPRESS", "BR-MEL", "BR-SYD", 100.0, LocalDate.now().plusDays(1), List.of(consignment));

    AtomicBoolean listenerCalled = new AtomicBoolean(false);
    orderProcessor.addOrderApprovedListener(approvedOrder -> {
      assertEquals(order.getId(), approvedOrder.getId());
      listenerCalled.set(true);
    });

    orderProcessor.approveOrder(order.getId());

    assertEquals("Approved", order.getStateName());
    assertEquals(true, listenerCalled.get());
  }
}
