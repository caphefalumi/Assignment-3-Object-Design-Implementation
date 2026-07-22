#import "ieee.typ": *
#import "@preview/wordometer:0.1.5": total-words, word-count
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#show: word-count
#show: ieee.with(
  title: "SWE30003 Assignment 3\nObject Design Implementation and Reflection",
  sub_title: "Smart Fleet Management System",
  date_of_submission: "9th August 2026",
  header-left: "Assignment 3",
  header-right: "Swinburne University of Technology",
  bibliography-file: none,
  authors: (
    (name: "Dang Duy Toan", studentid: [105508402], email: "105508402@student.swin.edu.au", signature: image("images/toan_signature.png", width: 50%)),
    (name: "Phan Le Minh Hieu", studentid: [105543377], email: "105543377@student.swin.edu.au", signature: image("images/hieu_sign.jpg", width: 60%)),
    (name: "Vo Ngoc Nam", studentid: [105551859], email: "105551859@student.swin.edu.au", signature: image("images/Nam_signature.png", width: 70%)),
    (name: "Lam An Thinh", studentid: [105508512], email: "105508512@student.swin.edu.au", signature: image("images/thinh_signature.png", width: 30%)),
  ),
)

#set par(first-line-indent: (amount: 1.5em, all: true))
#show table: set text(size: 8.2pt)

#let header-fill = rgb("#1a3a5c")
#let alt-row-fill = rgb("#f0f4f8")
#let border-stroke = 0.5pt + rgb("#9db3c8")
#let th(content) = table.cell(fill: header-fill, text(fill: white, weight: "bold", content))
#let console(content) = block(
  width: 100%, fill: rgb("#0d1117"), radius: 4pt, inset: 8pt,
  stroke: border-stroke,
  align(left, text(fill: rgb("#c9d1d9"), font: "Consolas", size: 6.7pt, content)),
)
#let styled-table(columns, cells) = table(
  columns: columns,
  align: (left + top,)*columns.len(),
  inset: (x: 7pt, y: 6pt),
  stroke: border-stroke,
  fill: (_, y) => if y == 0 { header-fill } else if calc.odd(y) { white } else { alt-row-fill },
  ..cells,
)

