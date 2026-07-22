# SmartFM - Assignment 3 Implementation

Java 17, standard library only at runtime (no external dependencies).
Packaged as a standard Maven project (`pom.xml`, `src/main/java`
layout) so it opens directly in any Maven-aware IDE; it also compiles
with plain `javac` if Maven is not installed. Implements four business
areas from the Assignment 1 SRS / Assignment 2 object design:

1. **Order Management** (`smartfm.application.OrderProcessor`)
2. **Fleet Dispatch** (`smartfm.application.DispatchManager`)
3. **Shipment Tracking** (`smartfm.application.ShipmentTracker`)
4. **Billing and Payment** (`smartfm.application.PaymentProcessor`)

Two presentation layers are provided over the same controller/domain
layer: a graphical (Swing) interface, `smartfm.ui.gui`, and a textual
(CLI) interface, `smartfm.ui.SmartFmConsoleApp`.

## Layout

```
pom.xml                        Maven project descriptor (Java 17, JUnit 5 test dep, executable jar)
src/main/java/smartfm/common/         Shared exceptions, validators, Money formatter
src/main/java/smartfm/domain/         Entities, State pattern hierarchies, Strategy/Adapter interfaces
src/main/java/smartfm/application/    The four controllers, Observer listener interfaces, Bootstrap
src/main/java/smartfm/infrastructure/ DataStore - file-based persistence (Java object serialization)
src/main/java/smartfm/ui/             Launcher (entry point) + textual (CLI) user interface
src/main/java/smartfm/ui/gui/         Graphical (Swing) user interface
src/main/resources/             Reserved for future non-code resources (currently empty)
src/test/java/                  Reserved test source root (Maven-standard convention)
tools/java/smartfm/ui/gui/      ScreenshotDriver - development-time evidence-capture tool, not shipped
scenarios/                      Scripted input files used to exercise each business area (CLI)
transcripts/                    Captured console output from running each scenario (evidence)
```

## Build

With Maven:

```
mvn package
```

Without Maven (plain javac fallback):

```
Get-ChildItem -Recurse -Filter *.java src/main/java | ForEach-Object { '"' + ($_.FullName -replace '\\','/') + '"' } | Set-Content -Encoding UTF8 sources.txt
javac -d target/classes -encoding UTF-8 "@sources.txt"
```

## Run

Graphical interface (default):

```
java -jar target/smartfm.jar
```

or, without the jar:

```
java -cp target/classes smartfm.ui.Launcher
```

Textual (CLI) interface:

```
java -jar target/smartfm.jar --cli
```

or:

```
java -cp target/classes smartfm.ui.Launcher --cli
```

Data persists to `data/smartfm-store.dat` between runs, shared by both
interfaces. Delete that file to reset to a fresh seeded state (2
branches, 3 vehicles, 3 drivers, 3 service offerings).

## Replaying the recorded CLI scenarios

```
Get-Content scenarios/01_register_customers.txt | java -cp target/classes smartfm.ui.Launcher --cli
```

Run `01` through `05` in order against a freshly deleted `data/` folder
to reproduce the raw output captured in `transcripts/`. Note that
`transcripts/02_place_and_manage_orders.txt` and
`transcripts/04_tracking.txt` were subsequently split into smaller
files (`02a`/`02a2`/`02b`/`02c` and `04a`/`04b`) purely so each figure
fits on one page in `asm3.typ`; the content is identical, just divided
at clean menu boundaries.

## Capturing GUI screenshots (optional, run on your own machine)

`tools/java/smartfm/ui/gui/ScreenshotDriver.java` drives the real GUI
through the same five scenarios as the CLI transcripts and saves a
screenshot of only the application window (never the full desktop)
after each step, to `screenshots/`. It is not part of the shipped
application. To run it:

```
javac -d target/tools-classes -cp target/classes -encoding UTF-8 tools/java/smartfm/ui/gui/ScreenshotDriver.java
java -cp "target/classes;target/tools-classes" smartfm.ui.gui.ScreenshotDriver
```

Run this on a machine where no other window is likely to be brought to
the foreground during the ~10 second capture sequence, and check each
screenshot before using it as evidence.
