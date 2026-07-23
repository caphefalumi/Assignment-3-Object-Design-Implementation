package smartfm.infrastructure;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import smartfm.domain.customer.Customer;
import smartfm.domain.catalog.ServiceOffering;
import smartfm.domain.fleet.Branch;
import smartfm.domain.order.Order;

@DisplayName("DataStore Persistence Infrastructure Tests")
class DataStoreTest {

  private Path testDbPath;

  @BeforeEach
  void setUp() throws IOException {
    testDbPath = Path.of("target", "test-data", "test-smartfm.db");
    Files.createDirectories(testDbPath.getParent());
    Files.deleteIfExists(testDbPath);
  }

  @AfterEach
  void tearDown() throws IOException {
    Files.deleteIfExists(testDbPath);
  }

  @Test
  @DisplayName("Should save normalized DataStore rows to SQLite and load them back accurately")
  void testSaveAndLoadFromSQLite() {
    DataStore originalStore = new DataStore();

    Branch branch = new Branch("BR-MEL", "Melbourne", "Melbourne", "+61391234567");
    Branch destination = new Branch("BR-SYD", "Sydney", "Sydney", "+61291234567");
    originalStore.branches().put("BR-MEL", branch);
    originalStore.branches().put("BR-SYD", destination);
    ServiceOffering service = new ServiceOffering("SVC-STD", "Standard", "Standard freight service");
    originalStore.serviceOfferings().put(service.getId(), service);

    Customer customer = new Customer("CUST-100", "Charlie Brown", "Male",
        LocalDate.of(1995, 8, 15), "+61400000000", "charlie@example.com", "Address");
    originalStore.customers().put("CUST-100", customer);

    Order order = new Order("ORD-500", "CUST-100", "SVC-STD", "BR-MEL", "BR-SYD", 100.0, LocalDate.now().plusDays(2));
    originalStore.orders().put("ORD-500", order);

    originalStore.saveTo(testDbPath);
    assertTrue(Files.exists(testDbPath));

    DataStore reloadedStore = DataStore.loadFrom(testDbPath);

    assertNotNull(reloadedStore);
    assertEquals(2, reloadedStore.branches().size());
    assertEquals("Melbourne", reloadedStore.branches().get("BR-MEL").getName());

    assertEquals(1, reloadedStore.customers().size());
    assertEquals("Charlie Brown", reloadedStore.customers().get("CUST-100").getFullName());

    assertEquals(1, reloadedStore.orders().size());
    assertEquals("Submitted", reloadedStore.orders().get("ORD-500").getStateName());
  }
}
