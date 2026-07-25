# SmartFM — Smart Fleet Management System (Assignment 3)

**Course**: SWE30003 — Software Architectures and Design  
**Institution**: Swinburne University of Technology  
**Project**: SmartFM Desktop Application (Object Design Implementation & Reflection)  
**Stack**: Java 26, Swing GUI, SQLite JDBC 3.46.1.0, JUnit 5, Typst  

---

## Team Members

| Name | Student ID | Email | Contribution |
| :--- | :---: | :--- | :---: |
| **Dang Duy Toan** | `105508402` | `105508402@student.swin.edu.au` | 25.0% (10.0 hrs) |
| **Phan Le Minh Hieu** | `105543377` | `105543377@student.swin.edu.au` | 25.0% (10.0 hrs) |
| **Vo Ngoc Nam** | `105551859` | `105551859@student.swin.edu.au` | 25.0% (10.0 hrs) |
| **Lam An Thinh** | `105508512` | `105508512@student.swin.edu.au` | 25.0% (10.0 hrs) |

---

## Project Overview

SmartFM is a fleet-logistics desktop application developed in Java 26 for ABC-Trans. It implements the object design refined from Assignment 2 across four core business operational areas:

1. **Order Management** — Customer registration, cargo consignment creation, quotation, order submission, approval, rejection, and cancellation (`smartfm.application.OrderProcessor`).
2. **Fleet Dispatch** — Vehicle capacity and driver qualification verification, resource scheduling, and shipment dispatch (`smartfm.application.DispatchManager`).
3. **Shipment Tracking** — Operational milestone tracking (pickup, in-transit, delivery) and manual telemetry processing (`smartfm.application.ShipmentTracker`).
4. **Billing & Payment** — Balance verification, cash/card payment strategy processing, invoice settlement, and receipt generation (`smartfm.application.PaymentProcessor`).

---

## Architecture & Design Highlights

* **Layered Architecture & GRASP Controllers**: Strict separation between Swing Presentation Boundary (`smartfm.ui.gui`), Application Layer (`smartfm.application`), Domain Layer (`smartfm.domain`), and Persistence Infrastructure (`smartfm.infrastructure`).
* **Event-Driven Observer Pattern**: Cross-subsystem notification via narrow interface listeners (`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener`) to keep controllers loosely coupled.
* **Polymorphic State Pattern**: Programmatically enforces lifecycle rules for `OrderState`, `ShipmentState`, `InvoiceState`, and `PaymentState` hierarchies; illegal transitions throw `InvalidDataException`.
* **Strategy & Adapter Patterns**: Flexible billing via `IPaymentStrategy` (cash vs gateway) and third-party isolation via `SimulatedGatewayAdapter` and `ManualTelemetrySource`.
* **Transactional Relational Persistence**: Single gateway facade (`DataStore`) executing prepared SQL statements inside atomic SQLite JDBC transactions (`data/smartfm.db`).

---

## Repository Layout

```text
Assignment 3/
├── README.md                                # Root project documentation
├── AGENTS.md                                # AI coding agent guidelines & context
├── requirement.md                           # Assignment specification & marking criteria
├── grading.md                               # Evaluation rubric
├── asm3.typ                                 # Typst source document for assignment report
├── asm3.pdf                                 # Compiled report PDF
├── refs.bib                                 # Bibliography references
├── ieee.typ                                 # IEEE Typst template
├── images/                                  # Diagrams and figures for report
└── implementation/                          # Java 26 desktop application codebase
    ├── README.md                            # Application build and run instructions
    ├── Makefile                             # Cross-platform build script (Windows / Unix)
    ├── pom.xml                              # Maven descriptor (Java 26 release)
    ├── data/                                # Embedded SQLite database storage (smartfm.db)
    ├── lib/                                 # Pinned dependency JARs (SQLite JDBC, SLF4J)
    ├── src/main/java/smartfm/               # Production Java sources
    │   ├── common/                          # Shared utilities, Money formatter, Validators
    │   ├── domain/                          # 6 domain sub-packages (entities, states, strategies)
    │   ├── application/                     # 4 GRASP Controllers, Observer listeners, Bootstrap
    │   ├── infrastructure/                  # DataStore SQLite gateway
    │   └── ui/gui/                          # Swing desktop GUI panels & main frame
    ├── src/test/java/smartfm/              # JUnit 5 test suite (76 tests)
    ├── tools/java/                          # Automated ScreenshotDriver for visual evidence
    └── screenshots/                         # Captured UI evidence PNGs
```

---

## Quick Start & Workflows

### Prerequisites
* **Java 26 JDK** (e.g., OpenJDK 26, Zulu 26)
* **Maven 3.8+** or **GNU Make**
* **Typst** (for compiling report PDF)

### 1. Build & Test Java Application
All commands must be run with working directory set to `implementation/`:

```bash
# Run Checkstyle audit and all 76 JUnit 5 automated tests
mvn test

# Package self-contained executable JAR
mvn package

# Launch Swing GUI Application
make run
# OR
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar
```

### 2. Reset Demonstration Data
```bash
# Deletes data/smartfm.db and resets to clean seeded state
make reset
```

### 3. Generate Visual Screenshot Evidence
```bash
# Resets database, runs ScreenshotDriver, and outputs evidence PNGs
make screenshots
```

### 4. Compile Report Document
From the root directory:

```bash
# Compile Typst source to asm3.pdf
typst compile asm3.typ asm3.pdf
```

---

## Verification & Quality Assurance

* **Checkstyle Audit**: Clean with 0 violations (`checkstyle.xml` Google Java Style Guide).
* **Test Suite**: 76 automated JUnit 5 tests passing with 100% success rate across common, domain, application, infrastructure, and GUI EDT layers.
* **Persistence Integrity**: Atomic SQLite JDBC transactions verified through real-time auto-save and state reload tests.
