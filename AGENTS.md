# SmartFM - Agent Instructions & Project Context (`AGENTS.md`)

This file provides architectural context, repository layout, build instructions, coding standards, and operational guidelines for AI coding agents operating within this repository.

---

## 1. Project Overview & Context

- **Course**: SWE30003 — Software Architectures and Design (Swinburne University of Technology)
- **Project**: SmartFM (Smart Fleet Management System) - Assignment 3
- **Primary Stack**:
  - **Java 26** (Desktop Application)
  - **Swing GUI** (`smartfm.ui.gui.*`) and **Console CLI** (`smartfm.ui.SmartFmConsoleApp`)
  - **SQLite JDBC** (`3.46.1.0`) embedded persistence via single-file DB `data/smartfm.db`
  - **SLF4J API** (`1.7.36`) with no-op logging binding
  - **GNU Make** / **Maven** build systems
  - **Typst** (`asm3.typ`) for report & detailed design documentation generation

---

## 2. Directory Structure

```text
Assignment 3/
├── AGENTS.md                                # This guidance file
├── requirement.md                           # Assignment 3 specification & marking criteria
├── grading.md                               # Grading rubrics and evaluation rules
├── asm3.typ                                 # Typst source document for assignment report
├── asm3.pdf                                 # Compiled report PDF
├── refs.bib                                 # Bibliography references
├── ieee.typ                                 # Typst IEEE template
├── images/                                  # Diagrams and figures for report
└── implementation/                          # Java 26 desktop application
    ├── Makefile                             # Cross-platform build script (Windows / Unix)
    ├── pom.xml                              # Maven descriptor
    ├── data/                                # SQLite database storage (smartfm.db)
    ├── lib/                                 # Pinned dependency JARs (SQLite JDBC, SLF4J)
    ├── src/
    │   └── main/java/smartfm/
    │       ├── common/                      # Exceptions, validators, Money formatter
    │       ├── domain/                      # Domain sub-packages (customer, order, shipment, billing, fleet, catalog)
    │       ├── application/                 # 4 GRASP Controllers, Observer listeners, Bootstrap
    │       ├── infrastructure/              # DataStore: SQLite database gateway
    │       └── ui/                          # Launcher, CLI, and Swing GUI (`ui.gui`)
    ├── scenarios/                           # Scripted CLI inputs for end-to-end user flows
    ├── tools/java/                          # Automated ScreenshotDriver for visual evidence
    ├── transcripts/                         # Evidence of compilation and CLI execution
    └── screenshots/                         # Captured UI evidence screenshots
```

---

## 3. Architecture & Design Guidelines

SmartFM is designed according to GRASP, GoF design patterns, and strict layered architecture principles:

### Layered Separation
1. **UI Layer (`smartfm.ui`, `smartfm.ui.gui`)**:
   - Presents Swing views and CLI prompts.
   - Delegates all business requests directly to Application Controllers.
   - **Must not** perform direct SQL/database access or implement business rules.
2. **Application Layer (`smartfm.application`)**:
   - Implements four GRASP Application Controllers:
     - `OrderProcessor` (Order Management)
     - `DispatchManager` (Fleet Dispatch)
     - `ShipmentTracker` (Shipment Tracking)
     - `PaymentProcessor` (Billing and Payment)
   - Coordinates domain operations and fires events to Observer listeners.
3. **Domain Layer (`smartfm.domain`)**:
   - Entities, Value Objects (`Money`), State Machine patterns, and Strategy/Adapter interfaces.
   - Completely decoupled from UI frameworks and SQLite/JDBC.
4. **Infrastructure Layer (`smartfm.infrastructure`)**:
   - `DataStore`: Single gateway facade managing embedded SQLite connections and transactional normalized relational persistence.

### Core Architectural Rules & Patterns
- **Persistence**: Transactional normalized relational tables storing system state in `data/smartfm.db`.
- **Observer Pattern**: Application controllers notify listeners on domain events.
- **Strategy & Adapter Patterns**: Plugged into domain workflows for billing calculation, vehicle selection, and external adapter simulation.
- **Input Boundaries**: Always validate input using shared helpers in `smartfm.common` before touching application or domain state.

---

## 4. Build, Run, & Test Workflows

> **Note**: For Java operations, always execute commands with the working directory set to `Assignment 3/implementation`.

### Java Application Commands (`implementation/`)

| Action | Command | Notes |
| :--- | :--- | :--- |
| **Compile Project** | `make compile` | Compiles Java sources with `-Xlint:all` to `target/classes` |
| **Run Swing GUI** | `make run` | Launches the GUI desktop application |
| **Run CLI Application** | `make run-cli` | Launches `smartfm.ui.SmartFmConsoleApp` in CLI mode |
| **Build Executable JAR** | `make jar` | Generates `target/smartfm.jar` with `target/lib/` dependencies |
| **Compile Tools** | `make tools` | Compiles `ScreenshotDriver` tool |
| **Generate Screenshots** | `make screenshots` | Resets DB, runs `ScreenshotDriver` to generate evidence PNGs |
| **Clean Output** | `make clean` | Removes `target/` directory |
| **Reset State** | `make reset` | Cleans target output and removes `data/smartfm.db*` files |
| **Maven Test** | `mvn test` | Executes JUnit 5 test suite across domain, application, and infrastructure layers |
| **Maven Compile** | `mvn clean compile` | Alternative Maven compile command |
| **Maven Package** | `mvn clean package` | Maven shaded jar build |

### Typst Document Workflows (`Assignment 3/`)

| Action | Command | Notes |
| :--- | :--- | :--- |
| **Compile Report** | `typst compile asm3.typ asm3.pdf` | Generates assignment report PDF |
| **Watch & Auto-compile**| `typst watch asm3.typ asm3.pdf` | Re-compiles report automatically on save |

---

## 5. Guidelines for AI Agents

When modifying or analyzing code in this repository:

1. **Surgical Diffs & Root Cause Fixing**:
   - Fix issues at their root cause. Inspect all callers of a modified method across the codebase before applying changes.
   - Minimize file edits and avoid unnecessary refactoring or renames.
2. **Preserve Compatibility**:
   - Maintain compatibility between GUI (`smartfm.ui.gui`), CLI (`smartfm.ui`), and the underlying Application Controllers.
   - Do not change the normalized `DataStore` schema without updating its schema version and documentation when required.
3. **No Unrequested Dependencies**:
   - Do not add new third-party JARs or libraries. Rely strictly on Java 26 standard libraries and pinned JARs in `lib/`.
4. **Validation**:
   - Verify code changes by running `make compile` in `Assignment 3/implementation`.
   - Ensure input validation prevents invalid state transitions and gracefully presents errors in UI/CLI.