// Small reusable diagram primitives. A solid arrow is a synchronous message;
// dashed vertical lines are lifelines rather than object dependencies.
#let box(pos, label, width: 2.35cm, height: .62cm, fill: rgb("#f0f4f8")) = node(
  pos,
  rect(width: width, height: height, radius: 3pt, fill: fill,
    stroke: .9pt + rgb("#1a3a5c"), inset: 2pt,
    align(center + horizon, text(size: 6.7pt, weight: "bold", fill: rgb("#1a3a5c"), label))),
  stroke: none, fill: none,
)
#let lifeline(x, end: 5) = edge((x, .32), (x, end), stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
#let sequence-order() = diagram(
  spacing: (2.35cm, .68cm),
  {
    box((0, 0), "Customer / GUI or CLI")
    box((1, 0), "OrderProcessor\n«GRASP Controller>")
    box((2, 0), "Customer, Consignment, Order")
    box((3, 0), "DataStore")
    lifeline(0); lifeline(1); lifeline(2); lifeline(3)
    edge((0, 1), (1, 1), "->", label: "1: registerCustomer(details)", label-pos: .5)
    edge((1, 1.55), (2, 1.55), "->", label: "2: create and validate Customer", label-pos: .5)
    edge((1, 2.1), (3, 2.1), "->", label: "3: save()", label-pos: .5)
    edge((0, 2.8), (1, 2.8), "->", label: "4: submitOrder(customer, consignments)", label-pos: .5)
    edge((1, 3.35), (2, 3.35), "->", label: "5: create Consignment(s) and Order", label-pos: .5)
    edge((1, 3.9), (3, 3.9), "->", label: "6: save(); return order id", label-pos: .5)
  }
)
#let sequence-dispatch() = diagram(
  spacing: (2.35cm, .68cm),
  {
    box((0, 0), "Dispatcher / GUI or CLI")
    box((1, 0), "DispatchManager\n«GRASP Controller>")
    box((2, 0), "Order, Vehicle, Driver, Shipment")
    box((3, 0), "DataStore / ShipmentTracker")
    lifeline(0); lifeline(1); lifeline(2); lifeline(3)
    edge((0, 1), (1, 1), "->", label: "1: assignShipment(orderId, vehicleId, driverId)", label-pos: .5)
    edge((1, 1.55), (2, 1.55), "->", label: "2: verify approved / available / same branch", label-pos: .5)
    edge((1, 2.1), (2, 2.1), "->", label: "3: create Shipment; allocate resources", label-pos: .5)
    edge((1, 2.65), (3, 2.65), "->", label: "4: save()", label-pos: .5)
    edge((1, 3.2), (3, 3.2), "->", label: "5: publish shipmentAssigned(shipment)", label-pos: .5)
  }
)
#let sequence-tracking() = diagram(
  spacing: (2.35cm, .68cm),
  {
    box((0, 0), "Operator / GUI or CLI")
    box((1, 0), "ShipmentTracker\n«GRASP Controller>")
    box((2, 0), "ManualTelemetrySource / ShipmentState")
    box((3, 0), "Shipment / DataStore")
    lifeline(0); lifeline(1); lifeline(2); lifeline(3)
    edge((0, 1), (1, 1), "->", label: "1: record milestone(shipmentId, location)", label-pos: .5)
    edge((1, 1.55), (2, 1.55), "->", label: "2: obtain location through ITelemetrySource", label-pos: .5)
    edge((1, 2.1), (3, 2.1), "->", label: "3: request next lifecycle transition", label-pos: .5)
    edge((3, 2.65), (2, 2.65), "->", label: "4: ShipmentState accepts/rejects transition", label-pos: .5)
    edge((1, 3.2), (3, 3.2), "->", label: "5: persist accepted status and location", label-pos: .5)
  }
)
#let sequence-payment() = diagram(
  spacing: (2.35cm, .68cm),
  {
    box((0, 0), "Customer / GUI or CLI")
    box((1, 0), "PaymentProcessor\n«GRASP Controller>")
    box((2, 0), "Invoice, Payment\nPaymentStrategy")
    box((3, 0), "Gateway / Receipt / DataStore")
    lifeline(0); lifeline(1); lifeline(2); lifeline(3)
    edge((0, 1), (1, 1), "->", label: "1: submitPayment(invoiceId, amount, method)", label-pos: .5)
    edge((1, 1.55), (2, 1.55), "->", label: "2: validate amount against outstanding balance", label-pos: .5)
    edge((1, 2.1), (2, 2.1), "->", label: "3: create Payment; select strategy", label-pos: .5)
    edge((1, 2.65), (3, 2.65), "->", label: "4: verify (gateway only for card)", label-pos: .5)
    edge((1, 3.2), (3, 3.2), "->", label: "5: settle, issue Receipt, save()", label-pos: .5)
  }
)

#outline(title: [Table of Contents])
#colbreak()

#heading(level: 1, numbering: none)[Introduction]

The Smart Fleet Management System (SmartFM) manages the commercial and operational path from customer registration and order placement through resource dispatch, shipment tracking, invoicing, payment, and receipt issue. Assignment 2 produced the high-level Entity-Control-Boundary design, CRC responsibilities, lifecycle states, and patterns. This Assignment 3 report converts that design into a detailed, running Java 17 system and evaluates the design decisions exposed by implementation.

The report deliberately follows the required assessment structure. Section 1 records revisions to Assignment 2; Section 2 provides the detailed design and the selected use-case sequence diagrams; Section 3 evaluates design quality; and Section 4 maps the design to code, gives reproducible compilation/execution instructions, and presents the tests and execution evidence. The complete Assignment 2 document is attached in the appendix so that every comparison can be checked.

The implemented scope comprises four connected business areas: Order Management, Fleet Dispatch, Shipment Tracking, and Billing and Payment. Both a Swing graphical interface and a repeatable command-line interface (CLI) invoke the same controller/domain logic. The GUI is the normal application entry point; the CLI is retained because it provides precise, reproducible scenario transcripts.

#heading(level: 1, numbering: none)[#text("1. Summary of Design Revision")]

No assessor or lecturer feedback document was supplied with the workspace. Therefore, the table below does *not* misrepresent internal observations as assessor feedback. It records the feedback received from self/team implementation review while converting Assignment 2 into Java, plus the corresponding revision. This is the evidence available for a truthful design-revision summary.

