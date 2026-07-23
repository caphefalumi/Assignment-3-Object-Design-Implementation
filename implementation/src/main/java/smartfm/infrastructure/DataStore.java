package smartfm.infrastructure;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.Payment;
import smartfm.domain.billing.PaymentMethod;
import smartfm.domain.billing.Receipt;
import smartfm.domain.catalog.PricingTariff;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.customer.CustomerStatus;
import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.DutyState;
import smartfm.domain.fleet.StaffMember;
import smartfm.domain.fleet.StaffRole;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Consignment;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;

/**
 * SQLite-backed persistence gateway for SmartFM.
 *
 * <p>The controller-facing maps remain in memory, but the durable representation
 * is a normalized relational schema. Every save replaces the aggregate rows in
 * one SQLite transaction; every load reconstructs the same domain graph from
 * those rows. Domain classes do not depend on JDBC or this gateway.
 */
public final class DataStore {
  private static final int SCHEMA_VERSION = 3;
  private static final String SQLITE_DRIVER = "org.sqlite.JDBC";
  private static final DateTimeFormatter DB_DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

  private final Map<String, Customer> customers = new LinkedHashMap<>();
  private final Map<String, StaffMember> staffMembers = new LinkedHashMap<>();
  private final Map<String, Driver> drivers = new LinkedHashMap<>();
  private final Map<String, Branch> branches = new LinkedHashMap<>();
  private final Map<String, Vehicle> vehicles = new LinkedHashMap<>();
  private final Map<String, ServiceOffering> serviceOfferings = new LinkedHashMap<>();
  private final Map<String, PricingTariff> pricingTariffs = new LinkedHashMap<>();
  private final Map<String, Order> orders = new LinkedHashMap<>();
  private final Map<String, Shipment> shipments = new LinkedHashMap<>();
  private final Map<String, Invoice> invoices = new LinkedHashMap<>();
  private final Map<String, Payment> payments = new LinkedHashMap<>();
  private final Map<String, Receipt> receipts = new LinkedHashMap<>();

  public Map<String, Customer> customers() { return customers; }
  public Map<String, StaffMember> staffMembers() { return staffMembers; }
  public Map<String, Driver> drivers() { return drivers; }
  public Map<String, Branch> branches() { return branches; }
  public Map<String, Vehicle> vehicles() { return vehicles; }
  public Map<String, ServiceOffering> serviceOfferings() { return serviceOfferings; }
  public Map<String, PricingTariff> pricingTariffs() { return pricingTariffs; }
  public Map<String, Order> orders() { return orders; }
  public Map<String, Shipment> shipments() { return shipments; }
  public Map<String, Invoice> invoices() { return invoices; }
  public Map<String, Payment> payments() { return payments; }
  public Map<String, Receipt> receipts() { return receipts; }

  /** Saves all aggregate rows in one SQLite transaction. */
  public void saveTo(Path databasePath) {
    ensureParentDirectory(databasePath);
    ensureJdbcDriver();
    try (Connection connection = DriverManager.getConnection(sqliteUrl(databasePath))) {
      enableForeignKeys(connection);
      connection.setAutoCommit(false);
      try {
        ensureSchema(connection);
        writeNormalized(connection, this);
        connection.commit();
      } catch (Exception exception) {
        rollback(connection, exception);
        throw exception;
      }
    } catch (SQLException exception) {
      throw new IllegalStateException("Failed to save SmartFM SQLite database to " + databasePath, exception);
    } catch (RuntimeException exception) {
      throw exception;
    } catch (Exception exception) {
      throw new IllegalStateException("Failed to save SmartFM SQLite database to " + databasePath, exception);
    }
  }

  /** Loads the normalized aggregate, or an empty store for a new database. */
  public static DataStore loadFrom(Path databasePath) {
    ensureParentDirectory(databasePath);
    ensureJdbcDriver();
    try (Connection connection = DriverManager.getConnection(sqliteUrl(databasePath))) {
      enableForeignKeys(connection);
      connection.setAutoCommit(false);
      try {
        ensureSchema(connection);
        DataStore store = readNormalized(connection);
        connection.commit();
        return store;
      } catch (Exception exception) {
        rollback(connection, exception);
        throw exception;
      }
    } catch (SQLException exception) {
      throw new IllegalStateException("Failed to load SmartFM SQLite database from " + databasePath, exception);
    } catch (RuntimeException exception) {
      throw exception;
    } catch (Exception exception) {
      throw new IllegalStateException("Failed to load SmartFM SQLite database from " + databasePath, exception);
    }
  }

