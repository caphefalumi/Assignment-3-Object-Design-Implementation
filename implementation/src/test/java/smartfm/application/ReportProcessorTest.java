package smartfm.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.common.Money;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.catalog.PricingTariff;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.domain.report.Report;
import smartfm.domain.report.ReportCategory;
import smartfm.domain.shipment.ManualTelemetrySource;
import smartfm.infrastructure.DataStore;

/**
 * Per-metric assertions for the administrative reporting controller (task T12).
 * Each test drives real state through the transactional controllers first, so the
 * asserted metrics are aggregated from the same aggregates the GUI reports on.
 */
@DisplayName("ReportProcessor Administrative Reporting Tests")
class ReportProcessorTest {

  private DataStore store;
  private OrderProcessor orderProcessor;
  private DispatchManager dispatchManager;
  private ShipmentTracker shipmentTracker;
  private PaymentProcessor paymentProcessor;
  private ReportProcessor reportProcessor;

  @BeforeEach
  void setUp() {
    store = new DataStore();

    Branch melbourne = new Branch("BR-MEL", "Melbourne Branch", "Melbourne", "+61391234567");
    Branch sydney = new Branch("BR-SYD", "Sydney Branch", "Sydney", "+61291234567");
    melbourne.registerVehicle("VHC-0001");
    melbourne.registerDriver("DRV-0001");
    sydney.registerVehicle("VHC-0002");
    store.branches().put(melbourne.getId(), melbourne);
    store.branches().put(sydney.getId(), sydney);

    Vehicle melbourneVan = new Vehicle("VHC-0001", "1AB2CD", "Hino 300", "Dry Van", 5000, 20, "BR-MEL");
    Vehicle sydneyVan = new Vehicle("VHC-0002", "3EF4GH", "Isuzu NQR", "Dry Van", 2000, 10, "BR-SYD");
    store.vehicles().put(melbourneVan.getId(), melbourneVan);
    store.vehicles().put(sydneyVan.getId(), sydneyVan);

    Driver driver = new Driver("DRV-0001", "Bob Driver", "Male", LocalDate.of(1988, 5, 4),
        "+61423456789", "bob@example.com", "9 Depot Road", "BR-MEL", "LIC-99887", LocalDate.now().plusYears(2));
    driver.setDutyState(DutyState.AVAILABLE);
    store.drivers().put(driver.getId(), driver);

    Customer customer = new Customer("CUS-0001", "Alice Smith", "Female",
        LocalDate.of(1990, 1, 1), "+61412345678", "alice@example.com", "123 Street");
    store.customers().put(customer.getId(), customer);

    ServiceOffering offering = new ServiceOffering("SVC-STD", "Standard Freight", "Standard road freight");
    offering.addCoveredBranch("BR-MEL");
    offering.addCoveredBranch("BR-SYD");
    offering.setPricingTariffId("TAR-STD");
    store.serviceOfferings().put(offering.getId(), offering);
    store.pricingTariffs().put("TAR-STD", new PricingTariff("TAR-STD", "SVC-STD", 50.0, 1.5, 2.0, 1.2));

    orderProcessor = new OrderProcessor(store);
    dispatchManager = new DispatchManager(store);
    shipmentTracker = new ShipmentTracker(store, new ManualTelemetrySource());
    paymentProcessor = new PaymentProcessor(store);
    reportProcessor = new ReportProcessor(store);
  }

  /** Submits one 10 kg / 100 km order, which the seeded tariff quotes at 220. */
  private Order submitOrder(String consignmentId) {
    return orderProcessor.submitOrder(
        "CUS-0001",
        "SVC-STD",
        "BR-MEL",
        "BR-SYD",
        100.0,
        LocalDate.now().plusDays(1),
        List.of(new Consignment(consignmentId, 10.0, 0.1, false, false, "Books")));
  }

