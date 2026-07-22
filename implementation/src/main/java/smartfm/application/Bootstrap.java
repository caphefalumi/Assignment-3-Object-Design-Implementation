package smartfm.application;

import java.time.LocalDate;
import smartfm.domain.Branch;
import smartfm.domain.Driver;
import smartfm.domain.ManualTelemetrySource;
import smartfm.domain.PricingTariff;
import smartfm.domain.ServiceOffering;
import smartfm.domain.StaffMember;
import smartfm.domain.StaffRole;
import smartfm.domain.SystemConfiguration;
import smartfm.domain.Vehicle;
import smartfm.infrastructure.DataStore;

/**
 * Drives the exact startup order specified in Assignment 2 Section 6
 * (Bootstrap Process): configuration, then branches, then fleet and
 * personnel resources, then the commercial catalogue, then the four
 * controllers in an order that lets each later controller register as
 * an Observer of the earlier ones before any transactional object is
 * created. See asm3.typ Part I.C for the full justification of any
 * changes made to this sequence during implementation.
 */
public final class Bootstrap {

  private final DataStore store;
  private final ManualTelemetrySource telemetrySource = new ManualTelemetrySource();
  private OrderProcessor orderProcessor;
  private DispatchManager dispatchManager;
  private ShipmentTracker shipmentTracker;
  private PaymentProcessor paymentProcessor;

  public Bootstrap(DataStore store) {
    this.store = store;
  }

  /** Runs the full bootstrap sequence. Idempotent on catalogue/branch seeding. */
  public void run() {
    // Step 1: system-wide configuration.
    SystemConfiguration.bootstrap();

    // Step 2 & 3 & 4: only seed reference/master data once (first run).
    if (store.branches().isEmpty()) {
      seedBranchesFleetAndCatalogue();
    }

    // Step 5-8: instantiate the four controllers in dependency-safe,
    // Observer-registration-safe order (Assignment 2 Section 6.2).
    orderProcessor = new OrderProcessor(store);
    dispatchManager = new DispatchManager(store);
    shipmentTracker = new ShipmentTracker(store, telemetrySource);
    paymentProcessor = new PaymentProcessor(store);

    orderProcessor.addOrderApprovedListener(dispatchManager);
    orderProcessor.addInvoiceCreatedListener(paymentProcessor);
    dispatchManager.addShipmentAssignedListener(shipmentTracker);
  }