  private static void ensureSchema(Connection connection) throws SQLException {
    execute(connection, "CREATE TABLE IF NOT EXISTS schema_metadata ("
        + "id INTEGER PRIMARY KEY CHECK (id = 1), schema_version INTEGER NOT NULL)");
    createTables(connection);
    Integer storedVersion = null;
    try (PreparedStatement statement = connection.prepareStatement(
        "SELECT schema_version FROM schema_metadata WHERE id = 1");
        ResultSet result = statement.executeQuery()) {
      if (result.next()) {
        storedVersion = result.getInt(1);
      }
    }

    if (storedVersion == null) {
      try (PreparedStatement statement = connection.prepareStatement(
          "INSERT INTO schema_metadata (id, schema_version) VALUES (1, ?)");) {
        statement.setInt(1, SCHEMA_VERSION);
        statement.executeUpdate();
      }
    } else if (storedVersion != SCHEMA_VERSION) {
      throw new IllegalStateException(
          "Unsupported SmartFM SQLite schema version " + storedVersion
              + "; expected " + SCHEMA_VERSION + ". Reset the database to initialize the current schema.");
    }
  }

  private static void createTables(Connection connection) throws SQLException {
    String[] ddl = {
      "CREATE TABLE IF NOT EXISTS branches (id TEXT PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, contact_phone TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS customers (id TEXT PRIMARY KEY, full_name TEXT NOT NULL, gender TEXT, date_of_birth TEXT, phone TEXT NOT NULL, email TEXT NOT NULL, address TEXT NOT NULL, registration_date TEXT NOT NULL, status TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS staff_members (id TEXT PRIMARY KEY, full_name TEXT NOT NULL, gender TEXT, date_of_birth TEXT, phone TEXT NOT NULL, email TEXT NOT NULL, address TEXT NOT NULL, role TEXT NOT NULL, home_branch_id TEXT NOT NULL REFERENCES branches(id))",
      "CREATE TABLE IF NOT EXISTS drivers (id TEXT PRIMARY KEY, full_name TEXT NOT NULL, gender TEXT, date_of_birth TEXT, phone TEXT NOT NULL, email TEXT NOT NULL, address TEXT NOT NULL, home_branch_id TEXT NOT NULL REFERENCES branches(id), license_number TEXT NOT NULL, license_expiry TEXT, duty_state TEXT NOT NULL, cumulative_shift_hours REAL NOT NULL)",
      "CREATE TABLE IF NOT EXISTS vehicles (id TEXT PRIMARY KEY, license_plate TEXT NOT NULL, make TEXT NOT NULL, cargo_type TEXT NOT NULL, max_weight_capacity_kg REAL NOT NULL, max_volume_capacity_m3 REAL NOT NULL, status TEXT NOT NULL, branch_id TEXT NOT NULL REFERENCES branches(id))",
      "CREATE TABLE IF NOT EXISTS service_offerings (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL, pricing_tariff_id TEXT)",
      "CREATE TABLE IF NOT EXISTS pricing_tariffs (id TEXT PRIMARY KEY, service_offering_id TEXT NOT NULL REFERENCES service_offerings(id), base_rate REAL NOT NULL, per_km_rate REAL NOT NULL, per_kg_rate REAL NOT NULL, peak_multiplier REAL NOT NULL)",
      "CREATE TABLE IF NOT EXISTS branch_vehicles (branch_id TEXT NOT NULL REFERENCES branches(id), vehicle_id TEXT NOT NULL REFERENCES vehicles(id), position INTEGER NOT NULL, PRIMARY KEY (branch_id, vehicle_id))",
      "CREATE TABLE IF NOT EXISTS branch_drivers (branch_id TEXT NOT NULL REFERENCES branches(id), driver_id TEXT NOT NULL REFERENCES drivers(id), position INTEGER NOT NULL, PRIMARY KEY (branch_id, driver_id))",
      "CREATE TABLE IF NOT EXISTS branch_staff (branch_id TEXT NOT NULL REFERENCES branches(id), staff_id TEXT NOT NULL REFERENCES staff_members(id), position INTEGER NOT NULL, PRIMARY KEY (branch_id, staff_id))",
      "CREATE TABLE IF NOT EXISTS branch_services (branch_id TEXT NOT NULL REFERENCES branches(id), service_offering_id TEXT NOT NULL REFERENCES service_offerings(id), position INTEGER NOT NULL, PRIMARY KEY (branch_id, service_offering_id))",
      "CREATE TABLE IF NOT EXISTS customers_orders (customer_id TEXT NOT NULL REFERENCES customers(id), order_id TEXT NOT NULL, position INTEGER NOT NULL, PRIMARY KEY (customer_id, order_id))",
      "CREATE TABLE IF NOT EXISTS orders (id TEXT PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers(id), service_offering_id TEXT NOT NULL REFERENCES service_offerings(id), origin_branch_id TEXT NOT NULL REFERENCES branches(id), destination_branch_id TEXT NOT NULL REFERENCES branches(id), distance_km REAL NOT NULL, requested_pickup_date TEXT NOT NULL, created_at TEXT NOT NULL, quoted_amount REAL NOT NULL, invoice_id TEXT, state_name TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS consignments (id TEXT PRIMARY KEY, weight_kg REAL NOT NULL, volume_m3 REAL NOT NULL, fragile INTEGER NOT NULL, requires_refrigeration INTEGER NOT NULL, description TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS order_consignments (order_id TEXT NOT NULL REFERENCES orders(id), consignment_id TEXT NOT NULL REFERENCES consignments(id), position INTEGER NOT NULL, PRIMARY KEY (order_id, consignment_id))",
      "CREATE TABLE IF NOT EXISTS shipments (id TEXT PRIMARY KEY, order_id TEXT NOT NULL REFERENCES orders(id), vehicle_id TEXT NOT NULL REFERENCES vehicles(id), driver_id TEXT NOT NULL REFERENCES drivers(id), created_at TEXT NOT NULL, state_name TEXT NOT NULL, last_known_location TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS invoices (id TEXT PRIMARY KEY, order_id TEXT NOT NULL REFERENCES orders(id), total_amount REAL NOT NULL, outstanding_balance REAL NOT NULL, due_date TEXT, created_at TEXT NOT NULL, state_name TEXT NOT NULL)",
      "CREATE TABLE IF NOT EXISTS payments (id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL REFERENCES invoices(id), amount REAL NOT NULL, method TEXT NOT NULL, timestamp TEXT NOT NULL, state_name TEXT NOT NULL, receipt_id TEXT)",
      "CREATE TABLE IF NOT EXISTS invoice_payments (invoice_id TEXT NOT NULL REFERENCES invoices(id), payment_id TEXT NOT NULL REFERENCES payments(id), position INTEGER NOT NULL, PRIMARY KEY (invoice_id, payment_id))",
      "CREATE TABLE IF NOT EXISTS receipts (id TEXT PRIMARY KEY, payment_id TEXT NOT NULL REFERENCES payments(id), invoice_id TEXT NOT NULL REFERENCES invoices(id), amount_settled REAL NOT NULL, issued_at TEXT NOT NULL)"
    };
    for (String statement : ddl) {
      execute(connection, statement);
    }
  }