  @Test
  @DisplayName("Financial report totals billed, collected and outstanding amounts per invoice state")
  void financialReportAggregatesBillingMetrics() {
    Order order = submitOrder("CNS-0001");
    Invoice invoice = orderProcessor.approveOrder(order.getId());
    paymentProcessor.submitPayment(invoice.getId(), 100.0, PaymentMethod.CASH);

    Report report = reportProcessor.generateFinancialReport(null, null);

    assertNotNull(report);
    assertEquals(ReportCategory.FINANCIAL, report.getCategory());
    assertTrue(report.getId().startsWith("RPT-"), "report ids are sequential RPT ids");
    assertEquals(Money.format(220.0) + " VND", report.getMetrics().get("Total Quoted Revenue"));
    assertEquals(Money.format(220.0) + " VND", report.getMetrics().get("Total Invoiced Amount"));
    assertEquals(Money.format(100.0) + " VND", report.getMetrics().get("Total Revenue Collected"));
    assertEquals(Money.format(120.0) + " VND", report.getMetrics().get("Outstanding Receivables"));
    assertEquals("1", report.getMetrics().get("Total Invoices"));
    assertEquals("0", report.getMetrics().get("Paid Invoices"));
    assertEquals("1", report.getMetrics().get("Partially Paid Invoices"));
    assertEquals("0", report.getMetrics().get("Unpaid Invoices"));
    assertEquals("1", report.getMetrics().get("Settled Payments Count"));
    assertTrue(report.getContent().contains("SMARTFM FINANCIAL"));
    assertTrue(report.getContent().contains("CASH"), "settled cash payment appears in the method breakdown");
  }

  @Test
  @DisplayName("Fleet report counts vehicles, drivers and shipment lifecycle states")
  void fleetReportAggregatesResourceAndShipmentMetrics() {
    Order order = submitOrder("CNS-0001");
    orderProcessor.approveOrder(order.getId());
    var shipment = dispatchManager.assignShipment(order.getId(), "VHC-0001", "DRV-0001");

    Report duringDispatch = reportProcessor.generateFleetReport(null, null);
    assertEquals("2", duringDispatch.getMetrics().get("Total Vehicles"));
    assertEquals("1", duringDispatch.getMetrics().get("Available Vehicles"));
    assertEquals("1", duringDispatch.getMetrics().get("Dispatched Vehicles"));
    assertEquals("7000", duringDispatch.getMetrics().get("Total Capacity (Kg)"));
    assertEquals("1", duringDispatch.getMetrics().get("Total Drivers"));
    assertEquals("0", duringDispatch.getMetrics().get("Available Drivers"));
    assertEquals("1", duringDispatch.getMetrics().get("Total Shipments"));
    assertEquals("1", duringDispatch.getMetrics().get("Active Shipments"));
    assertEquals("0", duringDispatch.getMetrics().get("Delivered Shipments"));

    shipmentTracker.confirmPickup(shipment.getId(), "Melbourne Depot");
    shipmentTracker.confirmInTransit(shipment.getId(), "Albury");
    shipmentTracker.confirmDelivery(shipment.getId(), "Sydney Depot");

    Report afterDelivery = reportProcessor.generateFleetReport(null, null);
    assertEquals(ReportCategory.FLEET, afterDelivery.getCategory());
    assertEquals("2", afterDelivery.getMetrics().get("Available Vehicles"));
    assertEquals("1", afterDelivery.getMetrics().get("Available Drivers"));
    assertEquals("0", afterDelivery.getMetrics().get("Active Shipments"));
    assertEquals("1", afterDelivery.getMetrics().get("Delivered Shipments"));
  }

