package smartfm.ui;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import smartfm.application.Bootstrap;
import smartfm.application.DispatchManager;
import smartfm.application.OrderProcessor;
import smartfm.application.PaymentProcessor;
import smartfm.application.ShipmentTracker;
import smartfm.common.InvalidDataException;
import smartfm.common.Money;
import smartfm.common.Validators;
import smartfm.domain.Branch;
import smartfm.domain.Consignment;
import smartfm.domain.Customer;
import smartfm.domain.Driver;
import smartfm.domain.Invoice;
import smartfm.domain.Order;
import smartfm.domain.PaymentMethod;
import smartfm.domain.Receipt;
import smartfm.domain.ServiceOffering;
import smartfm.domain.Shipment;
import smartfm.domain.Vehicle;
import smartfm.infrastructure.DataStore;

/**
 * Textual (CLI) user interface for the SmartFM Assignment 3
 * implementation. Presents four independent, but dependency-chained,
 * business-area workflows:
 *
 * <ol>
 *   <li>Order Management ({@link OrderProcessor})</li>
 *   <li>Fleet Dispatch ({@link DispatchManager})</li>
 *   <li>Shipment Tracking ({@link ShipmentTracker})</li>
 *   <li>Billing and Payment ({@link PaymentProcessor})</li>
 * </ol>
 *
 * <p>Every menu follows the same shape required by the Assignment 3
 * brief: an empty starting prompt, clearly labelled inputs, validation
 * of incorrect input with the ability to retry, a cancel/"change of
 * mind" option, and a clear success message on completion.
 */
public final class SmartFmConsoleApp {

  private static final Path DATA_FILE = Paths.get("data", "smartfm-store.dat");

  private final ConsoleIO io;
  private final DataStore store;
  private final Bootstrap bootstrap;

  public SmartFmConsoleApp(Scanner scanner) {
    this.io = new ConsoleIO(scanner);
    this.store = DataStore.loadFrom(DATA_FILE);
    this.bootstrap = new Bootstrap(store);
    this.bootstrap.run();
  }

  public static void main(String[] args) {
    Scanner scanner = new Scanner(System.in);
    SmartFmConsoleApp app = new SmartFmConsoleApp(scanner);
    app.run();
  }

  public void run() {
    io.println("======================================================");
    io.println(" SmartFM - Smart Fleet Management System (Assignment 3)");
    io.println(" ABC-Trans internal operations console");
    io.println("======================================================");
    io.println("Data file: " + DATA_FILE.toAbsolutePath());
    io.println("Loaded " + store.branches().size() + " branch(es), "
        + store.vehicles().size() + " vehicle(s), " + store.drivers().size() + " driver(s), "
        + store.orders().size() + " order(s) on record.");

    boolean running = true;
    while (running) {
      io.printHeader("Main Menu");
      io.println("[1] Business Area 1: Order Management");
      io.println("[2] Business Area 2: Fleet Dispatch");
      io.println("[3] Business Area 3: Shipment Tracking");
      io.println("[4] Business Area 4: Billing and Payment");
      io.println("[5] Register a new customer account");
      io.println("[0] Save and exit");
      String choice = io.readLine("Select an option");
      switch (choice) {
        case "1":
          orderManagementMenu();
          break;
        case "2":
          fleetDispatchMenu();
          break;
        case "3":
          shipmentTrackingMenu();
          break;
        case "4":
          billingMenu();
          break;
        case "5":
          registerCustomer();
          break;
        case "0":
          running = false;
          break;
        default:
          io.println("Unrecognised option '" + choice + "'. Please choose a number from the menu.");
      }
    }
    store.saveTo(DATA_FILE);
    io.println("Data saved to " + DATA_FILE.toAbsolutePath() + ". Goodbye.");
  }

  // ---------------------------------------------------------------
  // Business Area 1: Order Management
  // ---------------------------------------------------------------

