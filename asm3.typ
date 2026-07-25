#import "ieee.typ": *
#import "@preview/wordometer:0.1.5": total-words, word-count
#import "@preview/mmdr:0.2.2": *

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

#outline(title: [Table of Contents])
#colbreak()

#heading(level: 1, numbering: none)[Introduction]

SmartFM is a fleet-logistics desktop application that our team designed in Assignment 2 and has now built as a working Java 26 system. It handles customer registration, order placement, dispatch, shipment tracking, billing, and payment. This report explains how we turned the high-level design into running code, what we changed along the way, and what we learned from the process.

The report follows the assignment structure: Section 1 summarises revisions to Assignment 2; Section 2 presents the detailed class design, sequence diagrams, and architecture; Section 3 reflects on design quality and lessons learned; and Section 4 provides code mappings, build instructions, execution evidence, and test results. The full Assignment 2 submission is attached in Appendix A.

We implemented four core business areas: Order Management, Fleet Dispatch, Shipment Tracking, and Billing & Payment. Both a Swing GUI and a command-line interface (CLI) share the same application controllers, so every feature works identically in both modes. The GUI is the primary interface; the CLI provides repeatable scenario scripts for verification and marking.

#heading(level: 1, numbering: none)[#text("1. Summary of Design Revision")]

Because no formal marker feedback was provided, Table 1 records revisions made during team code reviews and implementation.

#figure(
  styled-table((1.55fr, 2.25fr, 3.35fr, 2.0fr), (
    th[Review input / Assignment 2 basis], th[Finding during review], th[Revision made for Assignment 3], th[Effect and status],
    [A2 Assumption A1 deferred data access], [Conceptual model lacked persistence mechanism.], [Added `smartfm.infrastructure.DataStore` gateway using SQLite (`data/smartfm.db`).], [Domain layer remains persistence-agnostic.],
    [A2 excluded boundary/UI classes], [A working UI was required to process inputs.], [Added Swing GUI panels and CLI boundary classes that delegate to controllers.], [Presentation added without duplicating business rules.],
    [A2 subscribed `DispatchManager` to order approval], [Automatic assignment contradicted human dispatcher requirement.], [Retained event notification but required explicit `assignShipment(...)` call.], [Resolved ambiguity; resource assignment remains manual.],
    [A2 lifecycle state tables], [State rules required programmatic enforcement.], [Built concrete State classes for Order, Shipment, Invoice, and Payment.], [Illegal state transitions throw `InvalidDataException`.],
    [A2 adapter interfaces], [System needed testable concrete adapters.], [Added `ManualTelemetrySource` and `SimulatedGatewayAdapter`.], [External integrations remain replaceable.],
    [A2 narrative observer descriptions], [Callbacks risked concrete controller coupling.], [Defined narrow interfaces (`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener`).], [Maintained low coupling between application controllers.],
    [A2 wide conceptual scope], [Reporting was independent of the four core areas.], [Deferred `Report` class while completing the main operational flow.], [Scope kept focused on four required business areas.],
    [A2 Invoice-Payment 1-to-1 assumption], [Partial payments require multiple payments per invoice.], [Updated relationship to 1-to-Many with `InvoicePartiallyPaidState`.], [Supported partial cash/card payment scenarios.],
    [A2 ServiceOffering-Branch conceptual link], [Branch availability check was not enforced during order entry.], [Added `Branch.registerServiceOffering()`; origin branch check deferred.], [Documented as a minor scope boundary in Section 3.2.],
  )),
  caption: [Summary of design revisions from Assignment 2 to Assignment 3 based on implementation reviews.],
) <tbl-revision-summary>

#heading(level: 1, numbering: none)[#text("2. Detailed Design")]

#heading(level: 2, numbering: none)[2.1 Design approach and responsibility allocation]

The detailed design maintains the Entity-Control-Boundary structure established in Assignment 2. Domain entities store business data and enforce state rules. Application controllers coordinate user requests. UI boundaries handle input and display output, while infrastructure classes isolate database persistence. This structure follows key GRASP principles from Larman @larman2004uml, including Controller, Information Expert, Low Coupling, and Indirection.