  @Test
  @DisplayName("Branch report scopes resources and order volume to the selected branch")
  void branchReportScopesMetricsToBranch() {
    Order order = submitOrder("CNS-0001");
    orderProcessor.approveOrder(order.getId());

    Report melbourne = reportProcessor.generateBranchReport("BR-MEL", null, null);
    assertEquals(ReportCategory.BRANCH, melbourne.getCategory());
    assertEquals("Melbourne Branch", melbourne.getMetrics().get("Branch Scope"));
    assertEquals("1", melbourne.getMetrics().get("Assigned Vehicles"));
    assertEquals("1", melbourne.getMetrics().get("Assigned Drivers"));
    assertEquals("1", melbourne.getMetrics().get("Originating Orders"));
    assertEquals("0", melbourne.getMetrics().get("Destination Orders"));
    assertEquals(Money.format(220.0) + " VND", melbourne.getMetrics().get("Branch Quoted Revenue"));

    Report allBranches = reportProcessor.generateBranchReport(null, null, null);
    assertEquals("All Branches", allBranches.getMetrics().get("Branch Scope"));
    assertEquals("2", allBranches.getMetrics().get("Assigned Vehicles"));
  }

  @Test
  @DisplayName("Order summary report counts order states, customers and aggregate freight")
  void orderSummaryReportAggregatesOrderPipeline() {
    Order approved = submitOrder("CNS-0001");
    Order cancelled = submitOrder("CNS-0002");
    orderProcessor.approveOrder(approved.getId());
    orderProcessor.cancelOrder(cancelled.getId());

    Report report = reportProcessor.generateOrderSummaryReport(null, null);

    assertEquals(ReportCategory.ORDER_SUMMARY, report.getCategory());
    assertEquals("1", report.getMetrics().get("Total Customers"));
    assertEquals("1", report.getMetrics().get("Active Customers"));
    assertEquals("2", report.getMetrics().get("Total Orders"));
    assertEquals("0", report.getMetrics().get("Submitted Orders"));
    assertEquals("1", report.getMetrics().get("Approved Orders"));
    assertEquals("0", report.getMetrics().get("Rejected Orders"));
    assertEquals("1", report.getMetrics().get("Cancelled Orders"));
    assertEquals("20.00", report.getMetrics().get("Total Freight Weight (Kg)"));
    assertEquals("0.20", report.getMetrics().get("Total Freight Volume (M3)"));
    assertTrue(report.getContent().contains("SMARTFM ORDER"));
  }

  @Test
  @DisplayName("Category dispatch selects the matching report and defaults to financial")
  void generateReportDispatchesByCategory() {
    submitOrder("CNS-0001");

    assertEquals(ReportCategory.FLEET,
        reportProcessor.generateReport(ReportCategory.FLEET, null, null, null).getCategory());
    assertEquals(ReportCategory.BRANCH,
        reportProcessor.generateReport(ReportCategory.BRANCH, "BR-MEL", null, null).getCategory());
    assertEquals(ReportCategory.ORDER_SUMMARY,
        reportProcessor.generateReport(ReportCategory.ORDER_SUMMARY, null, null, null).getCategory());
    assertEquals(ReportCategory.FINANCIAL,
        reportProcessor.generateReport(ReportCategory.FINANCIAL, null, null, null).getCategory());
    assertEquals(ReportCategory.FINANCIAL,
        reportProcessor.generateReport(null, null, null, null).getCategory(),
        "a missing category falls back to the financial report");
  }

  @Test
  @DisplayName("Date range filter excludes records created outside the requested period")
  void dateRangeFilterExcludesOutOfPeriodRecords() {
    Order order = submitOrder("CNS-0001");
    orderProcessor.approveOrder(order.getId());

    LocalDate from = LocalDate.now().minusDays(30);
    LocalDate to = LocalDate.now().minusDays(20);

    Report pastOrders = reportProcessor.generateOrderSummaryReport(from, to);
    assertEquals("0", pastOrders.getMetrics().get("Total Orders"));
    assertEquals("0", pastOrders.getMetrics().get("Approved Orders"));

    Report pastFinancials = reportProcessor.generateFinancialReport(from, to);
    assertEquals("0", pastFinancials.getMetrics().get("Total Invoices"));
    assertEquals(Money.format(0.0) + " VND", pastFinancials.getMetrics().get("Total Invoiced Amount"));

    Report currentOrders = reportProcessor.generateOrderSummaryReport(
        LocalDate.now().minusDays(1), LocalDate.now().plusDays(1));
    assertEquals("1", currentOrders.getMetrics().get("Total Orders"));
  }
}