  private void seedBranchesFleetAndCatalogue() {
    Branch hcm = new Branch("BR-HCM", "Ho Chi Minh City Branch", "Ho Chi Minh City", "+84-28-1234567");
    Branch han = new Branch("BR-HAN", "Hanoi Branch", "Hanoi", "+84-24-7654321");
    store.branches().put(hcm.getId(), hcm);
    store.branches().put(han.getId(), han);

    Vehicle v1 = new Vehicle("VHC-0001", "51C-11111", "Hino 300", "Dry Van", 3000, 18, hcm.getId());
    Vehicle v2 = new Vehicle("VHC-0002", "51C-22222", "Isuzu NQR", "Refrigerated", 2000, 14, hcm.getId());
    Vehicle v3 = new Vehicle("VHC-0003", "30H-33333", "Hyundai Mighty", "Dry Van", 2500, 16, han.getId());
    store.vehicles().put(v1.getId(), v1);
    store.vehicles().put(v2.getId(), v2);
    store.vehicles().put(v3.getId(), v3);
    hcm.registerVehicle(v1.getId());
    hcm.registerVehicle(v2.getId());
    han.registerVehicle(v3.getId());

    Driver d1 = new Driver(
        "DRV-0001", "Nguyen Van A", "Male", LocalDate.of(1990, 5, 12),
        "+84-90-1112222", "nguyenvana@abc-trans.vn", "12 Le Loi, HCMC",
        hcm.getId(), "LIC-000111", LocalDate.now().plusYears(2));
    Driver d2 = new Driver(
        "DRV-0002", "Tran Thi B", "Female", LocalDate.of(1988, 8, 3),
        "+84-90-3334444", "tranthib@abc-trans.vn", "45 Hai Ba Trung, HCMC",
        hcm.getId(), "LIC-000222", LocalDate.now().plusYears(3));
    Driver d3 = new Driver(
        "DRV-0003", "Le Van C", "Male", LocalDate.of(1992, 1, 20),
        "+84-90-5556666", "levanc@abc-trans.vn", "8 Trang Tien, Hanoi",
        han.getId(), "LIC-000333", LocalDate.now().plusYears(1));
    d1.setDutyState(smartfm.domain.DutyState.AVAILABLE);
    d2.setDutyState(smartfm.domain.DutyState.AVAILABLE);
    d3.setDutyState(smartfm.domain.DutyState.AVAILABLE);
    store.drivers().put(d1.getId(), d1);
    store.drivers().put(d2.getId(), d2);
    store.drivers().put(d3.getId(), d3);
    hcm.registerDriver(d1.getId());
    hcm.registerDriver(d2.getId());
    han.registerDriver(d3.getId());

    StaffMember dispatcherHcm = new StaffMember(
        "STF-0001", "Pham Thi Dispatcher", "Female", LocalDate.of(1985, 3, 15),
        "+84-90-7778888", "dispatcher.hcm@abc-trans.vn", "1 Nguyen Hue, HCMC",
        StaffRole.DISPATCHER, hcm.getId());
    store.staffMembers().put(dispatcherHcm.getId(), dispatcherHcm);
    hcm.registerStaff(dispatcherHcm.getId());

    ServiceOffering standard = new ServiceOffering(
        "SVC-STD", "Standard Freight", "Standard dry-van freight delivery within 3-5 business days.");
    ServiceOffering express = new ServiceOffering(
        "SVC-EXP", "Same-Day Express", "Expedited delivery guaranteed within the same business day.");
    ServiceOffering coldChain = new ServiceOffering(
        "SVC-CLD", "Cold Chain Transport", "Refrigerated transport for temperature-sensitive goods.");
    standard.addCoveredBranch(hcm.getId());
    standard.addCoveredBranch(han.getId());
    express.addCoveredBranch(hcm.getId());
    coldChain.addCoveredBranch(hcm.getId());
    store.serviceOfferings().put(standard.getId(), standard);
    store.serviceOfferings().put(express.getId(), express);
    store.serviceOfferings().put(coldChain.getId(), coldChain);
    hcm.registerServiceOffering(standard.getId());
    hcm.registerServiceOffering(express.getId());
    hcm.registerServiceOffering(coldChain.getId());
    han.registerServiceOffering(standard.getId());

    PricingTariff standardTariff = new PricingTariff("TAR-STD", standard.getId(), 50000, 8000, 3000, 1.2);
    PricingTariff expressTariff = new PricingTariff("TAR-EXP", express.getId(), 120000, 15000, 5000, 1.5);
    PricingTariff coldChainTariff = new PricingTariff("TAR-CLD", coldChain.getId(), 90000, 12000, 6000, 1.3);
    store.pricingTariffs().put(standardTariff.getId(), standardTariff);
    store.pricingTariffs().put(expressTariff.getId(), expressTariff);
    store.pricingTariffs().put(coldChainTariff.getId(), coldChainTariff);
    standard.setPricingTariffId(standardTariff.getId());
    express.setPricingTariffId(expressTariff.getId());
    coldChain.setPricingTariffId(coldChainTariff.getId());
  }

  public OrderProcessor getOrderProcessor() {
    return orderProcessor;
  }

  public DispatchManager getDispatchManager() {
    return dispatchManager;
  }

  public ShipmentTracker getShipmentTracker() {
    return shipmentTracker;
  }

  public PaymentProcessor getPaymentProcessor() {
    return paymentProcessor;
  }

  public ManualTelemetrySource getTelemetrySource() {
    return telemetrySource;
  }

  public DataStore getStore() {
    return store;
  }
}
