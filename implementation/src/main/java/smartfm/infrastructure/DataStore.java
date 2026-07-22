package smartfm.infrastructure;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import smartfm.domain.Branch;
import smartfm.domain.Customer;
import smartfm.domain.Driver;
import smartfm.domain.Invoice;
import smartfm.domain.Order;
import smartfm.domain.Payment;
import smartfm.domain.PricingTariff;
import smartfm.domain.Receipt;
import smartfm.domain.ServiceOffering;
import smartfm.domain.Shipment;
import smartfm.domain.StaffMember;
import smartfm.domain.Vehicle;

/**
 * File-based persistent data store for SmartFM.
 *
 * <p>Assignment 1 Assumption A1 states that "all system data is stored
 * in a single, shared relational database ... outside the scope of this
 * high-level design", and the Assignment 3 brief explicitly permits
 * "files may also be used for persistent data storage, instead of using
 * databases" as a simplification for the implementation stage. This
 * class is the concrete data access layer that Assumption A1 deferred:
 * it holds every long-lived aggregate in memory as a plain {@link Map}
 * keyed by id, and persists the entire snapshot to a single binary file
 * on disk using standard JDK object serialization (every domain class
 * already implements {@link Serializable} for exactly this reason).
 *
 * <p>This keeps the domain classes completely unaware of how or where
 * they are stored (Assignment 2 Section 4.1.3, low coupling): {@code
 * Order}, {@code Invoice}, etc. have no knowledge of {@code DataStore}.
 * Repository classes in this package are the only collaborators that
 * touch {@code DataStore} directly.
 */
public final class DataStore implements Serializable {

  private static final long serialVersionUID = 1L;

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

  public Map<String, Customer> customers() {
    return customers;
  }

  public Map<String, StaffMember> staffMembers() {
    return staffMembers;
  }

  public Map<String, Driver> drivers() {
    return drivers;
  }

  public Map<String, Branch> branches() {
    return branches;
  }

  public Map<String, Vehicle> vehicles() {
    return vehicles;
  }

  public Map<String, ServiceOffering> serviceOfferings() {
    return serviceOfferings;
  }

  public Map<String, PricingTariff> pricingTariffs() {
    return pricingTariffs;
  }

  public Map<String, Order> orders() {
    return orders;
  }

  public Map<String, Shipment> shipments() {
    return shipments;
  }

  public Map<String, Invoice> invoices() {
    return invoices;
  }

  public Map<String, Payment> payments() {
    return payments;
  }

  public Map<String, Receipt> receipts() {
    return receipts;
  }

  /** Persists this entire snapshot to {@code path} in one atomic write. */
  public void saveTo(Path path) {
    try {
      Path tmp = path.resolveSibling(path.getFileName().toString() + ".tmp");
      Files.createDirectories(path.toAbsolutePath().getParent());
      try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(tmp.toFile()))) {
        out.writeObject(this);
      }
      Files.move(tmp, path, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
    } catch (IOException exc) {
      throw new IllegalStateException("Failed to persist SmartFM data store to " + path, exc);
    }
  }

  /** Loads a previously persisted snapshot, or returns a fresh empty store if none exists. */
  public static DataStore loadFrom(Path path) {
    if (!Files.exists(path)) {
      return new DataStore();
    }
    try (ObjectInputStream in = new ObjectInputStream(new FileInputStream(path.toFile()))) {
      Object obj = in.readObject();
      if (obj instanceof DataStore) {
        return (DataStore) obj;
      }
      throw new IllegalStateException("Data file " + path + " did not contain a DataStore.");
    } catch (IOException | ClassNotFoundException exc) {
      throw new IllegalStateException("Failed to load SmartFM data store from " + path, exc);
    }
  }
}
