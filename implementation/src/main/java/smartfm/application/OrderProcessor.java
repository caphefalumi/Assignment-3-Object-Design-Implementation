package smartfm.application;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import smartfm.common.InvalidDataException;
import smartfm.domain.billing.Invoice;
import smartfm.domain.catalog.PricingTariff;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.infrastructure.DataStore;

/**
 * Coordinating controller managing the complete lifecycle of a customer
 * order, from submission through approval to invoice creation.
 * Corresponds to the {@code OrderProcessor} CRC card in Assignment 2
 * Section 3 (System Control and Configuration Package). Acts as a
 * Facade over {@code Order}, {@code Consignment}, {@code
 * ServiceOffering}, and {@code PricingTariff} (Assignment 2 Section
 * 5.3.1), and as the Factory Method for {@code Order} and {@code
 * Invoice} (Assignment 2 Section 5.1.1).
 *
 * <p>This is one of the four controllers implemented for Assignment 3's
 * "Business Area 1: Order Management".
 */
public class OrderProcessor {

  private final DataStore store;
  private final IdGenerator orderIds;
  private final IdGenerator invoiceIds;
  private final List<OrderApprovedListener> orderApprovedListeners = new ArrayList<>();
  private final List<InvoiceCreatedListener> invoiceCreatedListeners = new ArrayList<>();

  public OrderProcessor(DataStore store) {
    this.store = store;
    this.orderIds = new IdGenerator("ORD", store.orders());
    this.invoiceIds = new IdGenerator("INV", store.invoices());
  }

  /** Registered by DispatchManager during bootstrap (Observer pattern). */
  public void addOrderApprovedListener(OrderApprovedListener listener) {
    orderApprovedListeners.add(listener);
  }

  /** Registered by PaymentProcessor during bootstrap (Observer pattern). */
  public void addInvoiceCreatedListener(InvoiceCreatedListener listener) {
    invoiceCreatedListeners.add(listener);
  }

  /**
   * Step 1 of Scenario 1: a customer submits a delivery request. Creates
   * the {@code Order} and its {@code Consignment} items (Factory Method).
   */
  public Order submitOrder(
      String customerId,
      String serviceOfferingId,
      String originBranchId,
      String destinationBranchId,
      double distanceKm,
      LocalDate requestedPickupDate,
      List<Consignment> consignments) {

    Customer customer = store.customers().get(customerId);
    if (customer == null) {
      throw new InvalidDataException("Unknown customer id '" + customerId + "'.");
    }
    ServiceOffering offering = store.serviceOfferings().get(serviceOfferingId);
    if (offering == null) {
      throw new InvalidDataException("Unknown service offering id '" + serviceOfferingId + "'.");
    }
    if (!offering.isAvailableAt(originBranchId)) {
      throw new InvalidDataException(
          "Service '" + offering.getName() + "' is not available at branch " + originBranchId + ".");
    }

    Order order = new Order(
        orderIds.next(), customerId, serviceOfferingId, originBranchId,
        destinationBranchId, distanceKm, requestedPickupDate);

    for (Consignment consignment : consignments) {
      order.addConsignment(consignment);
    }
    order.requireHasConsignments();

    PricingTariff tariff = store.pricingTariffs().get(offering.getPricingTariffId());
    if (tariff == null) {
      throw new InvalidDataException("Service '" + offering.getName() + "' has no active pricing tariff.");
    }
    double quote = tariff.calculateQuote(distanceKm, order.getTotalWeightKg(), false);
    order.setQuotedAmount(quote);

    store.orders().put(order.getId(), order);
    customer.recordOrder(order.getId());
    return order;
  }

  /**
   * Step 5-8 of Scenario 1: a dispatcher approves a submitted order,
   * which triggers invoice generation and notifies observers.
   */
  public Invoice approveOrder(String orderId) {
    Order order = requireOrder(orderId);
    order.approve();

    Invoice invoice = new Invoice(
        invoiceIds.next(), order.getId(), order.getQuotedAmount(), LocalDate.now().plusDays(14));
    store.invoices().put(invoice.getId(), invoice);
    order.setInvoiceId(invoice.getId());

    for (OrderApprovedListener listener : orderApprovedListeners) {
      listener.onOrderApproved(order);
    }
    for (InvoiceCreatedListener listener : invoiceCreatedListeners) {
      listener.onInvoiceCreated(invoice);
    }
    return invoice;
  }

  /** A dispatcher rejects a submitted order with a stated reason. */
  public void rejectOrder(String orderId, String reason) {
    Order order = requireOrder(orderId);
    order.reject(reason);
  }

  /** A customer changes their mind before approval and withdraws the order. */
  public void cancelOrder(String orderId) {
    Order order = requireOrder(orderId);
    order.cancel();
  }

  public List<Order> listPendingOrders() {
    List<Order> pending = new ArrayList<>();
    for (Order order : store.orders().values()) {
      if ("Submitted".equals(order.getStateName())) {
        pending.add(order);
      }
    }
    return pending;
  }

  public Order requireOrder(String orderId) {
    Order order = store.orders().get(orderId);
    if (order == null) {
      throw new InvalidDataException("Unknown order id '" + orderId + "'.");
    }
    return order;
  }
}