#figure(
  styled-table((1.65fr, 2.35fr, 4.85fr), (
    th[Package / layer], th[Key classes], th[Responsibility],
    [`smartfm.ui`, `smartfm.ui.gui`], [`Launcher`, `SmartFmConsoleApp`, `SmartFmMainFrame`, five GUI panels], [Boundary layer. Collects and displays information only; it calls controller public operations and displays domain/controller validation messages.],
    [`smartfm.application`], [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`, `Bootstrap`], [Application layer. The four GRASP Controllers receive system events, coordinate entities, publish observer events, and invoke the persistence gateway.],
    [`smartfm.domain.*` (`customer`, `order`, `shipment`, `billing`, `fleet`, `catalog`)], [`Customer`, `Order`, `Consignment`, `Shipment`, `Vehicle`, `Driver`, `Invoice`, `Payment`, `Receipt`, state/strategy interfaces], [Domain layer. Divided into six domain sub-packages. Owns business information, lifecycle state, pricing/payment behaviour, and entity-level validation.],
    [`smartfm.infrastructure`], [`DataStore`], [Infrastructure layer. Opens the local SQLite database and uses a versioned normalized schema for branches, people and resources, catalogue, orders, shipments, invoices, payments, receipts, and association links. It reads and replaces the aggregate rows inside one SQLite transaction; it is the only persistence mechanism.],
    [`smartfm.common`], [`Validators`, `Money`, `InvalidDataException`], [Small shared utilities. Validation rules are reused by controllers/boundaries rather than copied between interfaces.],
  )),
  caption: [Layered package design and responsibility allocation.],
) <tbl-layered-design>



#figure(
  mermaid("
  classDiagram
      direction TB
  
      %% ============ Interfaces ============
      class IPricingStrategy {
          <<interface>>
          +calculateQuote(distanceKm, weightKg) double
      }
      class ITelemetrySource {
          <<interface>>
          +getLatestCoordinates(shipmentId) Coordinates
      }
      class IPaymentGateway {
          <<interface>>
          +charge(amount, method) TransactionResult
      }
  
      %% ============ Enumerations ============
      class OrderState {
          <<enumeration>>
          PENDING
          APPROVED
          CANCELLED
      }
      class ShipmentState {
          <<enumeration>>
          SCHEDULED
          IN_TRANSIT
          DELIVERED
      }
      class InvoiceState {
          <<enumeration>>
          UNPAID
          PARTIALLY_PAID
          SETTLED
      }
      class PaymentState {
          <<enumeration>>
          PENDING
          CONFIRMED
          FAILED
      }
      class DutyState {
          <<enumeration>>
          OFF_DUTY
          ON_DUTY
          ON_BREAK
      }
      class StaffRole {
          <<enumeration>>
          DISPATCHER
          DRIVER
          ADMIN
      }
  
      %% ============ Controllers ============
      class OrderProcessor {
          <<control>>
          -DataStore store
          +registerCustomer(details) Customer
          +submitOrder(order) Order
          +approveOrder(orderId) void
      }
      class DispatchManager {
          <<control>>
          -DataStore store
          +assignShipment(orderId) Shipment
          +onOrderApproved(order) void
      }
      class ShipmentTracker {
          <<control>>
          -DataStore store
          -ITelemetrySource telemetry
          +recordMilestone(shipmentId, location) void
          +recordDelivery(shipmentId) void
      }
      class PaymentProcessor {
          <<control>>
          -DataStore store
          -IPaymentGateway gateway
          +submitPayment(invoiceId, amount) Payment
      }
  
      %% ============ Infrastructure ============
      class DataStore {
          <<repository>>
          -Connection conn
          +load() void
          +save() void
          +customers() List~Customer~
          +orders() List~Order~
      }
      class GPSTelemetryAdapter {
          -Map~String,Coordinates~ locations
          +getLatestCoordinates(shipmentId) Coordinates
      }
      class PaymentGatewayAdapter {
          +charge(amount, method) TransactionResult
      }
  
      %% ============ People ============
      class Person {
          <<abstract>>
          #String id
          #String fullName
      }
      class Customer {
          -String phone
          +recordOrder(orderId) void
      }
      class StaffMember {
          <<abstract>>
          -StaffRole role
          +getRole() StaffRole
      }
      class Driver {
          -String licenseNo
          -DutyState dutyState
          +setDutyState(state) void
      }
  
      %% ============ Core Domain ============
      class Order {
          -String id
          -OrderState state
          -double quotedAmount
          +approve() void
          +cancel() void
          +addConsignment(c) void
      }
      class Consignment {
          -String id
          -double weightKg
          -String desc
          +getWeightKg() double
      }
      class ServiceOffering {
          -String id
          -String name
          +isAvailableAt(branchId) boolean
      }
      class Tariff {
          -double baseRate
          -double kmRate
          +calculateQuote(distanceKm, weightKg) double
      }
      class Branch {
          -String id
          -String name
          -String city
          +addVehicle(v) void
          +addDriver(d) void
      }
      class Vehicle {
          -String id
          -double capacityKg
          -String status
          +assignToShipment(s) void
      }
      class Shipment {
          -String id
          -ShipmentState state
          -String location
          +pickup() void
          +deliver() void
          +updateLocation(loc) void
      }
      class Invoice {
          -String id
          -double amount
          -InvoiceState state
          +recordPayment(p) void
          +isSettled() boolean
      }
      class Payment {
          -String id
          -double amount
          -PaymentState state
          +settle() void
      }
      class Receipt {
          -String id
          -DateTime issuedAt
          +getFormattedReceipt() String
      }
  
      %% ============ Generalization ============
      Person <|-- Customer
      Person <|-- StaffMember
      StaffMember <|-- Driver
  
      %% ============ Realization ============
      IPricingStrategy <|.. Tariff
      ITelemetrySource <|.. GPSTelemetryAdapter
      IPaymentGateway <|.. PaymentGatewayAdapter
  
      %% ============ Controller dependencies ============
      OrderProcessor ..> Customer
      OrderProcessor ..> Order
      OrderProcessor ..> Invoice
      OrderProcessor ..> DataStore
      DispatchManager ..> Branch
      DispatchManager ..> Shipment
      DispatchManager ..> DataStore
      ShipmentTracker ..> Shipment
      ShipmentTracker ..> DataStore
      ShipmentTracker --> ITelemetrySource
      PaymentProcessor ..> Payment
      PaymentProcessor ..> DataStore
      PaymentProcessor --> IPaymentGateway
      PaymentProcessor ..> Tariff
  
      %% ============ Domain associations ============
      Customer \"1\" --> \"1..*\" Order
      Order \"1\" *-- \"1..*\" Consignment
      Order \"1\" --> \"1\" ServiceOffering
      Order \"1\" --> \"0..1\" Shipment
      Order \"1\" --> \"1\" Invoice
      ServiceOffering \"1\" --> \"1\" Tariff

      Branch \"1\" o-- \"1..*\" Vehicle
      Branch \"1\" o-- \"1..*\" Driver
      Shipment \"1\" --> \"1\" Vehicle
      Shipment \"1\" --> \"1\" Driver

      Invoice \"1\" *-- \"1..*\" Payment
      Payment \"1\" *-- \"1\" Receipt
  
      %% ============ State usage ============
      Order ..> OrderState
      Shipment ..> ShipmentState
      Invoice ..> InvoiceState
      Payment ..> PaymentState
      Driver ..> DutyState
      StaffMember ..> StaffRole
  "),
  caption: [Final implementation class diagram. Each box names an implemented core class or a closely coupled State, Strategy, or Adapter family; solid lines show aggregate/domain relationships, dashed lines show polymorphic dependencies, and red dotted lines show controller use of the persistence boundary. `Report` and the authentication/session service are deliberately excluded because they are outside the selected four-area scope. Shared utility classes (`Money`, `Validators`, `IdGenerator`) and custom exceptions in `smartfm.common` are omitted from the diagram to prevent clutter, but act as ubiquitous helpers across all layers.],
) <fig-final-class-model>

#heading(level: 2, numbering: none)[2.2 GRASP Controller assignments]

In GRASP, a Controller handles incoming system events for a use-case session or operational domain @larman2004uml. SmartFM assigns one application controller to each of the four business areas. UI event handlers do not construct domain entities or mutate state directly. Instead, `Launcher` initializes a `Bootstrap` instance that wires controllers and event listeners. UI and CLI actions then delegate all requests to these controller operations.

#figure(
  styled-table((1.75fr, 2.25fr, 3.0fr, 1.95fr), (
    th[GRASP Controller], th[System events received], th[Delegation and collaboration], th[Why this is the Controller],
    [`OrderProcessor`], [Register customer; submit, approve, reject, or cancel order], [Coordinates `Customer`, `Consignment`, `Order`, and `Invoice`; fires order/invoice events.], [Represents the order-management use-case session; keeps UI free of domain rules.],
    [`DispatchManager`], [Assign approved order to vehicle and driver], [Checks resource availability and capacity, creates `Shipment`, and notifies tracking.], [Represents the dispatcher-facing dispatch use case; retains human decision.],
    [`ShipmentTracker`], [Record pickup, in-transit, delivery, and location events], [Delegates state transitions to `ShipmentState` and records telemetry milestones.], [Receives tracking events and delegates transition legality to the state object.],
    [`PaymentProcessor`], [Submit cash/card payment], [Validates balances, invokes payment strategy/adapter, settles invoices, and issues receipts.], [Represents payment processing; keeps gateway details out of domain models.],
  )),
  caption: [Explicit GRASP Controller allocation.],
) <tbl-grasp-controller>

#heading(level: 2, numbering: none)[2.3 Lifecycle, patterns, and dynamic constraints]

We used the State pattern to enforce lifecycle rules so that illegal transitions are caught at the point of request rather than discovered later in corrupted data. Orders move from Submitted to Approved, Rejected, or Cancelled. Shipments progress from Assigned through Picked Up and In Transit to Delivered. Invoices transition from Unpaid to Partially Paid or Paid, and Payments move from Pending through Verified to Settled or Failed. Any out-of-order transition throws an `InvalidDataException`; for example, a shipment cannot be marked Delivered without first being Picked Up. An early bug during development confirmed this guard was worth the additional State subclasses.

#figure(
  styled-table((1.7fr, 3.15fr, 4.1fr), (
    th[Pattern / GRASP principle], th[Concrete implementation], th[Reason and resulting constraint],
    [State], [`OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState` hierarchies], [Moves rules out of large conditional controllers. Each state accepts only its legal next operation.],
    [Observer], [Listener interfaces for order approval, invoice creation, and shipment assignment], [Coordinates operational areas without a publisher referring to a concrete subscriber class.],
    [Strategy], [`IPaymentStrategy` (cash vs gateway); `IPricingStrategy` / `PricingTariff`], [`PaymentProcessor` delegates cash and card processing through `IPaymentStrategy`. `IPricingStrategy` remains available for future pricing extensions (Section 3.2).],
    [Adapter / Protected Variations], [`SimulatedGatewayAdapter`, `ManualTelemetrySource`], [External systems are accessed through stable interfaces, allowing replacement with real integrations later.],
    [Creator / Information Expert], [Controllers create aggregates; entities/states own transition knowledge], [Construction occurs where inputs are available; invariant checks occur where knowledge resides.],
    [Indirection / Low Coupling], [`DataStore` and listener interfaces], [Controllers do not expose JDBC/SQL or concrete cross-controller dependencies to UI/domain layers.],
  )),
  caption: [Patterns and GRASP principles realised by the detailed design.],
) <tbl-pattern-grasp>

#heading(level: 3, numbering: none)[2.3.1 SQLite database design]

`DataStore` is the persistence gateway, fulfilling Assumption A1 from Assignment 2 while keeping domain models independent of database logic. It connects to the embedded SQLite database (`data/smartfm.db`) using the pinned Xerial JDBC driver. All database operations use prepared statements within explicit transactions.

When saving, `DataStore` atomically updates the normalized aggregate tables. When loading, it reconstructs domain objects, relationships, and state hierarchies in dependency order. The system enforces schema version 3 and rejects incompatible database versions, requiring a database reset if an older schema is detected.

#figure(
  styled-table((2.25fr, 3.4fr, 3.25fr), (
    th[SQLite table group], th[Representative columns / keys], th[Responsibility],
    [`schema_metadata`], [`id`, `schema_version`], [Stores current schema version (v3) to prevent incompatible loads.],
    [`branches`], [`id`, `name`, `city`, `contact_phone`], [Stores operational branch locations.],
    [`customers`, `staff_members`, `drivers`], [Person details, status/role, branch, licence and duty fields], [Stores customer records and staff/driver details.],
    [`vehicles`], [`id`, `branch_id`, capacities, `status`], [Stores fleet vehicle capacities and availability states.],
    [`service_offerings`, `pricing_tariffs`], [Service/tariff IDs, descriptions, rates and multipliers], [Stores service catalogue and pricing rate parameters.],
    [`branch_*`, `customers_orders`], [Branch/resource/catalogue and customer/order association keys], [Stores aggregate association links and collection ordering.],
    [`orders`, `consignments`, `order_consignments`], [Order IDs, route/date/quote/state; cargo fields; foreign keys], [Stores order attributes, routes, and cargo relationships.],
    [`shipments`], [`order_id`, `vehicle_id`, `driver_id`, `state_name`, location], [Stores dispatch assignments, state names, and current locations.],
    [`invoices`, `payments`, `invoice_payments`, `receipts`], [Billing IDs, amounts, dates, methods, states and foreign keys], [Stores billing balances, payment history, and receipt records.],
  )),
  caption: [Normalized SQLite schema owned exclusively by `DataStore`; all writes occur in one transaction and all foreign-key relationships are enabled.],
) <tbl-sqlite-schema>

#heading(level: 2, numbering: none)[2.4 Selected use-case sequence diagrams]

The four sequence diagrams below illustrate the core implemented use cases. Each diagram shows the exact controller methods invoked by the GUI and CLI boundaries. Section 4.1 maps these interactions directly to source code, and Section 4.3 provides execution evidence for each flow.

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant C as Customer / GUI or CLI
    participant OP as OrderProcessor<br/>«GRASP Controller»
    participant DOM as Customer, Consignment, Order
    participant DS as DataStore

    C->>OP: registerCustomer(details)
    OP->>DOM: create and validate Customer
    OP->>DS: stage customer in aggregate
    C->>OP: submitOrder(customer, consignments)
    OP->>DOM: create Consignment(s) and Order
    OP->>DS: stage order; return id
  "),
  caption: [UC-01 / UC-02: customer registration and order submission. The boundary sends each system event to `OrderProcessor`, which creates and validates domain objects and persists changes to SQLite through `DataStore`.],
) <fig-seq-order>

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant D as Dispatcher / GUI or CLI
    participant DM as DispatchManager<br/>«GRASP Controller»
    participant DOM as Order, Vehicle, Driver, Shipment
    participant ST as DataStore / ShipmentTracker

    D->>DM: assignShipment(orderId, vehicleId, driverId)
    DM->>DOM: verify approved / available / branch / capacity
    DM->>DOM: create Shipment; allocate resources
    DM->>ST: stage shipment and resource updates
    DM->>ST: publish shipmentAssigned(shipment)
  "),
  caption: [UC-03: dispatcher assigns a vehicle and driver to an approved order. `DispatchManager` checks the dispatch constraints, persists the shipment and resource updates to SQLite, and notifies `ShipmentTracker` via the listener interface.],
) <fig-seq-dispatch>

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant O as Operator / GUI or CLI
    participant ST as ShipmentTracker<br/>«GRASP Controller»
    participant TS as ManualTelemetrySource / ShipmentState
    participant DS as Shipment / DataStore

    O->>ST: record milestone(shipmentId, location)
    ST->>TS: obtain location through ITelemetrySource
    ST->>DS: request next lifecycle transition
    DS->>TS: ShipmentState accepts/rejects transition
    ST->>DS: stage accepted status and location
  "),
  caption: [UC-04: tracking a shipment milestone. The adapter normalises location input, while `ShipmentState` decides whether the requested transition is legal.],
) <fig-seq-tracking>

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant C as Customer / GUI or CLI
    participant PP as PaymentProcessor<br/>«GRASP Controller»
    participant PS as Invoice, Payment, PaymentStrategy
    participant GW as Gateway / Receipt / DataStore

    C->>PP: submitPayment(invoiceId, amount, method)
    PP->>PS: validate amount against outstanding balance
    PP->>PS: create Payment; select strategy
    PP->>GW: verify (gateway only for card)
    PP->>GW: settle, issue Receipt, stage aggregate
  "),
  caption: [UC-05: billing and payment. `PaymentProcessor` validates the amount before strategy/gateway processing; a receipt is issued only after settlement.],
) <fig-seq-payment>

#heading(level: 2, numbering: none)[2.5 Justification of changes and non-changes]

#heading(level: 3, numbering: none)[2.5.1 Class-level changes and non-changes]

All fourteen core domain classes from Assignment 2 (Customer, Order, Consignment, Shipment, Vehicle, Driver, Branch, ServiceOffering, PricingTariff, Invoice, Payment, Receipt, and the Person hierarchy) remain in the final implementation with the same responsibilities. The four State hierarchies and core interfaces (`IPaymentGateway`, `IPaymentStrategy`, `IPricingStrategy`, `ITelemetrySource`) were also preserved. The only additions are components that Assignment 2 explicitly deferred: `DataStore` for persistence, concrete adapters, `Bootstrap` for startup wiring, listener interfaces, and the UI boundary classes. Table 1 in Section 1 lists every revision; the paragraphs below explain the reasoning for the main changes.

The main class-level change was updating the relationship between `Invoice` and `Payment` from 1-to-1 to 1-to-Many. During implementation, we found that a customer paying a 500-dollar invoice with a 200-dollar cash deposit followed by a 300-dollar card payment was impossible under the 1-to-1 constraint. The new `InvoicePartiallyPaidState` tracks the remaining balance across multiple `Payment` objects, each of which remains immutable once settled.

Features outside the four operational areas, such as the `Report` class and authentication or role-based access (`StaffMember`, `StaffRole`, `SystemConfiguration`), remain in the domain model without UI bindings. We deferred these deliberately rather than deliver half-built features.

#heading(level: 3, numbering: none)[2.5.2 Responsibilities and collaborators]

The responsibility split from Assignment 2 (entities own business rules, controllers coordinate workflows, and boundaries handle I/O) carried over without change. The single new collaborator is `DataStore`, which controllers receive at construction time so domain entities stay persistence-agnostic.

The biggest responsibility-level refinement was replacing narrative observer callbacks with typed listener interfaces (`OrderApprovedListener`, `InvoiceCreatedListener`). In Assignment 2, we described these as "DispatchManager subscribes to order events," but during coding we found that this wording was ambiguous: did it mean automatic dispatch or just a notification? Defining narrow interfaces made the answer explicit: `OrderProcessor` fires an event, `DispatchManager.onOrderApproved` flags the order as dispatch-ready, and a human dispatcher must still call `assignShipment(...)` to allocate resources.

#heading(level: 3, numbering: none)[2.5.3 Dynamic aspects: bootstrap and interactions]

Assignment 2 did not specify how the system starts up or when data is saved; those decisions were made during implementation.

On first launch, `DataStore` creates `data/smartfm.db`, builds all tables in a single transaction, and seeds demonstration records (two branches, three vehicles, three drivers, and three service offerings). On later launches it detects the existing schema (version 3) and loads domain objects directly. `Bootstrap` then wires the four controllers and registers their event listeners in dependency-safe order. For example, `DispatchManager` is registered as an `OrderApprovedListener` on `OrderProcessor` before any orders can be approved.

We chose to persist after every state mutation rather than only on exit, because the CLI has no guaranteed shutdown hook. This means that if the process is killed mid-session, the database still reflects the last successful operation. The interaction order matters: order approval updates the order and creates the invoice _before_ notifying listeners, dispatch stages shipment and resource changes _before_ firing `shipmentAssigned`, and payments generate a receipt only _after_ settlement succeeds. These sequences match the diagrams in Section 2.4.

#heading(level: 2, numbering: none)[2.6 Architecture style(s)]

SmartFM uses two complementary architecture styles: a *Layered Architecture* for structural organisation and an *Event-Driven Architecture* for cross-subsystem communication. We chose this combination because a pure layered design would have forced `OrderProcessor` to call `DispatchManager` directly when an order is approved, creating tight coupling between two independent business areas. Adding event connectors at the application layer keeps the dispatch decision with the human operator while notifying the tracking subsystem automatically.

The system is organised into four architectural components:
1. *Presentation:* `SmartFmConsoleApp`, `SmartFmMainFrame`, and the Swing panel classes.
2. *Order and Billing:* `OrderProcessor`, `PaymentProcessor`, and their domain entities.
3. *Fleet and Dispatch:* `DispatchManager`, `ShipmentTracker`, and their domain entities.
4. *Persistence:* The `DataStore` database gateway.

These components communicate through two connector types. *Synchronous downward calls* follow the layer ordering: UI views call controller methods, controllers coordinate domain entities, and controllers invoke `DataStore`. *Event connectors* operate within the application layer: order approval, invoice creation, and shipment assignment publish events through narrow listener interfaces, so that no publisher needs to know which concrete class handles the event.

Three architectural constraints enforce these rules:
1. Domain classes never import presentation or application packages, as verified by the package structure.
2. `DataStore` is accessed exclusively through controllers; UI and domain classes never touch JDBC.
3. Event publishers depend only on listener interfaces, never on concrete subscriber classes.

#heading(level: 1, numbering: none)[#text("3. Design Quality")]

#heading(level: 2, numbering: none)[3.1 Good aspects of the Assignment 2 design]

The CRC cards from Assignment 2 mapped almost one-to-one to controller methods. For example, `OrderProcessor`'s three core responsibilities became `registerCustomer()`, `submitOrder()`, and `approveOrder()` with no extra logic bolted on; the CRC description was specific enough to code from directly. Defining lifecycle tables early was equally valuable: each table row became a concrete State subclass, and writing JUnit tests for invalid transitions was straightforward because the expected behaviour was already documented.

Design patterns chosen during Assignment 2 also proved useful in practice. The Adapter pattern allowed us to build `SimulatedGatewayAdapter` for development and swap it for a real payment gateway later without modifying `PaymentProcessor`. The Observer pattern kept controllers decoupled. When order approval needed to notify `PaymentProcessor` about a newly created invoice, we registered it as an `InvoiceCreatedListener` rather than adding a direct call inside `OrderProcessor`.

The four controllers maintain high cohesion: each one owns a single business area and delegates domain logic to the entities it coordinates. Coupling stays low because the UI depends on controller methods (not domain internals) and cross-controller communication flows through abstract listener interfaces.

#heading(level: 2, numbering: none)[3.2 Missing or ambiguous aspects]

Assignment 2 deliberately excluded UI and persistence details, which was appropriate for a high-level design but left notable gaps to fill during coding. We had to define input-validation rules (e.g. phone format, non-negative cargo weight), error-feedback flows for both GUI and CLI, the full SQLite schema, and the bootstrap/seeding sequence. These additions were substantial (DataStore alone is nearly 400 lines), but they did not contradict the original design. Instead, they extended it into areas that Assignment 2 had flagged as out of scope.

The main ambiguity was whether dispatch should be automatic or manual. Assignment 2 described `DispatchManager` as "subscribing to order approval events," which our team initially read as automatic assignment. During implementation, we realised this contradicted the SRS requirement for human dispatchers to choose vehicles and drivers. Resolving this took two team discussions before we settled on the current approach: the event notifies `DispatchManager` that an order is ready, but a dispatcher must still call `assignShipment(...)` explicitly.

Two minor design gaps remain in the implementation:

1. *Branch service validation:* `Branch.registerServiceOffering()` tracks which services a branch offers, but `OrderProcessor` does not filter orders by branch capability. Adding this would require branch-aware selection lists in the UI, a feature we scoped out for now.
2. *Pricing Strategy wiring:* `IPricingStrategy` and `PricingTariff` exist as designed, but `OrderProcessor` calls `PricingTariff.calculateQuote()` directly instead of going through `ServiceOffering`. The indirection layer is ready for future pricing models but is not exercised today.

#heading(level: 2, numbering: none)[3.3 Flaws or errors in the initial design]

The most consequential flaw was the dispatch ambiguity discussed in Section 3.2. Looking back, we should have drawn at least a basic dispatch screen wireframe during Assignment 2. A simple sketch showing a "Select Vehicle" dropdown and an "Assign" button would have made the manual-dispatch requirement obvious and saved two days of team debate during implementation.

The second flaw was omitting any persistence contract. Assignment 2's Assumption A1 acknowledged that "data access is deferred," but it said nothing about _when_ to save or _how_ to initialise. This forced us to design the entire `DataStore` transaction model from scratch, which worked out well but could have been guided by even a brief paragraph in the original design.

The third flaw was the 1-to-1 constraint between `Invoice` and `Payment`. We only discovered this was a problem when trying to implement a scenario where a customer pays in two instalments: cash first, then card. The fix (1-to-Many with `InvoicePartiallyPaidState`) was straightforward, but walking through realistic payment scenarios during design would have caught it earlier.

Finally, `ServiceOffering` was documented as delegating to `IPricingStrategy`, but the delegation was never specified in the CRC collaborators. During coding, we wired `PricingTariff` directly into `OrderProcessor` rather than routing through `ServiceOffering`, which means the strategy pattern is structurally present but not fully exercised.

#heading(level: 2, numbering: none)[3.4 Level of interpretation required]

Overall, the Assignment 2 design required moderate interpretation. The parts that were well specified (entity attributes, State transition tables, controller responsibilities, and pattern contracts) translated to code with minimal guesswork. The areas that needed the most interpretation were:

- *Persistence timing:* When should the system save? We chose "after every mutation" rather than "on exit only" because the CLI has no guaranteed shutdown hook (Section 2.5.3).
- *Input validation:* Assignment 2 defined what data each entity holds but not what constitutes valid input. We added regex-based phone and email validation, non-negative weight checks, and non-blank name enforcement in `smartfm.common.Validators`.
- *Adapter behaviour:* The interfaces were defined, but how a simulated gateway or manual telemetry source should behave was left to our judgement. We kept both adapters simple. `SimulatedGatewayAdapter` always approves and `ManualTelemetrySource` accepts free-text locations, making them easy to replace with real integrations.
- *Dispatch workflow:* As discussed in Sections 3.2 and 3.3, the original observer description was ambiguous about automation versus notification.

#heading(level: 2, numbering: none)[3.5 Lessons learnt]

Building SmartFM taught us several lessons that would change how we approach high-level OO design in the future.

*Specify state behaviour, not just state names.* The lifecycle tables in Assignment 2 were our most useful design artefact. Because each row already defined legal transitions, writing State subclasses was mechanical. We knew exactly which methods to allow and which to reject. By contrast, the observer descriptions were vague enough that we spent two days debating whether dispatch was automatic or manual. Next time, we would specify observer semantics with the same precision as state transitions: what triggers the event, what the listener is allowed to do, and what still requires human action.

*Walk through realistic scenarios during design.* The Invoice-Payment multiplicity flaw would have been caught immediately if we had traced a partial-payment scenario (for example, "200 cash now, 300 card later") through the CRC cards. In future designs, we would run at least one scenario per use case through the design model before calling it complete.

*Wire patterns end-to-end or document why not.* We defined `IPricingStrategy` and `PricingTariff` but never connected them through `ServiceOffering`. The pattern looks good on the class diagram, but in the running code, `OrderProcessor` calls `PricingTariff` directly. The lesson is that a pattern declared but not exercised adds complexity without value. Next time, we would either complete the wiring or explicitly mark the interface as a future extension point.

*Include persistence and UI sketches early.* Assignment 2 deferred both, which was acceptable for a high-level design but meant we had to make major architectural decisions (transaction boundaries, schema versioning, validation rules) during coding without design guidance. Even a one-paragraph persistence contract and a rough UI wireframe would have reduced interpretation effort considerably.

*Invest in test automation from day one.* Our JUnit suite (76 tests) and the automated `ScreenshotDriver` paid for themselves many times over. Every time we changed a State class or refactored `DataStore`, the tests caught regressions within seconds. Working with Java 26 also taught us a practical lesson: SQLite JDBC requires the flag `--enable-native-access=ALL-UNNAMED`. This requirement is easy to miss and would block execution without the provided Makefile.

#heading(level: 1, numbering: none)[#text("4. Implementation and Testing")]

#heading(level: 2, numbering: none)[4.1 Mapping design to code]

SmartFM is implemented in Java 26 using a standard Maven project layout. The design elements and sequence diagrams map directly to the source code.

*Coding standards and metrics:* The codebase adheres to the Google Java Style Guide @google2023javastyle. It uses standard naming conventions, explicit control blocks, and concise Javadoc comments. Source files compile with zero lint warnings under `javac -Xlint:all`. Code correctness is verified by 76 automated JUnit 5 tests across 17 test classes, covering domain states, event pipelines, SQLite persistence, and Swing GUI components. All tests pass with a 100% success rate.

*Development environment:* Development was conducted on Windows using PowerShell 7.6 and OpenJDK 26.0.2. The application requires Java 26 and the bundled library JARs in `implementation/lib/`. It runs locally without external database servers. Build options include Maven, GNU Make, or standard `javac`.

#figure(
  styled-table((2.0fr, 2.65fr, 3.8fr), (
    th[Design element / sequence diagram], th[Production code], th[Implementation match],
    [Presentation boundary], [`smartfm.ui.Launcher`, `SmartFmConsoleApp`, GUI panels], [GUI and CLI obtain `Bootstrap` on startup and invoke controller operations.],
    [UC-01/UC-02, @fig-seq-order], [`OrderProcessor`, `Customer`, `Consignment`, `Order`, `Invoice`], [`OrderProcessor` registers customers, calculates quotes, handles approval/cancellation, and generates invoices.],
    [UC-03, @fig-seq-dispatch], [`DispatchManager`, `Vehicle`, `Driver`, `Shipment`], [`DispatchManager` checks resource prerequisites, creates shipments, and fires assignment events.],
    [UC-04, @fig-seq-tracking], [`ShipmentTracker`, `ManualTelemetrySource`, `ShipmentState`], [`ShipmentTracker` delegates state updates to `ShipmentState` subclasses and records telemetry.],
    [UC-05, @fig-seq-payment], [`PaymentProcessor`, `IPaymentStrategy`, `SimulatedGatewayAdapter`], [`PaymentProcessor` validates balances, delegates cash/card strategies, invokes adapter, and generates receipts.],
    [Persistence / indirection], [`smartfm.infrastructure.DataStore`], [`DataStore` manages SQLite JDBC operations inside atomic transactions.],
    [Bootstrap / observer wiring], [`Bootstrap`, listener interfaces, `IdGenerator`], [Seeds initial database records and wires listener interfaces in dependency-safe order.],
  )),
  caption: [Traceability from detailed design and selected sequence diagrams to Java source.],
) <tbl-design-code-map>

*Task coverage.* The table below maps each SRS task (from Assignment 1) to its implementation status. Eight of fifteen tasks are fully implemented; the remaining seven are either partially supported or outside the selected four-area scope.

#figure(
  styled-table((2.0fr, 1.5fr, 4.5fr), (
    th[SRS Task], th[Status], th[Notes],
    [T1: Register Customer], [Full], [Implemented via `OrderProcessor.registerCustomer()` with field-level validation.],
    [T2: Browse Services], [Not implemented], [Service catalogue exists but no browse/search UI is provided.],
    [T3: Place Order], [Full], [Implemented via `OrderProcessor.submitOrder()` with consignment creation and quote calculation.],
    [T4: Process/Approve Order], [Full], [Dispatcher approve/reject with reason; `OrderState` pattern guards transitions.],
    [T5: Assign Resources], [Full], [Implemented via `DispatchManager.assignShipment()` with capacity and availability checks.],
    [T6: Track Shipment], [Full], [Implemented via `ShipmentTracker.confirmPickup/InTransit/Delivery()` with State pattern guards.],
    [T7: Record Milestones], [Full], [Covered by T6; manual location input through `ManualTelemetrySource` adapter.],
    [T8: Process Payment], [Full], [Implemented via `PaymentProcessor.submitPayment()` with cash/gateway strategies.],
    [T9: Generate Receipt], [Full], [Immutable `Receipt` created automatically upon payment settlement.],
    [T10: Manage Vehicles], [Not implemented], [Vehicle records are seeded during bootstrap but no CRUD UI is provided.],
    [T11: Manage Drivers], [Not implemented], [Driver records are seeded during bootstrap but no CRUD UI is provided.],
    [T12: Generate Reports], [Not implemented], [`Report` class is designed (Assignment 2) but explicitly deferred as out of scope.],
    [T13: Update Customer], [Not implemented], [Customer status can be changed programmatically but no update UI is provided.],
    [T14: Cancel/Modify Order], [Partial], [Cancellation is implemented; modification of submitted order fields is not supported.],
    [T15: Manage Config], [Not implemented], [`SystemConfiguration` is loaded at startup but no admin UI for changing values is provided.],
  )),
  caption: [SRS task coverage: eight tasks fully implemented, one partially supported, and six deferred or out of scope.],
) <tbl-task-coverage>

#figure(
  styled-table((2.7fr, 6.0fr), (
    th[Project path], th[Purpose],
    [`pom.xml`], [Maven descriptor: Java `26` release target, pinned dependencies, SLF4J, JUnit Jupiter, and executable shaded JAR.],
    [`src/main/java/smartfm/common/`], [Shared utility classes: money formatting, regex validators, and domain exceptions.],
    [`src/main/java/smartfm/domain/`], [Six domain sub-packages owning entities, lifecycle state hierarchies, and strategy/adapter contracts.],
    [`src/test/java/smartfm/`], [JUnit 5 unit, integration, and E2E test suite covering all layers.],
    [`src/main/java/smartfm/application/`], [Four GRASP Controllers, observer interfaces, bootstrap, and ID generation.],
    [`src/main/java/smartfm/infrastructure/`], [The `DataStore` SQLite persistence gateway.],
    [`src/main/java/smartfm/ui/`, `src/main/java/smartfm/ui/gui/`], [CLI and Swing presentation layers over application controllers.],
    [`scenarios/`], [Repeatable CLI input scripts for scenario testing.],
    [`tools/java/`], [GUI screenshot automation driver.],
  )),
  caption: [Standard project layout and package organisation.],
) <tbl-project-layout>

#heading(level: 2, numbering: none)[4.2 Compilation and Execution]

*Prerequisites:* Building and running the application requires JDK 26. SQLite is embedded, so no external database or network configuration is needed. All required library JARs are declared in `pom.xml` and stored in `implementation/lib/`. Running on Java 26 requires `--enable-native-access=ALL-UNNAMED` for SQLite JDBC native library loading. Execute commands from the `implementation/` directory using one of the methods below.

*Using Maven (recommended):*

#console(```
mvn test          # Runs all 76 automated JUnit 5 tests
mvn package       # Compiles and builds the self-contained executable JAR
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar --cli
```) 

*Using Makefile:*

#console(```
make compile      # Compiles Java sources with -Xlint:all
make run          # Launches GUI interface
make run-cli      # Launches CLI interface
make jar          # Builds target/smartfm.jar
```)



Data is stored locally in the embedded SQLite database `data/smartfm.db`. Delete this database and any `-wal`/`-shm` sidecar files (or run `make reset`) to return to the seeded state: two branches, three vehicles, three drivers, and three service offerings. No external database server, credentials, or network service is required.

#figure(
  console(raw(read("implementation/transcripts/00_compilation_evidence.txt"), lang: "text")),
  caption: [Compilation evidence from a clean Java 26 build: all 75 production source files compile with the pinned SQLite/JDBC classpath and exit code 0. Java 26 reports the existing serial/this-escape lint warnings but no compilation errors.],
) <fig-compilation>

#heading(level: 3, numbering: none)[GUI execution screenshots]

The screenshots below were generated by running `tools/java/smartfm/ui/gui/ScreenshotDriver.java`. The driver automates user actions and captures the application window directly. The full set of 26 screenshots is stored in `images/`. The selection below illustrates the core system features.

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/00_home_screen_empty.png", width: 100%),
    image("images/01b_customer_registration_validation_errors.png", width: 100%),
  ),
  caption: [GUI evidence: empty customer-registration home screen (left) and rejected invalid phone/email input with inline messages (right).],
) <fig-gui-empty-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/01c_customer_registration_success.png", width: 100%),
    image("images/02f_order_management_order_cancelled.png", width: 100%),
  ),
  caption: [GUI evidence: accepted customer input and successful account creation (left); a customer change of mind cancels an order without deleting unrelated data (right).],
) <fig-gui-input-change>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/03d_fleet_dispatch_shipment_created.png", width: 100%),
    image("images/04b_shipment_tracking_invalid_transition_rejected.png", width: 100%),
  ),
  caption: [GUI evidence: successful vehicle/driver assignment creates a shipment (left); an illegal delivery-before-pickup transition is rejected by the State pattern (right).],
) <fig-gui-dispatch-tracking-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/04e_shipment_tracking_delivered.png", width: 100%),
    image("images/05d_billing_payment_settled.png", width: 100%),
  ),
  caption: [GUI evidence: successful delivery transition (left); simulated payment completion, receipt issuance, and a paid invoice (right). No real banking transaction is performed.],
) <fig-gui-completion>

#figure(
  image("images/06_final_state_before_exit.png", width: 75%),
  caption: [Final application state immediately before normal exit. Closing the window invokes the registered handler, commits the normalized `DataStore` rows to SQLite, and exits; the recorded CLI scenarios independently verify that the database is restored in a later process.],
) <fig-gui-exit>

To regenerate all screenshots on a machine with JDK 26 and GNU Make, run `make screenshots` inside `implementation/`. The driver resets demonstration data, executes the test scenarios, saves the screenshots, and exits.

#heading(level: 2, numbering: none)[4.3 Testing]

System testing includes compiler linting, automated unit and integration tests, scenario-based acceptance testing, and persistence verification.

*Automated testing:* A suite of 76 JUnit 5 tests (`src/test/java/smartfm/`) runs via `mvn test`. The tests cover:
1. *Common Layer:* Currency formatting, timestamp rendering, and field validators (`MoneyTest`, `ValidatorsTest`).
2. *Domain Layer:* Entity invariants, cargo aggregation, state transitions, receipt issuance, and pricing tariffs across domain packages.
3. *Application Layer:* Event dispatch, shipment creation, resource allocation, and payment settlement across all four controllers.
4. *Infrastructure Layer:* Saving and reloading normalized aggregates in SQLite (`DataStoreTest`).
5. *Core E2E Workflows:* Full business flow execution from registration to payment settlement and database recovery (`SmartFmEndToEndTest`).
6. *Swing GUI E2E:* Interactive GUI testing on the Event Dispatch Thread covering validation errors, dispatch, and window closure (`SmartFmGuiEndToEndTest`).
7. *GUI Persistence:* Real-time SQLite auto-save verification upon UI state mutation (`GuiContextAndPersistenceTest`).
8. *Coverage Helpers:* CLI/GUI prompt parsing and edge-case component handlers (`SmartFmGuiCoverageTest`).

All 76 automated tests complete in under 5 seconds with zero failures.

*Scenario-Based Acceptance Testing:* The five scenarios below exercise the core use cases. Each scenario validates both correct and invalid inputs, state transitions, and persistence.

#figure(
  styled-table((1.1fr, 1.8fr, 2.7fr, 3.1fr), (
    th[Scenario], th[Use Case / Area], th[User Entry & Verification Path], th[Evidence & Outcome],
    [01 Customer], [Customer Registration (UC-01)], [Enter details. Invalid phone/email is rejected; valid input creates customer record.], [Customer `CUS-0001` created (@fig-gui-empty-validation, @fig-gui-input-change).],
    [02 Order], [Order Management (UC-02)], [Select customer/route. Negative cargo weight is rejected; submitted order can be cancelled or approved.], [Approval creates invoice `INV-0001` (@fig-gui-input-change).],
    [03 Dispatch], [Fleet Dispatch (UC-03)], [Select approved order and compatible vehicle/driver. Missing order selection is rejected.], [Shipment `SHP-0001` created (@fig-gui-dispatch-tracking-validation).],
    [04 Tracking], [Shipment Tracking (UC-04)], [Record milestones. Delivery before pickup is rejected by State pattern; sequential progress succeeds.], [Delivered state achieved (@fig-gui-completion).],
    [05 Payment], [Billing & Payment (UC-05)], [Select invoice and amount. Overpayment is rejected; partial cash deposit and card settlement succeed.], [Receipt issued, invoice Paid (@fig-gui-completion).],
  )),
  caption: [Scenario instructions, validation paths, and execution evidence.],
) <tbl-scenario-summary>



After running Scenario 05, `data/smartfm.db` contains committed database rows for two customers, three orders, one delivered shipment, one paid invoice, two settled payments, and two receipts. The table schema is set to version 3 with foreign keys enabled. Replaying CLI scenario transcripts verifies that application state persists correctly across separate process runs.

#heading(level: 1, numbering: none)[Conclusion]

SmartFM demonstrates that a well-structured Assignment 2 design can be turned into working software with relatively few structural surprises. The core entities, State patterns, and controller responsibilities survived implementation largely intact. The changes we made (adding persistence, replacing vague observer descriptions with typed listeners, and relaxing the Invoice-Payment multiplicity) were motivated by concrete problems found during coding rather than design trends.

The system compiles cleanly, passes 76 automated tests, and runs the four core business workflows end-to-end in both GUI and CLI modes. Deferred features such as report generation and service browsing can be added in future iterations without restructuring the layered architecture. If we were to start this project again, we would invest more time in persistence contracts, UI sketches, and scenario walkthroughs during the design phase. However, the overall approach of GRASP Controllers, lifecycle State classes, and event-driven subsystem communication proved to be a solid foundation.

#heading(level: 1, numbering: none)[References]

#bibliography("refs.bib", title: none, style: "harvard-cite-them-right")

#heading(level: 1, numbering: none)[Appendices]

#heading(level: 2, numbering: none)[Appendix A: Assignment 2 Object Design (Complete Submission)] <appendix-asm2>

The complete Assignment 2 Object Design submission is attached below so this report is self-contained. References such as “Assignment 2 lifecycle table” and “Assignment 2 Assumption A1” refer to this attached document.

#counter("appendix").update(1)
#colbreak()

#for page-num in range(1, 48) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm2.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}