#figure(
  styled-table((1.55fr, 2.25fr, 3.35fr, 2.0fr), (
    th[Review input / Assignment 2 basis], th[Finding during review or implementation], th[Revision made for Assignment 3], th[Effect and status],
    [A2 Assumption A1 deferred the data access layer], [The conceptual model did not specify how state survives program restart.], [`smartfm.infrastructure.DataStore` was added as one persistence gateway using atomic file replacement and Java serialization. Controllers save durable aggregate state; entities do not manage storage.], [Required implementation detail added; the domain layer remains persistence-agnostic.],
    [A2 intentionally excluded boundary/UI classes], [A UI was mandatory for a usable application, but A2 did not define input sequencing or field-level errors.], [Added CLI boundary classes and Swing GUI panels. Both validate user data and delegate to the same controllers; no business rule is duplicated in the GUI.], [New presentation layer; stable domain/application responsibilities unchanged.],
    [A2 bootstrap subscribed `DispatchManager` to order approval], [Automatic allocation would contradict the business requirement that a dispatcher selects an appropriate vehicle and driver.], [The listener registration remains, but `assignShipment(orderId, vehicleId, driverId)` is an explicit human decision.], [Ambiguity resolved without introducing automatic resource assignment.],
    [A2 State-pattern lifecycle tables], [State transitions needed machine-enforced guards rather than only documentation.], [Concrete Order, Shipment, Invoice, and Payment state hierarchies reject illegal transitions with `InvalidDataException`.], [Lifecycle integrity is executable and tested.],
    [A2 Adapter interfaces only], [A running system needed concrete substitutes for GPS and card verification.], [Added `ManualTelemetrySource` and `SimulatedGatewayAdapter` behind the existing interfaces.], [External concerns remain replaceable and no real bank/GPS connection is required.],
    [A2 observer relations described narratively], [Narrative callbacks risk concrete controller coupling.], [Added narrow listener interfaces: `OrderApprovedListener`, `InvoiceCreatedListener`, and `ShipmentAssignedListener`.], [Publishers depend on listener abstractions, preserving low coupling.],
    [A2 covered a wider conceptual scope], [Reporting is independent of the four connected operational areas and could not be completed to the same standard within this iteration.], [`Report` remains designed but is explicitly deferred. Customer, order, dispatch, tracking, billing, and payment form a complete executable chain.], [Scope decision is visible; no stub is represented as implemented.],
  )),
  caption: [Truthful revision summary from Assignment 2 to Assignment 3. “Review input” identifies the available source of feedback; it is not attributed to an unavailable assessor.],
) <tbl-revision-summary>

#heading(level: 1, numbering: none)[#text("2. Detailed Design")]

#heading(level: 2, numbering: none)[2.1 Design approach and responsibility allocation]

The detailed design retains Assignment 2's Entity-Control-Boundary separation. Domain entities hold information and enforce local lifecycle/business invariants; application controllers coordinate system operations; UI boundary objects obtain input and show output; and infrastructure isolates durable storage. This applies GRASP Information Expert, Creator, Low Coupling, High Cohesion, Indirection, Protected Variations, and especially Controller as described by Larman @larman2004uml.

