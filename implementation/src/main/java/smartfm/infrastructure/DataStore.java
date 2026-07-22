package smartfm.infrastructure;

import static org.jooq.impl.DSL.check;
import static org.jooq.impl.DSL.field;
import static org.jooq.impl.DSL.name;
import static org.jooq.impl.DSL.primaryKey;
import static org.jooq.impl.DSL.table;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.jooq.DSLContext;
import org.jooq.Field;
import org.jooq.Record;
import org.jooq.SQLDialect;
import org.jooq.Table;
import org.jooq.impl.DSL;
import org.jooq.impl.SQLDataType;
import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.Payment;
import smartfm.domain.billing.Receipt;
import smartfm.domain.catalog.PricingTariff;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.StaffMember;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.order.Order;
import smartfm.domain.shipment.Shipment;

/**
 * SQLite-backed persistence gateway for SmartFM.
 *
 * <p>Assignment 2 Assumption A1 specifies a single shared relational
 * database behind a data-access layer. This class is that layer: it keeps
 * the existing controller-facing map API in memory, but commits the durable
 * snapshot to {@code data/smartfm.db} with jOOQ's typed SQLite DSL. Domain
 * classes do not know about JDBC, SQL, jOOQ, or this class.
 *
 * <p>The small schema contains a versioned metadata row and one transactionally
 * updated snapshot row. The snapshot payload preserves the existing aggregate
 * graph, including State-pattern objects and consignment collections, while
 * SQLite provides a real database file, atomic transaction boundaries, and a
 * clear migration point for future per-entity repository tables.
 */
public final class DataStore implements Serializable {

  private static final long serialVersionUID = 1L;
  private static final int SCHEMA_VERSION = 1;
  private static final String SQLITE_DRIVER = "org.sqlite.JDBC";

  private static final Table<Record> SCHEMA_METADATA = table(name("schema_metadata"));
  private static final Field<Integer> METADATA_ID =
      field(name("id"), SQLDataType.INTEGER.notNull());
  private static final Field<Integer> SCHEMA_VERSION_FIELD =
      field(name("schema_version"), SQLDataType.INTEGER.notNull());
  private static final Table<Record> STORE_SNAPSHOT = table(name("store_snapshot"));
  private static final Field<Integer> SNAPSHOT_ID =
      field(name("snapshot_id"), SQLDataType.INTEGER.notNull());
  private static final Field<byte[]> SNAPSHOT_PAYLOAD =
      field(name("payload"), SQLDataType.BLOB.notNull());
  private static final Field<String> SNAPSHOT_UPDATED_AT =
      field(name("updated_at"), SQLDataType.VARCHAR.notNull());

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

  /** Saves this aggregate snapshot in one jOOQ-managed SQLite transaction. */
  public void saveTo(Path databasePath) {
    ensureParentDirectory(databasePath);
    ensureJdbcDriver();
    try (Connection connection = DriverManager.getConnection(sqliteUrl(databasePath))) {
      DSLContext context = DSL.using(connection, SQLDialect.SQLITE);
      context.transaction(configuration -> {
        DSLContext transaction = DSL.using(configuration);
        initializeSchema(transaction);
        byte[] payload = serialize(this);
        String updatedAt = Instant.now().toString();
        transaction.insertInto(STORE_SNAPSHOT)
            .columns(SNAPSHOT_ID, SNAPSHOT_PAYLOAD, SNAPSHOT_UPDATED_AT)
            .values(1, payload, updatedAt)
            .onConflict(SNAPSHOT_ID)
            .doUpdate()
            .set(SNAPSHOT_PAYLOAD, payload)
            .set(SNAPSHOT_UPDATED_AT, updatedAt)
            .execute();
      });
    } catch (SQLException exception) {
      throw new IllegalStateException("Failed to save SmartFM SQLite database to " + databasePath, exception);
    }
  }