  private static void writeNormalized(Connection connection, DataStore store) throws SQLException {
    clearNormalized(connection);
    insertBranches(connection, store);
    insertPeopleAndFleet(connection, store);
    insertCatalogue(connection, store);
    insertOrders(connection, store);
    insertShipments(connection, store);
    insertBilling(connection, store);
  }

  private static void insertBranches(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO branches VALUES (?, ?, ?, ?)")) {
      for (Branch value : s.branches.values()) {
        q.setString(1, value.getId()); q.setString(2, value.getName());
        q.setString(3, value.getCity()); q.setString(4, value.getContactPhone()); q.addBatch();
      }
      q.executeBatch();
    }
  }

  private static void insertPeopleAndFleet(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO customers VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
      for (Customer value : s.customers.values()) {
        q.setString(1, value.getId()); q.setString(2, value.getFullName()); q.setString(3, value.getGender());
        setDate(q, 4, value.getDateOfBirth()); q.setString(5, value.getPhone()); q.setString(6, value.getEmail());
        q.setString(7, value.getAddress()); q.setString(8, value.getRegistrationDate().toString());
        q.setString(9, value.getStatus().name()); q.addBatch();
      }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO staff_members VALUES (?, ?, ?, ?, ?, ?, ?, ?, ? )")) {
      for (StaffMember value : s.staffMembers.values()) {
        q.setString(1, value.getId()); q.setString(2, value.getFullName()); q.setString(3, value.getGender());
        setDate(q, 4, value.getDateOfBirth()); q.setString(5, value.getPhone()); q.setString(6, value.getEmail());
        q.setString(7, value.getAddress()); q.setString(8, value.getRole().name()); q.setString(9, value.getHomeBranchId()); q.addBatch();
      }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO drivers VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")) {
      for (Driver value : s.drivers.values()) {
        q.setString(1, value.getId()); q.setString(2, value.getFullName()); q.setString(3, value.getGender());
        setDate(q, 4, value.getDateOfBirth()); q.setString(5, value.getPhone()); q.setString(6, value.getEmail());
        q.setString(7, value.getAddress()); q.setString(8, value.getHomeBranchId()); q.setString(9, value.getLicenseNumber());
        setDate(q, 10, value.getLicenseExpiry()); q.setString(11, value.getDutyState().name()); q.setDouble(12, value.getCumulativeShiftHours()); q.addBatch();
      }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO vehicles VALUES (?, ?, ?, ?, ?, ?, ?, ? )")) {
      for (Vehicle value : s.vehicles.values()) {
        q.setString(1, value.getId()); q.setString(2, value.getLicensePlate()); q.setString(3, value.getMake()); q.setString(4, value.getCargoType());
        q.setDouble(5, value.getMaxWeightCapacityKg()); q.setDouble(6, value.getMaxVolumeCapacityM3()); q.setString(7, value.getStatus().name()); q.setString(8, value.getBranchId()); q.addBatch();
      }
      q.executeBatch();
    }
    insertBranchLinks(c, s);
  }

  private static void insertBranchLinks(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO branch_vehicles VALUES (?, ?, ?)")) {
      for (Branch b : s.branches.values()) for (int i = 0; i < b.getVehicleIds().size(); i++) { q.setString(1,b.getId());q.setString(2,b.getVehicleIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO branch_drivers VALUES (?, ?, ?)")) {
      for (Branch b : s.branches.values()) for (int i = 0; i < b.getDriverIds().size(); i++) { q.setString(1,b.getId());q.setString(2,b.getDriverIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO branch_staff VALUES (?, ?, ?)")) {
      for (Branch b : s.branches.values()) for (int i = 0; i < b.getStaffIds().size(); i++) { q.setString(1,b.getId());q.setString(2,b.getStaffIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
  }

  private static void insertCatalogue(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO service_offerings VALUES (?, ?, ?, ?)")) {
      for (ServiceOffering value : s.serviceOfferings.values()) { q.setString(1,value.getId());q.setString(2,value.getName());q.setString(3,value.getDescription());q.setString(4,value.getPricingTariffId());q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO pricing_tariffs VALUES (?, ?, ?, ?, ?, ?)")) {
      for (PricingTariff value : s.pricingTariffs.values()) { q.setString(1,value.getId());q.setString(2,value.getServiceOfferingId());q.setDouble(3,value.getBaseRate());q.setDouble(4,value.getPerKmRate());q.setDouble(5,value.getPerKgRate());q.setDouble(6,value.getPeakMultiplier());q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO branch_services VALUES (?, ?, ?)")) {
      for (Branch b : s.branches.values()) for (int i = 0; i < b.getServiceOfferingIds().size(); i++) { q.setString(1,b.getId());q.setString(2,b.getServiceOfferingIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
  }

  private static void insertOrders(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
      for (Order value : s.orders.values()) {
        q.setString(1,value.getId());q.setString(2,value.getCustomerId());q.setString(3,value.getServiceOfferingId());q.setString(4,value.getOriginBranchId());q.setString(5,value.getDestinationBranchId());q.setDouble(6,value.getDistanceKm());setDate(q,7,value.getRequestedPickupDate());q.setString(8,value.getCreatedAt().toString());q.setDouble(9,value.getQuotedAmount());q.setString(10,value.getInvoiceId());q.setString(11,value.getStateName());q.addBatch();
      }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO consignments VALUES (?, ?, ?, ?, ?, ?)")) {
      for (Order order : s.orders.values()) for (Consignment value : order.getConsignments()) { q.setString(1,value.getId());q.setDouble(2,value.getWeightKg());q.setDouble(3,value.getVolumeM3());q.setInt(4,value.isFragile()?1:0);q.setInt(5,value.isRequiresRefrigeration()?1:0);q.setString(6,value.getDescription());q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO order_consignments VALUES (?, ?, ?)")) {
      for (Order order : s.orders.values()) for (int i=0;i<order.getConsignments().size();i++) { q.setString(1,order.getId());q.setString(2,order.getConsignments().get(i).getId());q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO customers_orders VALUES (?, ?, ?)")) {
      for (Customer customer : s.customers.values()) for (int i=0;i<customer.getOrderIds().size();i++) { q.setString(1,customer.getId());q.setString(2,customer.getOrderIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
  }

  private static void insertShipments(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO shipments VALUES (?, ?, ?, ?, ?, ?, ?)")) {
      for (Shipment value : s.shipments.values()) { q.setString(1,value.getId());q.setString(2,value.getOrderId());q.setString(3,value.getVehicleId());q.setString(4,value.getDriverId());q.setString(5,value.getCreatedAt().toString());q.setString(6,value.getStateName());q.setString(7,value.getLastKnownLocation());q.addBatch(); }
      q.executeBatch();
    }
  }

  private static void insertBilling(Connection c, DataStore s) throws SQLException {
    try (PreparedStatement q = c.prepareStatement("INSERT INTO invoices VALUES (?, ?, ?, ?, ?, ?, ?)")) {
      for (Invoice value : s.invoices.values()) { q.setString(1,value.getId());q.setString(2,value.getOrderId());q.setDouble(3,value.getTotalAmount());q.setDouble(4,value.getOutstandingBalance());setDate(q,5,value.getDueDate());q.setString(6,value.getCreatedAt().toString());q.setString(7,value.getStateName());q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO payments VALUES (?, ?, ?, ?, ?, ?, ?)")) {
      for (Payment value : s.payments.values()) { q.setString(1,value.getId());q.setString(2,value.getInvoiceId());q.setDouble(3,value.getAmount());q.setString(4,value.getMethod().name());q.setString(5,value.getTimestamp().toString());q.setString(6,value.getStateName());q.setString(7,value.getReceiptId());q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO invoice_payments VALUES (?, ?, ?)")) {
      for (Invoice invoice : s.invoices.values()) for (int i=0;i<invoice.getPaymentIds().size();i++) { q.setString(1,invoice.getId());q.setString(2,invoice.getPaymentIds().get(i));q.setInt(3,i);q.addBatch(); }
      q.executeBatch();
    }
    try (PreparedStatement q = c.prepareStatement("INSERT INTO receipts VALUES (?, ?, ?, ?, ?)")) {
      for (Receipt value : s.receipts.values()) { q.setString(1,value.getId());q.setString(2,value.getPaymentId());q.setString(3,value.getInvoiceId());q.setDouble(4,value.getAmountSettled());q.setString(5,value.getIssuedAt().toString());q.addBatch(); }
      q.executeBatch();
    }
  }

  private static DataStore readNormalized(Connection c) throws SQLException {
    DataStore s = new DataStore();
    readBranches(c,s); readPeopleAndFleet(c,s); readCatalogue(c,s); readOrders(c,s); readShipments(c,s); readBilling(c,s);
    return s;
  }

  private static void readBranches(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,name,city,contact_phone FROM branches ORDER BY rowid")) { while(r.next()) s.branches.put(r.getString(1),new Branch(r.getString(1),r.getString(2),r.getString(3),r.getString(4))); }
  }

  private static void readPeopleAndFleet(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,full_name,gender,date_of_birth,phone,email,address,status FROM customers ORDER BY rowid")) { while(r.next()) { Customer x=new Customer(r.getString(1),r.getString(2),r.getString(3),parseDate(r.getString(4)),r.getString(5),r.getString(6),r.getString(7));x.setStatus(CustomerStatus.valueOf(r.getString(8)));s.customers.put(x.getId(),x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,full_name,gender,date_of_birth,phone,email,address,role,home_branch_id FROM staff_members ORDER BY rowid")) { while(r.next()) { StaffMember x=new StaffMember(r.getString(1),r.getString(2),r.getString(3),parseDate(r.getString(4)),r.getString(5),r.getString(6),r.getString(7),StaffRole.valueOf(r.getString(8)),r.getString(9));s.staffMembers.put(x.getId(),x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,full_name,gender,date_of_birth,phone,email,address,home_branch_id,license_number,license_expiry,duty_state,cumulative_shift_hours FROM drivers ORDER BY rowid")) { while(r.next()) { Driver x=new Driver(r.getString(1),r.getString(2),r.getString(3),parseDate(r.getString(4)),r.getString(5),r.getString(6),r.getString(7),r.getString(8),r.getString(9),parseDate(r.getString(10)));x.setDutyState(DutyState.valueOf(r.getString(11)));x.addShiftHours(r.getDouble(12));s.drivers.put(x.getId(),x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,license_plate,make,cargo_type,max_weight_capacity_kg,max_volume_capacity_m3,status,branch_id FROM vehicles ORDER BY rowid")) { while(r.next()) { Vehicle x=new Vehicle(r.getString(1),r.getString(2),r.getString(3),r.getString(4),r.getDouble(5),r.getDouble(6),r.getString(8));x.setStatus(VehicleStatus.valueOf(r.getString(7)));s.vehicles.put(x.getId(),x); } }
    readBranchLinks(c,s);
  }

  private static void readBranchLinks(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT branch_id,vehicle_id FROM branch_vehicles ORDER BY branch_id,position")) { while(r.next()) if(s.branches.containsKey(r.getString(1))) s.branches.get(r.getString(1)).registerVehicle(r.getString(2)); }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT branch_id,driver_id FROM branch_drivers ORDER BY branch_id,position")) { while(r.next()) if(s.branches.containsKey(r.getString(1))) s.branches.get(r.getString(1)).registerDriver(r.getString(2)); }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT branch_id,staff_id FROM branch_staff ORDER BY branch_id,position")) { while(r.next()) if(s.branches.containsKey(r.getString(1))) s.branches.get(r.getString(1)).registerStaff(r.getString(2)); }
  }

  private static void readCatalogue(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,name,description,pricing_tariff_id FROM service_offerings ORDER BY rowid")) { while(r.next()) { ServiceOffering x=new ServiceOffering(r.getString(1),r.getString(2),r.getString(3));x.setPricingTariffId(r.getString(4));s.serviceOfferings.put(x.getId(),x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,service_offering_id,base_rate,per_km_rate,per_kg_rate,peak_multiplier FROM pricing_tariffs ORDER BY rowid")) { while(r.next()) { PricingTariff x=new PricingTariff(r.getString(1),r.getString(2),r.getDouble(3),r.getDouble(4),r.getDouble(5),r.getDouble(6));s.pricingTariffs.put(x.getId(),x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT branch_id,service_offering_id FROM branch_services ORDER BY branch_id,position")) { while(r.next()) if(s.branches.containsKey(r.getString(1))) { s.branches.get(r.getString(1)).registerServiceOffering(r.getString(2)); if(s.serviceOfferings.containsKey(r.getString(2))) s.serviceOfferings.get(r.getString(2)).addCoveredBranch(r.getString(1)); } }
  }

  private static void readOrders(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,customer_id,service_offering_id,origin_branch_id,destination_branch_id,distance_km,requested_pickup_date,quoted_amount,invoice_id,state_name FROM orders ORDER BY rowid")) { while(r.next()) { Order x=new Order(r.getString(1),r.getString(2),r.getString(3),r.getString(4),r.getString(5),r.getDouble(6),parseDate(r.getString(7)));x.setQuotedAmount(r.getDouble(8));x.setInvoiceId(r.getString(9));x.restoreState(r.getString(10));s.orders.put(x.getId(),x); } }
    Map<String,Consignment> consignments=new LinkedHashMap<>();
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,weight_kg,volume_m3,fragile,requires_refrigeration,description FROM consignments ORDER BY rowid")) { while(r.next()) consignments.put(r.getString(1),new Consignment(r.getString(1),r.getDouble(2),r.getDouble(3),r.getInt(4)!=0,r.getInt(5)!=0,r.getString(6))); }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT order_id,consignment_id FROM order_consignments ORDER BY order_id,position")) { while(r.next()) { Order o=s.orders.get(r.getString(1)); Consignment x=consignments.get(r.getString(2)); if(o!=null&&x!=null)o.addConsignment(x); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT customer_id,order_id FROM customers_orders ORDER BY customer_id,position")) { while(r.next()) { Customer x=s.customers.get(r.getString(1)); if(x!=null)x.recordOrder(r.getString(2)); } }
  }

  private static void readShipments(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,order_id,vehicle_id,driver_id,state_name,last_known_location FROM shipments ORDER BY rowid")) { while(r.next()) { Shipment x=new Shipment(r.getString(1),r.getString(2),r.getString(3),r.getString(4));x.restoreState(r.getString(5));x.updateLocation(r.getString(6));s.shipments.put(x.getId(),x); } }
  }

  private static void readBilling(Connection c, DataStore s) throws SQLException {
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,order_id,total_amount,outstanding_balance,due_date,state_name FROM invoices ORDER BY rowid")) { while(r.next()) s.invoices.put(r.getString(1),new Invoice(r.getString(1),r.getString(2),r.getDouble(3),parseDate(r.getString(5)))); }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,invoice_id,amount,method,state_name,receipt_id FROM payments ORDER BY rowid")) { while(r.next()) { Payment x=new Payment(r.getString(1),r.getString(2),r.getDouble(3),PaymentMethod.valueOf(r.getString(4)));x.restoreState(r.getString(5));x.setReceiptId(r.getString(6));s.payments.put(x.getId(),x); } }
    Map<String,List<String>> links=new LinkedHashMap<>();
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT invoice_id,payment_id FROM invoice_payments ORDER BY invoice_id,position")) { while(r.next()) links.computeIfAbsent(r.getString(1),key->new ArrayList<>()).add(r.getString(2)); }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,order_id,total_amount,outstanding_balance,due_date,state_name FROM invoices ORDER BY rowid")) { while(r.next()) { Invoice x=s.invoices.get(r.getString(1)); if(x!=null)x.restoreState(r.getString(6),r.getDouble(4),links.getOrDefault(x.getId(),List.of())); } }
    try (Statement q=c.createStatement(); ResultSet r=q.executeQuery("SELECT id,payment_id,invoice_id,amount_settled FROM receipts ORDER BY rowid")) { while(r.next()) s.receipts.put(r.getString(1),new Receipt(r.getString(1),r.getString(2),r.getString(3),r.getDouble(4))); }
  }

  private static void clearNormalized(Connection c) throws SQLException {
    String[] tables={"invoice_payments","receipts","payments","invoices","shipments","order_consignments","consignments","customers_orders","orders","branch_services","branch_staff","branch_drivers","branch_vehicles","pricing_tariffs","service_offerings","vehicles","drivers","staff_members","customers","branches"};
    for(String table:tables) execute(c,"DELETE FROM "+table);
  }

  private static void execute(Connection c, String sql) throws SQLException { try (Statement q=c.createStatement()) { q.executeUpdate(sql); } }
  private static void setDate(PreparedStatement q,int index,LocalDate value) throws SQLException { if(value==null) q.setNull(index,java.sql.Types.VARCHAR); else q.setString(index,value.format(DB_DATE_FORMAT)); }
  private static LocalDate parseDate(String value) { if(value==null||value.trim().isEmpty()) return null; String t=value.trim(); try { return LocalDate.parse(t,DB_DATE_FORMAT); } catch(DateTimeParseException e) { return LocalDate.parse(t); } }
  private static String sqliteUrl(Path path) { return "jdbc:sqlite:"+path.toAbsolutePath(); }
  private static void ensureParentDirectory(Path path) { try { Path parent=path.toAbsolutePath().getParent(); if(parent!=null)Files.createDirectories(parent); } catch(IOException e){throw new IllegalStateException("Failed to create database directory for "+path,e);} }
  private static void ensureJdbcDriver() { try { Class.forName(SQLITE_DRIVER); } catch(ClassNotFoundException e){throw new IllegalStateException("SQLite JDBC driver is unavailable.",e);} }
  private static void enableForeignKeys(Connection c) throws SQLException { execute(c,"PRAGMA foreign_keys = ON"); }
  private static void rollback(Connection c, Exception original) {
    try {
      c.rollback();
    } catch (SQLException rollback) {
      original.addSuppressed(rollback);
    }
  }
}