  private void orderManagementMenu() {
    io.printHeader("Business Area 1: Order Management");
    io.println("[1] Place a new shipment order");
    io.println("[2] View pending orders");
    io.println("[3] Approve an order");
    io.println("[4] Reject an order");
    io.println("[5] Cancel my own order (change of mind)");
    io.println("[0] Back to main menu");
    String choice = io.readLine("Select an option");
    switch (choice) {
      case "1":
        placeOrder();
        break;
      case "2":
        viewPendingOrders();
        break;
      case "3":
        approveOrder();
        break;
      case "4":
        rejectOrder();
        break;
      case "5":
        cancelOrder();
        break;
      case "0":
        break;
      default:
        io.println("Unrecognised option '" + choice + "'.");
    }
  }

  private void registerCustomer() {
    io.printHeader("Register Customer Account (empty form below)");
    io.println("Full name, contact details, and address are all required.");

    String id = "CUS-" + String.format("%04d", store.customers().size() + 1);
    String fullName = io.readValidated("Full name", v -> Validators.requireNonBlank(v, "Full name", 80));
    if (fullName == null) {
      io.println("Registration cancelled.");
      return;
    }
    String gender = io.readLine("Gender");
    LocalDate dob = io.readValidated("Date of birth (YYYY-MM-DD)",
        v -> Validators.requirePastOrTodayDate(v, "Date of birth"));
    if (dob == null) {
      io.println("Registration cancelled.");
      return;
    }
    String phone = io.readValidated("Phone number", v -> Validators.requirePhone(v, "Phone number"));
    if (phone == null) {
      io.println("Registration cancelled.");
      return;
    }
    String email = io.readValidated("Email address", v -> Validators.requireEmail(v, "Email"));
    if (email == null) {
      io.println("Registration cancelled.");
      return;
    }
    String address = io.readValidated("Address", v -> Validators.requireNonBlank(v, "Address", 160));
    if (address == null) {
      io.println("Registration cancelled.");
      return;
    }

    Customer customer = new Customer(id, fullName, gender, dob, phone, email, address);
    store.customers().put(customer.getId(), customer);
    io.println("Success: customer account " + customer.getId() + " (" + fullName + ") created.");
  }

