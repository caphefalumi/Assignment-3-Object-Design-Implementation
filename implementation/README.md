# SmartFM – Assignment 3 Implementation

SmartFM is a **Java 26** desktop application for the Smart Fleet Management System. It implements four connected business areas from the Assignment 1 SRS and Assignment 2 object design:

1. **Order Management** — `smartfm.application.OrderProcessor`
2. **Fleet Dispatch** — `smartfm.application.DispatchManager`
3. **Shipment Tracking** — `smartfm.application.ShipmentTracker`
4. **Billing and Payment** — `smartfm.application.PaymentProcessor`

Both a Swing GUI (`smartfm.ui.gui`) and a CLI (`smartfm.ui.SmartFmConsoleApp`) call the same application/domain controllers.

## SQLite persistence with jOOQ

Assignment 2 assumed a shared relational database. Assignment 3 implements that boundary with embedded **SQLite** and the **jOOQ SQL DSL**:

- Database: `data/smartfm.db`
- SQL DSL: jOOQ `3.20.0`
- JDBC driver: Xerial SQLite JDBC `3.46.1.0`
- jOOQ runtime closure: R2DBC SPI `1.0.0.RELEASE`, Reactive Streams `1.0.3`, Jakarta XML Bind API `4.0.1`, and Jakarta Activation API `2.1.2`
- Supporting logging API: SLF4J API and no-op binding `1.7.36`
- Schema: `schema_metadata` records the schema version and `store_snapshot` stores the SmartFM aggregate snapshot transactionally.

`DataStore` remains the single infrastructure facade used by application startup and shutdown. It uses jOOQ's typed SQLite DSL for `CREATE TABLE IF NOT EXISTS`, schema-version reads/inserts, snapshot reads, and conflict-upsert writes; the only direct JDBC usage is acquiring the SQLite connection for jOOQ. Domain classes and controllers remain independent of jOOQ, JDBC, and SQL. SQLite is embedded: no database server, account, or network connection is needed. The old `data/smartfm-store.dat` serialization file is not read or deleted automatically.

## Project layout

```text
pom.xml                                  Maven descriptor; Java 26 and pinned SQLite/jOOQ dependencies
lib/                                     Pinned local SQLite, jOOQ, JAXB, and SLF4J runtime JARs
src/main/java/smartfm/common/            Exceptions, validators, Money formatter
src/main/java/smartfm/domain/            6 domain sub-packages (customer, order, shipment, billing, fleet, catalog)
src/main/java/smartfm/application/       Four GRASP Controllers, Observer listeners, Bootstrap
src/main/java/smartfm/infrastructure/    DataStore: jOOQ-backed SQLite database gateway
src/main/java/smartfm/ui/                Launcher and CLI
src/main/java/smartfm/ui/gui/            Swing GUI
src/main/resources/                      Reserved Maven resource root
src/test/java/                           JUnit 5 unit & integration test suite (55 tests)
scenarios/                               Scripted CLI inputs for the five scenario flows
transcripts/                             Compilation and CLI execution evidence
screenshots/                             Generated GUI evidence images
tools/java/                              ScreenshotDriver (development/evidence tool, not packaged application code)
```

## Build

A **Java 26 JDK** is required. On this Windows development machine, Azul Zulu JDK 26 is installed at `C:\Program Files\Zulu\zulu-26`. In a new PowerShell session, select any Java 26 JDK before building:

```powershell
$env:JAVA_HOME = "C:\Program Files\Zulu\zulu-26"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
java -version
javac -version
```

### Option A: GNU Make (verified on Windows)

From `implementation/`, with Java 26+ and GNU Make installed:

```text
make compile      # Compiles 74 production classes with -Xlint:all
make tools        # Compiles ScreenshotDriver
make jar          # Builds target/smartfm.jar and target/lib/ runtime dependencies
```

The Makefile has separate Windows and POSIX recipes. On Windows it has been verified with GNU Make 4.4.1 and PowerShell. The pinned JARs under `lib/` must remain beside the source code. Its run targets provide Java 26 native access for SQLite automatically.

### Option B: Maven

With Maven installed and running under Java 26:

