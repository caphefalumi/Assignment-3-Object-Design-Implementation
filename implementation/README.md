# SmartFM - Assignment 3 Implementation

Java 17, standard library only (no external dependencies, no build tool
required beyond `javac`/`java`). Implements four business areas from the
Assignment 1 SRS / Assignment 2 object design:

1. **Order Management** (`smartfm.application.OrderProcessor`)
2. **Fleet Dispatch** (`smartfm.application.DispatchManager`)
3. **Shipment Tracking** (`smartfm.application.ShipmentTracker`)
4. **Billing and Payment** (`smartfm.application.PaymentProcessor`)

## Layout

```
src/smartfm/common/        Shared exceptions, validators, Money formatter
src/smartfm/domain/        Entities, State pattern hierarchies, Strategy/Adapter interfaces
src/smartfm/application/   The four controllers, Observer listener interfaces, Bootstrap
src/smartfm/infrastructure/DataStore - file-based persistence (Java object serialization)
src/smartfm/ui/            Textual (CLI) user interface
scenarios/                 Scripted input files used to exercise each business area
transcripts/               Captured console output from running each scenario (evidence)
```

## Build

```
Get-ChildItem -Recurse -Filter *.java src | ForEach-Object { '"' + ($_.FullName -replace '\\','/') + '"' } | Set-Content -Encoding UTF8 sources.txt
javac -d out -encoding UTF-8 "@sources.txt"
```

## Run

```
java -cp out smartfm.ui.SmartFmConsoleApp
```

Data persists to `data/smartfm-store.dat` between runs. Delete that file
to reset to a fresh seeded state (2 branches, 3 vehicles, 3 drivers, 3
service offerings).

## Replaying the recorded scenarios

```
Get-Content scenarios/01_register_customers.txt | java -cp out smartfm.ui.SmartFmConsoleApp
```

Run `01` through `05` in order against a freshly deleted `data/` folder
to reproduce the raw output captured in `transcripts/`. Note that
`transcripts/02_place_and_manage_orders.txt` and
`transcripts/04_tracking.txt` were subsequently split into smaller
files (`02a`/`02a2`/`02b`/`02c` and `04a`/`04b`) purely so each figure
fits on one page in `asm3.typ`; the content is identical, just divided
at clean menu boundaries.