  private void placeOrder() {
    io.printHeader("Place a Shipment Order (empty form below)");
    printAvailableCustomers();
    String customerId = io.readValidated("Customer id", v -> Validators.requireNonBlank(v, "Customer id", 20));
    if (customerId == null) {
      io.println("Order placement cancelled.");
      return;
    }
    if (!store.customers().containsKey(customerId)) {
      io.println("  [Invalid input] No customer with id '" + customerId + "' exists. Order placement cancelled.");
      return;
    }

    printAvailableServiceOfferings();
    String serviceId = io.readValidated("Service offering id",
        v -> Validators.requireNonBlank(v, "Service offering id", 20));
    if (serviceId == null) {
      io.println("Order placement cancelled.");
      return;
    }

    printAvailableBranches();
    String originId = io.readValidated("Origin branch id", v -> Validators.requireNonBlank(v, "Origin branch id", 20));
    if (originId == null) {
      io.println("Order placement cancelled.");
      return;
    }
    String destinationId = io.readValidated("Destination branch id",
        v -> Validators.requireNonBlank(v, "Destination branch id", 20));
    if (destinationId == null) {
      io.println("Order placement cancelled.");
      return;
    }
    Double distance = io.readValidated("Distance in km (positive number)",
        v -> Validators.parsePositiveNumber(v, "Distance"));
    if (distance == null) {
      io.println("Order placement cancelled.");
      return;
    }
    LocalDate pickupDate = io.readValidated("Requested pickup date (YYYY-MM-DD, today or later)",
        v -> Validators.requireTodayOrFuture(v, "Pickup date"));
    if (pickupDate == null) {
      io.println("Order placement cancelled.");
      return;
    }

    List<Consignment> consignments = new ArrayList<>();
    boolean addingMore = true;
    int seq = 1;
    while (addingMore) {
      io.println("-- Consignment #" + seq + " --");
      String desc = io.readValidated("  Description", v -> Validators.requireNonBlank(v, "Description", 120));
      if (desc == null) {
        break;
      }
      Double weight = io.readValidated("  Weight in kg (positive number)",
          v -> Validators.parsePositiveNumber(v, "Weight"));
      if (weight == null) {
        break;
      }
      Double volume = io.readValidated("  Volume in m3 (positive number)",
          v -> Validators.parsePositiveNumber(v, "Volume"));
      if (volume == null) {
        break;
      }
      String fragileRaw = io.readLine("  Fragile? (y/n)");
      String coldRaw = io.readLine("  Requires refrigeration? (y/n)");
      consignments.add(new Consignment(
          "CSG-" + seq, weight, volume,
          fragileRaw.equalsIgnoreCase("y"), coldRaw.equalsIgnoreCase("y"), desc));
      seq++;
      String more = io.readLine("Add another consignment? (y/n)");
      addingMore = more.equalsIgnoreCase("y");
    }

    if (consignments.isEmpty()) {
      io.println("  [Invalid input] An order must have at least one consignment. Order placement cancelled.");
      return;
    }

    try {
      Order order = bootstrap.getOrderProcessor().submitOrder(
          customerId, serviceId, originId, destinationId, distance, pickupDate, consignments);
      io.println("Success: order " + order.getId() + " submitted. Estimated quote: "
          + Money.format(order.getQuotedAmount()) + " VND. Status: " + order.getStateName() + ".");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  private void viewPendingOrders() {
    io.printHeader("Pending Orders");
    List<Order> pending = bootstrap.getOrderProcessor().listPendingOrders();
    if (pending.isEmpty()) {
      io.println("(no pending orders)");
      return;
    }
    for (Order order : pending) {
      io.println(order.toString() + " | customer=" + order.getCustomerId()
          + " | weight=" + order.getTotalWeightKg() + "kg");
    }
  }

  private void approveOrder() {
    io.printHeader("Approve an Order");
    viewPendingOrders();
    String orderId = io.readValidated("Order id to approve", v -> Validators.requireNonBlank(v, "Order id", 20));
    if (orderId == null) {
      io.println("Approval cancelled.");
      return;
    }
    try {
      Invoice invoice = bootstrap.getOrderProcessor().approveOrder(orderId);
      io.println("Success: order " + orderId + " approved. Invoice " + invoice.getId()
          + " generated for " + Money.format(invoice.getTotalAmount()) + " VND, due " + invoice.getDueDate() + ".");
      io.println("(Observer notification: DispatchManager and PaymentProcessor were notified automatically.)");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  private void rejectOrder() {
    io.printHeader("Reject an Order");
    viewPendingOrders();
    String orderId = io.readValidated("Order id to reject", v -> Validators.requireNonBlank(v, "Order id", 20));
    if (orderId == null) {
      io.println("Rejection cancelled.");
      return;
    }
    String reason = io.readValidated("Rejection reason", v -> Validators.requireNonBlank(v, "Rejection reason", 200));
    if (reason == null) {
      io.println("Rejection cancelled.");
      return;
    }
    try {
      bootstrap.getOrderProcessor().rejectOrder(orderId, reason);
      io.println("Success: order " + orderId + " rejected. Reason recorded: " + reason);
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  private void cancelOrder() {
    io.printHeader("Cancel an Order (customer change of mind)");
    viewPendingOrders();
    String orderId = io.readValidated("Order id to cancel", v -> Validators.requireNonBlank(v, "Order id", 20));
    if (orderId == null) {
      io.println("Nothing changed.");
      return;
    }
    try {
      bootstrap.getOrderProcessor().cancelOrder(orderId);
      io.println("Success: order " + orderId + " cancelled at the customer's request.");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  // ---------------------------------------------------------------
  // Business Area 2: Fleet Dispatch
  // ---------------------------------------------------------------

  private void fleetDispatchMenu() {
    io.printHeader("Business Area 2: Fleet Dispatch (empty form below)");
    io.println("Approved orders awaiting dispatch:");
    boolean any = false;
    for (Order order : store.orders().values()) {
      if (order.isApproved() && order.getInvoiceId() != null && !hasShipment(order.getId())) {
        io.println("  " + order);
        any = true;
      }
    }
    if (!any) {
      io.println("  (none - approve an order first in Business Area 1)");
      return;
    }
    String orderId = io.readValidated("Order id to dispatch", v -> Validators.requireNonBlank(v, "Order id", 20));
    if (orderId == null) {
      io.println("Dispatch cancelled.");
      return;
    }
    Order order = store.orders().get(orderId);
    if (order == null) {
      io.println("  [Invalid input] No order with id '" + orderId + "'.");
      return;
    }

    io.println("Available vehicles at origin branch " + order.getOriginBranchId() + ":");
    List<Vehicle> vehicles = bootstrap.getDispatchManager()
        .findAvailableVehicles(order.getOriginBranchId(), order.getTotalWeightKg(), 0);
    if (vehicles.isEmpty()) {
      io.println("  (no suitable vehicle available - try again later)");
      return;
    }
    for (Vehicle v : vehicles) {
      io.println("  " + v.getId() + " - " + v);
    }
    String vehicleId = io.readValidated("Vehicle id", v -> Validators.requireNonBlank(v, "Vehicle id", 20));
    if (vehicleId == null) {
      io.println("Dispatch cancelled.");
      return;
    }

    io.println("Available drivers at origin branch " + order.getOriginBranchId() + ":");
    List<Driver> drivers = bootstrap.getDispatchManager().findAvailableDrivers(order.getOriginBranchId());
    if (drivers.isEmpty()) {
      io.println("  (no available driver - try again later)");
      return;
    }
    for (Driver d : drivers) {
      io.println("  " + d.getId() + " - " + d.getFullName());
    }
    String driverId = io.readValidated("Driver id", v -> Validators.requireNonBlank(v, "Driver id", 20));
    if (driverId == null) {
      io.println("Dispatch cancelled.");
      return;
    }

    try {
      Shipment shipment = bootstrap.getDispatchManager().assignShipment(orderId, vehicleId, driverId);
      io.println("Success: shipment " + shipment.getId() + " created for order " + orderId
          + ". Status: " + shipment.getStateName() + ".");
      io.println("(Observer notification: ShipmentTracker was notified automatically.)");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  private boolean hasShipment(String orderId) {
    for (Shipment shipment : store.shipments().values()) {
      if (shipment.getOrderId().equals(orderId)) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------
  // Business Area 3: Shipment Tracking
  // ---------------------------------------------------------------

  private void shipmentTrackingMenu() {
    io.printHeader("Business Area 3: Shipment Tracking");
    io.println("[1] Confirm pickup");
    io.println("[2] Confirm in transit");
    io.println("[3] Confirm delivery");
    io.println("[4] View shipment status");
    io.println("[0] Back to main menu");
    String choice = io.readLine("Select an option");
    switch (choice) {
      case "1":
        transitionShipment("pick up", (id, loc) -> bootstrap.getShipmentTracker().confirmPickup(id, loc));
        break;
      case "2":
        transitionShipment("mark in transit", (id, loc) -> bootstrap.getShipmentTracker().confirmInTransit(id, loc));
        break;
      case "3":
        transitionShipment("mark delivered", (id, loc) -> bootstrap.getShipmentTracker().confirmDelivery(id, loc));
        break;
      case "4":
        viewShipmentStatus();
        break;
      case "0":
        break;
      default:
        io.println("Unrecognised option '" + choice + "'.");
    }
  }

  private interface ShipmentTransition {
    void apply(String shipmentId, String location);
  }

  private void transitionShipment(String actionLabel, ShipmentTransition transition) {
    io.printHeader("Shipment Tracking: " + actionLabel + " (empty form below)");
    listAllShipments();
    String shipmentId = io.readValidated("Shipment id", v -> Validators.requireNonBlank(v, "Shipment id", 20));
    if (shipmentId == null) {
      io.println("Cancelled.");
      return;
    }
    String location = io.readValidated("Current location description",
        v -> Validators.requireNonBlank(v, "Location", 120));
    if (location == null) {
      io.println("Cancelled.");
      return;
    }
    try {
      transition.apply(shipmentId, location);
      Shipment shipment = store.shipments().get(shipmentId);
      io.println("Success: shipment " + shipmentId + " is now '" + shipment.getStateName()
          + "' at " + shipment.getLastKnownLocation() + ".");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  private void listAllShipments() {
    if (store.shipments().isEmpty()) {
      io.println("(no shipments yet - dispatch an order first in Business Area 2)");
      return;
    }
    for (Shipment shipment : store.shipments().values()) {
      io.println("  " + shipment);
    }
  }

  private void viewShipmentStatus() {
    io.printHeader("Shipment Status");
    listAllShipments();
  }

  // ---------------------------------------------------------------
  // Business Area 4: Billing and Payment
  // ---------------------------------------------------------------

  private void billingMenu() {
    io.printHeader("Business Area 4: Billing and Payment (empty form below)");
    io.println("Outstanding invoices:");
    boolean any = false;
    for (Invoice invoice : store.invoices().values()) {
      if (!invoice.isSettled()) {
        io.println("  " + invoice);
        any = true;
      }
    }
    if (!any) {
      io.println("  (none - approve an order in Business Area 1 first)");
      return;
    }
    String invoiceId = io.readValidated("Invoice id to pay", v -> Validators.requireNonBlank(v, "Invoice id", 20));
    if (invoiceId == null) {
      io.println("Payment cancelled.");
      return;
    }
    Invoice invoice = store.invoices().get(invoiceId);
    if (invoice == null) {
      io.println("  [Invalid input] No invoice with id '" + invoiceId + "'.");
      return;
    }
    io.println("Outstanding balance: " + Money.format(invoice.getOutstandingBalance()) + " VND.");
    Double amount = io.readValidated("Payment amount in VND (positive number)",
        v -> Validators.parsePositiveNumber(v, "Payment amount"));
    if (amount == null) {
      io.println("Payment cancelled.");
      return;
    }
    io.println("Payment methods: CASH, CARD, DIGITAL_WALLET");
    PaymentMethod method = io.readValidated("Payment method",
        v -> Validators.requireEnum(v, PaymentMethod.class, "Payment method"));
    if (method == null) {
      io.println("Payment cancelled.");
      return;
    }
    try {
      Receipt receipt = bootstrap.getPaymentProcessor().submitPayment(invoiceId, amount, method);
      io.println("Success: payment processed. As per the Assignment 3 simplification, "
          + "no real banking transaction was executed - this is a simulated confirmation only.");
      io.println("Receipt " + receipt.getId() + " issued for " + Money.format(receipt.getAmountSettled())
          + " VND at " + Money.formatTimestamp(receipt.getIssuedAt()) + ". Invoice status: "
          + invoice.getStateName() + ".");
    } catch (InvalidDataException exc) {
      io.println("  [Rejected] " + exc.getMessage());
    }
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  private void printAvailableCustomers() {
    io.println("Registered customers:");
    if (store.customers().isEmpty()) {
      io.println("  (none yet - register one from the main menu first)");
    }
    for (Customer customer : store.customers().values()) {
      io.println("  " + customer.getId() + " - " + customer.getFullName());
    }
  }

  private void printAvailableServiceOfferings() {
    io.println("Available service offerings:");
    for (ServiceOffering offering : store.serviceOfferings().values()) {
      io.println("  " + offering.getId() + " - " + offering.getName());
    }
  }

  private void printAvailableBranches() {
    io.println("Branches:");
    for (Branch branch : store.branches().values()) {
      io.println("  " + branch.getId() + " - " + branch);
    }
  }
}