```text
mvn package
```

`pom.xml` sets `maven.compiler.release` to `26`. Maven resolves the pinned dependencies and uses the Shade plugin to produce a self-contained executable `target/smartfm.jar`.

### Option C: Plain `javac` fallback (PowerShell)

```powershell
$deps = @(
  "lib/sqlite-jdbc-3.46.1.0.jar",
  "lib/jooq-3.20.0.jar",
  "lib/r2dbc-spi-1.0.0.RELEASE.jar",
  "lib/reactive-streams-1.0.3.jar",
  "lib/jakarta.xml.bind-api-4.0.1.jar",
  "lib/jakarta.activation-api-2.1.2.jar",
  "lib/slf4j-api-1.7.36.jar",
  "lib/slf4j-nop-1.7.36.jar"
) -join ';'
New-Item -ItemType Directory -Force target/classes | Out-Null
$sources = Get-ChildItem -Recurse -Filter *.java src/main/java | ForEach-Object { $_.FullName }
javac --release 26 -cp $deps -d target/classes -encoding UTF-8 -Xlint:all $sources
```

## Run

### Graphical interface

```text
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar
```

The native-access flag permits the SQLite JDBC driver to load its embedded SQLite library under Java 26. The Makefile JAR uses `target/lib/` for the SQLite/jOOQ/JAXB/SLF4J runtime libraries, so keep that directory next to `target/smartfm.jar`. Alternatively:

```text
make run
```

### Textual interface

```text
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar --cli
```

or:

```text
make run-cli
```

For a plain-JDK build on Windows:

```powershell
$deps = "target/classes;" + (@(
  "lib/sqlite-jdbc-3.46.1.0.jar",
  "lib/jooq-3.20.0.jar",
  "lib/r2dbc-spi-1.0.0.RELEASE.jar",
  "lib/reactive-streams-1.0.3.jar",
  "lib/jakarta.xml.bind-api-4.0.1.jar",
  "lib/jakarta.activation-api-2.1.2.jar",
  "lib/slf4j-api-1.7.36.jar",
  "lib/slf4j-nop-1.7.36.jar"
) -join ';')
java --enable-native-access=ALL-UNNAMED -cp $deps smartfm.ui.Launcher
java --enable-native-access=ALL-UNNAMED -cp $deps smartfm.ui.Launcher --cli
```

The GUI is the default. Pass `--cli` for the repeatable textual interface.

## Resetting demonstration data

```text
make reset
```

This deletes `data/smartfm.db` and any SQLite `-wal`/`-shm` sidecars, then recompiles on the next build. A fresh startup seeds two branches, three vehicles, three drivers, and three service offerings. It intentionally does **not** delete the legacy `smartfm-store.dat` file.

## Replaying CLI scenarios

After `make reset` then `make compile`, run the scenario input files in numerical order. For example, in PowerShell:

```powershell
$cp = "target/classes;" + (@(
  "lib/sqlite-jdbc-3.46.1.0.jar",
  "lib/jooq-3.20.0.jar",
  "lib/r2dbc-spi-1.0.0.RELEASE.jar",
  "lib/reactive-streams-1.0.3.jar",
  "lib/jakarta.xml.bind-api-4.0.1.jar",
  "lib/jakarta.activation-api-2.1.2.jar",
  "lib/slf4j-api-1.7.36.jar",
  "lib/slf4j-nop-1.7.36.jar"
) -join ';')
Get-Content scenarios/01_register_customers.txt | java --enable-native-access=ALL-UNNAMED -cp $cp smartfm.ui.Launcher --cli
```

Scenarios 01–05 must be run in order against the same SQLite database so later operations can use the customers, approved order, shipment, and invoice created earlier.

## GUI screenshot evidence

`tools/java/smartfm/ui/gui/ScreenshotDriver.java` drives the real Swing GUI through the five scenarios and generates images under `screenshots/`. The capture helper renders the SmartFM frame directly, so no desktop/browser content is included.

```text
make screenshots
```

The command resets only the local SQLite demonstration database, compiles the application/tool, generates the screenshots, saves the final database snapshot, and exits automatically.