  /** Loads the persisted SQLite snapshot, or returns an empty store for a new database. */
  public static DataStore loadFrom(Path databasePath) {
    ensureParentDirectory(databasePath);
    ensureJdbcDriver();
    try (Connection connection = DriverManager.getConnection(sqliteUrl(databasePath))) {
      DSLContext context = DSL.using(connection, SQLDialect.SQLITE);
      return context.transactionResult(configuration -> {
        DSLContext transaction = DSL.using(configuration);
        initializeSchema(transaction);
        byte[] payload = transaction.select(SNAPSHOT_PAYLOAD)
            .from(STORE_SNAPSHOT)
            .where(SNAPSHOT_ID.eq(1))
            .fetchOne(SNAPSHOT_PAYLOAD);
        return payload == null ? new DataStore() : deserialize(payload);
      });
    } catch (SQLException exception) {
      throw new IllegalStateException("Failed to load SmartFM SQLite database from " + databasePath, exception);
    }
  }

  private static void initializeSchema(DSLContext context) {
    context.createTableIfNotExists(SCHEMA_METADATA)
        .column(METADATA_ID)
        .column(SCHEMA_VERSION_FIELD)
        .constraints(primaryKey(METADATA_ID), check(METADATA_ID.eq(1)))
        .execute();
    context.createTableIfNotExists(STORE_SNAPSHOT)
        .column(SNAPSHOT_ID)
        .column(SNAPSHOT_PAYLOAD)
        .column(SNAPSHOT_UPDATED_AT)
        .constraints(primaryKey(SNAPSHOT_ID), check(SNAPSHOT_ID.eq(1)))
        .execute();

    Integer storedVersion = context.select(SCHEMA_VERSION_FIELD)
        .from(SCHEMA_METADATA)
        .where(METADATA_ID.eq(1))
        .fetchOne(SCHEMA_VERSION_FIELD);
    if (storedVersion == null) {
      context.insertInto(SCHEMA_METADATA)
          .columns(METADATA_ID, SCHEMA_VERSION_FIELD)
          .values(1, SCHEMA_VERSION)
          .execute();
      return;
    }
    if (storedVersion != SCHEMA_VERSION) {
      throw new IllegalStateException(
          "Unsupported SmartFM SQLite schema version " + storedVersion
              + "; expected " + SCHEMA_VERSION + ".");
    }
  }

  private static String sqliteUrl(Path databasePath) {
    return "jdbc:sqlite:" + databasePath.toAbsolutePath();
  }

  private static void ensureParentDirectory(Path path) {
    try {
      Path parent = path.toAbsolutePath().getParent();
      if (parent != null) {
        Files.createDirectories(parent);
      }
    } catch (IOException exception) {
      throw new IllegalStateException("Failed to create database directory for " + path, exception);
    }
  }

  private static void ensureJdbcDriver() {
    try {
      Class.forName(SQLITE_DRIVER);
    } catch (ClassNotFoundException exception) {
      throw new IllegalStateException(
          "SQLite JDBC driver is unavailable. Build with the pinned sqlite-jdbc dependency.", exception);
    }
  }

  private static byte[] serialize(DataStore store) {
    try (ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ObjectOutputStream output = new ObjectOutputStream(bytes)) {
      output.writeObject(store);
      output.flush();
      return bytes.toByteArray();
    } catch (IOException exception) {
      throw new IllegalStateException("Failed to serialize SmartFM database snapshot", exception);
    }
  }

  private static DataStore deserialize(byte[] payload) {
    try (ObjectInputStream input = new ObjectInputStream(new ByteArrayInputStream(payload))) {
      Object value = input.readObject();
      if (value instanceof DataStore) {
        return (DataStore) value;
      }
      throw new IllegalStateException("SQLite snapshot did not contain a DataStore.");
    } catch (IOException | ClassNotFoundException exception) {
      throw new IllegalStateException("Failed to deserialize SmartFM SQLite snapshot", exception);
    }
  }
}