#figure(
  styled-table((1.65fr, 2.35fr, 4.85fr), (
    th[Package / layer], th[Key classes], th[Responsibility],
    [`smartfm.ui`, `smartfm.ui.gui`], [`Launcher`, `SmartFmConsoleApp`, `SmartFmMainFrame`, five GUI panels], [Boundary layer. Collects and displays information only; it calls controller public operations and displays domain/controller validation messages.],
    [`smartfm.application`], [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`, `Bootstrap`], [Application layer. The four GRASP Controllers receive system events, coordinate entities, publish observer events, and invoke the persistence gateway.],
    [`smartfm.domain`], [`Customer`, `Order`, `Consignment`, `Shipment`, `Vehicle`, `Driver`, `Invoice`, `Payment`, `Receipt`, state/strategy interfaces], [Domain layer. Owns business information, lifecycle state, pricing/payment behaviour, and validation that belongs to the object itself.],
    [`smartfm.infrastructure`], [`DataStore`], [Infrastructure layer. Loads and atomically stores the serialized snapshot. It is the only persistence mechanism.],
    [`smartfm.common`], [`Validators`, `Money`, `InvalidDataException`], [Small shared utilities. Validation rules are reused by controllers/boundaries rather than copied between interfaces.],
  )),
  caption: [Layered package design and responsibility allocation.],
) <tbl-layered-design>

#let class-model() = diagram(
  spacing: (2.25cm, 1.22cm),
  {
    box((0, 0), "OrderProcessor\n«Controller>", width: 2.6cm)
    box((1, 0), "DispatchManager\n«Controller>", width: 2.6cm)
    box((2, 0), "ShipmentTracker\n«Controller>", width: 2.6cm)
    box((3, 0), "PaymentProcessor\n«Controller>", width: 2.6cm)
    box((0, 1), "Customer\nOrder + Consignment")
    box((1, 1), "Vehicle + Driver\nShipment")
    box((2, 1), "ShipmentState\nITelemetrySource")
    box((3, 1), "Invoice + Payment\nReceipt")
    box((1.5, 2), "DataStore\n«repository / infrastructure>", width: 3.15cm, fill: rgb("#fff4db"))
    edge((0, 0), (0, 1), "->", stroke: .8pt + rgb("#1a3a5c"))
    edge((1, 0), (1, 1), "->", stroke: .8pt + rgb("#1a3a5c"))
    edge((2, 0), (2, 1), "->", stroke: .8pt + rgb("#1a3a5c"))
    edge((3, 0), (3, 1), "->", stroke: .8pt + rgb("#1a3a5c"))
    edge((0, 1), (1, 1), "->", stroke: .65pt + rgb("#1a3a5c"), dash: "dashed")
    edge((1, 1), (2, 1), "->", stroke: .65pt + rgb("#1a3a5c"), dash: "dashed")
    edge((0, 0), (1.5, 2), "->", stroke: .7pt + rgb("#c0392b"), dash: "dotted")
    edge((1, 0), (1.5, 2), "->", stroke: .7pt + rgb("#c0392b"), dash: "dotted")
    edge((2, 0), (1.5, 2), "->", stroke: .7pt + rgb("#c0392b"), dash: "dotted")
    edge((3, 0), (1.5, 2), "->", stroke: .7pt + rgb("#c0392b"), dash: "dotted")
  }
)
#figure(
  align(center, class-model()),
  caption: [Detailed class-level view: controller-to-domain calls are solid; the operational dependency chain is dashed; red dotted edges identify controller use of the persistence gateway added during implementation.],
) <fig-class-model>

#heading(level: 2, numbering: none)[2.2 GRASP Controller assignments]

A GRASP Controller should represent either the overall system, a use-case session, or a cohesive service that receives external system events @larman2004uml. SmartFM deliberately assigns one application controller to each coherent operational area, rather than allowing GUI event handlers to construct entities or alter state directly. `Launcher` creates a single `Bootstrap`; `Bootstrap` wires the controllers and observer listeners; and GUI/CLI actions call only their controller's public operations.

#figure(
  styled-table((1.75fr, 2.25fr, 3.0fr, 1.95fr), (
    th[GRASP Controller], th[System events received], th[Delegation and collaboration], th[Why this is the Controller],
    [`OrderProcessor`], [Register customer; submit, approve, reject, or cancel order], [Creates/coordinates `Customer`, `Consignment`, `Order`, and `Invoice`; publishes order-approved and invoice-created events; saves state.], [Represents the order-management use-case session and keeps UI free of order rules.],
    [`DispatchManager`], [Assign approved order to vehicle and driver], [Obtains order/resources, checks approval/availability/branch compatibility, creates `Shipment`, then publishes shipment-assigned.], [Represents the dispatcher-facing dispatch use case while retaining the human allocation decision.],
    [`ShipmentTracker`], [Record pickup, in-transit, delivery, and location events], [Uses telemetry abstraction and `ShipmentState` to validate each transition, then persists the accepted milestone.], [Receives tracking system events and delegates transition legality to the state object.],
    [`PaymentProcessor`], [Submit cash/card payment], [Checks the invoice balance, selects payment strategy, calls adapter when required, settles payment, creates receipt, and persists.], [Represents the payment use case and stops UI/payment gateway details entering the domain model.],
  )),
  caption: [Explicit GRASP Controller allocation.],
) <tbl-grasp-controller>

#heading(level: 2, numbering: none)[2.3 Lifecycle, patterns, and dynamic constraints]

The State pattern carries legal lifecycle transitions. An order progresses from Pending to Approved, Rejected, or Cancelled. A shipment progresses from Assigned to Picked Up, In Transit, and Delivered. An invoice moves from Open to Partially Paid or Paid, while a payment becomes Settled only after its strategy/gateway verification succeeds. Attempts to skip a lifecycle state throw `InvalidDataException` before persistence, so invalid data cannot be made durable.

#figure(
  styled-table((1.7fr, 3.15fr, 4.1fr), (
    th[Pattern / GRASP principle], th[Concrete implementation], th[Reason and resulting constraint],
    [State], [`OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState` hierarchies], [Moves rules out of large conditional controllers. Each state accepts only its legal next operation.],
    [Observer], [Listener interfaces for order approval, invoice creation, and shipment assignment], [Coordinates operational areas without a publisher referring to a concrete subscriber class.],
    [Strategy], [`IPaymentStrategy`; pricing strategy/tariff abstractions], [Allows cash and gateway/card processing variations without changing `PaymentProcessor` logic.],
    [Adapter / Protected Variations], [`SimulatedGatewayAdapter`, `ManualTelemetrySource`], [External systems are accessed through stable interfaces, allowing replacement with real integrations later.],
    [Creator / Information Expert], [Controllers create aggregates for their use cases; entities/states own their own data/transition knowledge], [Construction occurs where inputs and lifecycle context are available; invariant checks occur where knowledge resides.],
    [Indirection / Low Coupling], [`DataStore` and listener interfaces], [Controllers do not expose serialization or concrete cross-controller dependencies to the UI/domain layers.],
  )),
  caption: [Patterns and GRASP principles realised by the detailed design.],
) <tbl-pattern-grasp>

#heading(level: 2, numbering: none)[2.4 Selected use-case sequence diagrams]

The following four diagrams specify the selected implemented use cases. They are not merely illustrative: the controller operation named at each diagram entry is the operation invoked by both presentation layers, and the code mapping is given in Section 4.1. Together they specify all selected use cases used for the end-to-end execution evidence in Section 4.3.

#figure(
  align(center, sequence-order()),
  caption: [UC-01 / UC-02: customer registration and order submission. The boundary sends each system event to `OrderProcessor`; entity construction/validation and persistence occur behind that GRASP Controller.],
) <fig-seq-order>

#figure(
  align(center, sequence-dispatch()),
  caption: [UC-03: dispatcher assigns a vehicle and driver to an approved order. `DispatchManager` coordinates the decision and notifies `ShipmentTracker` after successful persistence.],
) <fig-seq-dispatch>

#figure(
  align(center, sequence-tracking()),
  caption: [UC-04: tracking a shipment milestone. The adapter normalises location input, while `ShipmentState` decides whether the requested transition is legal.],
) <fig-seq-tracking>

#figure(
  align(center, sequence-payment()),
  caption: [UC-05: billing and payment. `PaymentProcessor` validates the amount before strategy/gateway processing; a receipt is issued only after settlement.],
) <fig-seq-payment>

#heading(level: 1, numbering: none)[#text("3. Design Quality")]

#heading(level: 2, numbering: none)[3.1 Good aspects of the Assignment 2 design]

Assignment 2's CRC responsibilities translated well into code. The controller/entity boundary was clear enough that each selected business operation has one obvious application entry point. The lifecycle tables were particularly valuable: they turned into concrete State subclasses with minimal interpretation and made invalid tracking and payment behaviour testable rather than implicit. The early use of Strategy, Adapter, and Observer also protected volatile external concerns (payment verification, telemetry, cross-area notification) from the domain model.

The resulting design has high cohesion: order creation/approval stays in `OrderProcessor`, allocation in `DispatchManager`, tracking in `ShipmentTracker`, and settlement in `PaymentProcessor`. It also has low coupling because both GUI and CLI invoke the same controller contracts, and publishers hold listener interfaces rather than other controller implementations.

#heading(level: 2, numbering: none)[3.2 Missing or ambiguous aspects]

The original design deliberately left UI and persistence outside its high-level class model. That was reasonable for Assignment 2 but left input flow, inline error handling, durable storage, atomic-write behaviour, and recovery from a fresh versus populated store to the implementation phase. Concrete behaviour for the gateway and telemetry interfaces was similarly unspecified. These omissions are addressed as explicit infrastructure and boundary additions in Section 1.

The main ambiguity was the phrase that `DispatchManager` “reacts” to an approved order. Automatic dispatch conflicts with the operational requirement that a human dispatcher selects the vehicle and driver. The revision preserves event awareness but makes allocation an explicit operation. This resolves the ambiguity while retaining the intended Observer decoupling.

#heading(level: 2, numbering: none)[3.3 Architecture quality and lessons learnt]

The implemented architecture is layered with an event-driven application/control layer. Downward method-call dependencies run from presentation to application to domain/infrastructure; observer messages coordinate controllers at the application layer. Domain classes never import GUI or application classes, and they do not hold `DataStore` references. This structure makes the Swing UI, CLI, adapter implementations, and persistence mechanism replaceable without rewriting business rules.

The most important lesson is that state machines and human/automatic decisions must be specified before coding. State diagrams/lifecycle tables avoided later rework; in contrast, the dispatch ambiguity required interpretation. A future iteration should define a persistence interface and UI interaction sketch during high-level design, even if the concrete database/UI toolkit remains undecided. It should also label each observer relationship as either “notify a human decision-maker” or “automate a reaction”.

#heading(level: 1, numbering: none)[#text("4. Implementation and Testing")]

#heading(level: 2, numbering: none)[4.1 Mapping design to code]

SmartFM is implemented in Java 17 in a Maven-standard structure. The following mapping demonstrates that the classes and calls in the selected sequence diagrams match code rather than a separate conceptual design.

#figure(
  styled-table((2.0fr, 2.65fr, 3.8fr), (
    th[Design element / sequence diagram], th[Production code], th[Implementation match],
    [Presentation boundary], [`smartfm.ui.Launcher`, `SmartFmConsoleApp`; `smartfm.ui.gui.SmartFmMainFrame` and panels], [GUI is the default entry point; `--cli` selects the transcript-friendly UI. Both obtain one `Bootstrap` through `GuiContext`/startup and call controller methods.],
    [UC-01/UC-02, @fig-seq-order], [`OrderProcessor`, `Customer`, `Consignment`, `Order`, `Invoice`], [`OrderProcessor` registers the customer, creates/validates consignments and orders, approves/rejects/cancels orders, and produces an invoice on approval.],
    [UC-03, @fig-seq-dispatch], [`DispatchManager`, `Vehicle`, `Driver`, `Shipment`, `ShipmentAssignedListener`], [Dispatch verifies prerequisites, allocates real seeded resources, creates a shipment, persists it, and sends the observer event.],
    [UC-04, @fig-seq-tracking], [`ShipmentTracker`, `ManualTelemetrySource`, `ShipmentState` subclasses], [Tracking events use the adapter interface and state hierarchy; invalid state transitions are rejected.],
    [UC-05, @fig-seq-payment], [`PaymentProcessor`, `IPaymentStrategy`, `SimulatedGatewayAdapter`, `Payment`, `Receipt`], [Payment amount is checked against the invoice before settlement; card verification is behind an adapter and receipt creation follows success.],
    [Persistence / indirection], [`smartfm.infrastructure.DataStore`], [All controllers use the single persistence gateway. It writes `data/smartfm-store.dat`; domain classes remain storage-independent.],
    [Bootstrap / observer wiring], [`Bootstrap`, listener interfaces, `IdGenerator`], [Creates seeded reference data for a new store, constructs controllers on every launch, and registers listeners in dependency-safe order.],
  )),
  caption: [Traceability from detailed design and selected sequence diagrams to Java source.],
) <tbl-design-code-map>

#figure(
  styled-table((2.7fr, 6.0fr), (
    th[Project path], th[Purpose],
    [`pom.xml`], [Maven descriptor: Java 17, JUnit Jupiter 5.10.2 test-scope dependency, and executable JAR main class `smartfm.ui.Launcher`.],
    [`src/main/java/smartfm/common/`], [Exceptions, validators, and money formatting.],
    [`src/main/java/smartfm/domain/`], [Entities, state hierarchies, and strategy/adapter contracts.],
    [`src/main/java/smartfm/application/`], [Four GRASP Controllers, observer interfaces, bootstrap, and ID generation.],
    [`src/main/java/smartfm/infrastructure/`], [The `DataStore` persistence gateway.],
    [`src/main/java/smartfm/ui/`, `src/main/java/smartfm/ui/gui/`], [CLI and Swing presentations over the same controller contracts.],
    [`scenarios/`, `transcripts/`], [Repeatable CLI input scripts and captured execution output used in Section 4.3.],
    [`tools/java/`], [Development-only GUI screenshot driver; not packaged with the application.],
  )),
  caption: [Industry-standard project layout and source-code organisation.],
) <tbl-project-layout>

#heading(level: 2, numbering: none)[4.2 Compilation and Execution]

*Prerequisites.* A classmate needs a Java Development Kit (JDK) 17 or later. Maven is recommended but not required. The application itself has no runtime library beyond the Java standard library. In a terminal opened at `implementation/`, use one of the following reproducible paths.

*Using Maven (recommended):*

#console(```
mvn package
java -jar target/smartfm.jar
java -jar target/smartfm.jar --cli
```) 

The first command compiles production code, runs Maven tests when present, and creates `target/smartfm.jar`. The second launches the graphical interface; the third launches the CLI.

*Using the supplied Makefile:* a GNU Make implementation and JDK 17+ must be available. On Windows, GNU Make can be provided by MSYS2, Git Bash, or WSL. Run:

#console(```
make compile
make run          # graphical interface
make run-cli      # textual interface
make jar
```) 

*Plain `javac` fallback (PowerShell):*

#console(```
Get-ChildItem -Recurse -Filter *.java src/main/java |
  ForEach-Object { '"' + ($_.FullName -replace '\\','/') + '"' } |
  Set-Content -Encoding UTF8 sources.txt
javac -d target/classes -encoding UTF-8 -Xlint:all "@sources.txt"
java -cp target/classes smartfm.ui.Launcher
java -cp target/classes smartfm.ui.Launcher --cli
```) 

Data is stored locally in `data/smartfm-store.dat`. Delete this file (or run `make reset`) to return to the seeded state: two branches, three vehicles, three drivers, and three service offerings. No database, network service, credentials, or installation beyond the JDK is required.

#figure(
  console(raw(read("implementation/transcripts/00_compilation_evidence.txt"), lang: "text")),
  caption: [Compilation evidence from a clean plain-JDK build: all 74 Java source files compile with `-Xlint:all`, zero errors/warnings, exit code 0.],
) <fig-compilation>

#heading(level: 3, numbering: none)[GUI and screenshot evidence]

The GUI opens by default and has Customer Registration, Order Management, Fleet Dispatch, Shipment Tracking, and Billing/Payment tabs. Each panel calls the same controllers identified in @tbl-grasp-controller; no workflow has a GUI-only business-rule implementation. The application was manually smoke-tested by launching `smartfm.ui.Launcher` on the development machine and confirming that all five tabs render.

A development-only `ScreenshotDriver` can capture the application window after real GUI interactions:

#console(```
make screenshots
```) 

Automated captures from the development machine are intentionally not embedded in this report because they occasionally contained unrelated desktop/browser content. The images were deleted rather than risk submitting private or irrelevant material. This report therefore does not falsely label a diagram as a screenshot. The reproducible CLI transcripts below are the primary runtime evidence; a marker may safely generate and inspect local GUI-only images using the supplied tool before relying on them. This limitation is disclosed because evidence integrity is more important than an unverified image.

#heading(level: 2, numbering: none)[4.3 Testing]

Testing combines compilation with warning checks, scenario-based functional tests, boundary/negative-path tests, and persistence checks. The five scenarios below exercise every selected use case shown in the sequence diagrams. They are replayable by running the files in `scenarios/` in numerical order after resetting the persistent store. Each transcript is captured from a separate CLI process, proving that persisted data is reread between operations.

#figure(
  styled-table((1.05fr, 2.25fr, 3.35fr, 2.1fr), (
    th[Scenario], th[Business area / selected use case], th[Positive and negative behaviour verified], th[Evidence],
    [01], [Customer registration (UC-01)], [Invalid phone/email input is rejected; two valid customers are created.], [`transcripts/01_register_customers.txt`],
    [02], [Order management (UC-02)], [Negative consignment weight is rejected; orders are placed; cancellation, rejection with reason, and approval/invoice creation succeed.], [`02a`, `02a2`, `02b`, `02c` transcripts],
    [03], [Fleet dispatch (UC-03)], [Non-existent vehicle ID is rejected without side effect; valid vehicle/driver assignment creates `SHP-0001` and sends shipment-assigned notification.], [`transcripts/03_dispatch.txt`],
    [04], [Shipment tracking (UC-04)], [Delivery directly from Assigned is rejected; valid Picked Up -> In Transit -> Delivered transitions succeed with location/status output.], [`04a`, `04b` transcripts],
    [05], [Billing/payment (UC-05)], [Overpayment is rejected; partial cash payment creates a receipt and partial invoice status; final card payment settles the invoice and creates a second receipt.], [`transcripts/05_billing.txt`],
  )),
  caption: [Scenario-based testing coverage across all selected use cases.],
) <tbl-testing-summary>

#figure(
  console(raw(read("implementation/transcripts/01_register_customers.txt"), lang: "text")),
  caption: [Scenario 01: customer registration validates bad phone/email input before creating customers.],
) <fig-test-registration>

#figure(
  console(raw(read("implementation/transcripts/02c_manage_orders.txt"), lang: "text")),
  caption: [Scenario 02 completion: approval generates `INV-0001` and triggers the designed observer notifications. Earlier scenario transcript parts capture invalid weight, cancellation, and rejection.],
) <fig-test-order>

#figure(
  console(raw(read("implementation/transcripts/03_dispatch.txt"), lang: "text")),
  caption: [Scenario 03: invalid resource selection is rejected, then an approved order is assigned valid vehicle/driver resources and becomes a shipment.],
) <fig-test-dispatch>

#figure(
  console(raw(read("implementation/transcripts/04b_delivery.txt"), lang: "text")),
  caption: [Scenario 04 completion: a shipment progresses to Delivered after the prior transcript verifies the invalid out-of-order transition.],
) <fig-test-tracking>

#figure(
  console(raw(read("implementation/transcripts/05_billing.txt"), lang: "text")),
  caption: [Scenario 05: overpayment is rejected, then partial and final payments demonstrate invoice state changes and receipt issuance.],
) <fig-test-payment>

After Scenario 05, `data/smartfm-store.dat` contains the persisted snapshot of two customers, three orders (approved/dispatched, cancelled, rejected), one delivered shipment, one paid invoice, two settled payments, and two receipts. The independent-process transcript sequence and the saved snapshot provide a practical persistence regression check in addition to individual business-rule checks.

#heading(level: 1, numbering: none)[Conclusion]

SmartFM turns the Assignment 2 responsibility-driven design into a working Java 17 application with two interchangeable interfaces, durable file-based storage, four connected operational areas, and explicit GRASP Controllers. The revised design preserves the strongest Assignment 2 decisions—cohesive controller allocation, lifecycle State objects, and decoupled observer/adapter interfaces—while making UI, persistence, and human allocation decisions explicit.

The supplied compilation evidence and five scenario transcripts demonstrate the selected use cases from customer registration through payment and receipt issuance, including deliberately invalid inputs and lifecycle transitions. The report's design-to-code table and sequence diagrams provide traceability from UI system events to controller coordination, domain behaviour, and persistence. The remaining `Report` capability is clearly deferred rather than presented as complete; a future iteration can add it through the established layered/controller design without compromising the implemented business chain.

#heading(level: 1, numbering: none)[References]

#bibliography("refs.bib", title: none, style: "harvard-cite-them-right")

#heading(level: 1, numbering: none)[Appendices]

#heading(level: 2, numbering: none)[Appendix A: Assignment 2 Object Design (Complete Submission)] <appendix-asm2>

The complete Assignment 2 Object Design submission is attached below so this report is self-contained. References such as “Assignment 2 lifecycle table” and “Assignment 2 Assumption A1” refer to this attached document.

#counter("appendix").update(1)
#colbreak()

#for page-num in range(1, 66) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm2.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}
