# SmartFM – Assignment 3 Implementation

SmartFM is a **Java 26** Swing desktop application for the Smart Fleet Management System. It implements four connected business operational areas from the Assignment 1 SRS and Assignment 2 Object Design:

1. **Order Management** — `smartfm.application.OrderProcessor`
2. **Fleet Dispatch** — `smartfm.application.DispatchManager`
3. **Shipment Tracking** — `smartfm.application.ShipmentTracker`
4. **Billing and Payment** — `smartfm.application.PaymentProcessor`

The user interface is built using Java Swing (`smartfm.ui.gui.*`). UI panels collect user input and display system results by delegating directly to the four GRASP application controllers.

---

## Embedded SQLite Persistence

Assignment 2 assumed a shared relational database. Assignment 3 implements that boundary with embedded **SQLite** and versioned normalized tables:

* **Database File**: `data/smartfm.db`
* **JDBC Driver**: Xerial SQLite JDBC `3.46.1.0`
* **Supporting Runtime Libraries**: JAXB, R2DBC/Reactive Streams, SLF4J API and no-op binding `1.7.36`
* **Schema**: `schema_metadata` records the schema version (v3); normalized relational tables persist branches, staff/drivers, customers, vehicles, service offerings, tariffs, orders, consignments, shipments, invoices, payments, receipts, and association links.

`DataStore` serves as the single infrastructure gateway facade. It executes prepared SQL statements inside atomic SQLite JDBC transactions to manage persistence while keeping domain entities and controllers completely independent of SQL and JDBC.

---

## Project Layout

```text
pom.xml                                  Maven descriptor (Java 26 release target & dependencies)
Makefile                                 Cross-platform build script (Windows / POSIX)
lib/                                     Pinned local SQLite JDBC and SLF4J runtime JARs
data/                                    Embedded SQLite database storage (smartfm.db)
src/main/java/smartfm/common/            Shared Money formatter, Validators, and Exceptions
src/main/java/smartfm/domain/            6 domain sub-packages (customer, order, shipment, billing, fleet, catalog)
src/main/java/smartfm/application/       Four GRASP Controllers, Observer listeners, Bootstrap
src/main/java/smartfm/infrastructure/    DataStore normalized SQLite database gateway
src/main/java/smartfm/ui/                Launcher
src/main/java/smartfm/ui/gui/            Swing GUI panels, SmartFmMainFrame, and UI components
src/test/java/                           JUnit 5 test suite (76 automated tests)
screenshots/                             Generated GUI evidence PNG images
tools/java/                              ScreenshotDriver automated UI evidence tool
```

---

## Build & Run Instructions

### Prerequisites
* **JDK 26** installed and configured (`JAVA_HOME` pointing to JDK 26)
* Running under Java 26 requires `--enable-native-access=ALL-UNNAMED` for SQLite JDBC native library loading.

### Option A: Maven (Recommended)

```bash
# Run Checkstyle audit and all 76 JUnit 5 automated tests
mvn test

# Package self-contained executable JAR
mvn package

# Run the application
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar
```

### Option B: GNU Make

```bash
# Compile Java sources with -Xlint:all
make compile

# Run Swing GUI application
make run

# Build target/smartfm.jar with target/lib/ dependencies
make jar

# Compile automated ScreenshotDriver tool
make tools
```

---

## Resetting Demonstration Data

To reset the SQLite database to its clean seeded state (two branches, three vehicles, three drivers, and three service offerings):

```bash
make reset
```

This removes `data/smartfm.db` and any SQLite `-wal`/`-shm` sidecar files.

---

## Generating Screenshot Evidence

`tools/java/smartfm/ui/gui/ScreenshotDriver.java` drives the real Swing GUI through five operational scenario flows and captures window screenshots directly under `screenshots/`:

```bash
make screenshots
```

This command resets the demonstration database, compiles the application and tools, executes the scenario walkthroughs, saves PNG screenshots, and exits cleanly.
