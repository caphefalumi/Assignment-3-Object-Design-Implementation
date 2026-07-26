#import "ieee.typ": *
#import "@preview/mmdr:0.2.2": *

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

#outline(title: [Table of Contents])
#colbreak()

= Introduction

SmartFM is a fleet-logistics desktop application that our team designed in Assignment 2 and has now built as a working Java 26 system. It handles customer registration, order placement, dispatch, shipment tracking, billing, and payment. This report covers how we turned the high-level design into running code, what changed along the way, and what we learned.

The report follows the assignment structure: Section 1 lists revisions to Assignment 2; Section 2 presents the detailed class design, sequence diagrams, and architecture; Section 3 reflects on design quality and lessons learned; Section 4 provides code mappings, build instructions, execution evidence, and test results. The full Assignment 2 submission is attached in Appendix A.

We implemented four business areas: Order Management, Fleet Dispatch, Shipment Tracking, and Billing & Payment. A Swing GUI (`smartfm.ui.gui`) provides operational forms that delegate all requests to the application controllers. The UI does not contain business rules; it only collects input and displays results.

= Summary of Design Revision

Because no formal marker feedback was provided, Table 1 records revisions made during team code reviews and implementation.

#figure(
  styled-table((1.55fr, 2.25fr, 3.35fr, 2.0fr), (
    th[Review input / Assignment 2 basis], th[Finding during review], th[Revision made for Assignment 3], th[Effect and status],
    [A2 Assumption A1 deferred data access], [Conceptual model lacked persistence mechanism.], [Added `smartfm.infrastructure.DataStore` gateway using SQLite (`data/smartfm.db`).], [Domain layer remains persistence-agnostic.],
    [A2 excluded boundary/UI classes], [A working UI was required to process inputs.], [Added Swing GUI panels (`smartfm.ui.gui`) that delegate directly to application controllers.], [Presentation added without duplicating business rules.],
    [A2 subscribed `DispatchManager` to order approval], [Automatic assignment contradicted human dispatcher requirement.], [Retained event notification but required explicit `assignShipment(...)` call.], [Resolved ambiguity; resource assignment remains manual.],
    [A2 lifecycle state tables], [State rules required programmatic enforcement.], [Built concrete State classes for Order, Shipment, Invoice, and Payment.], [Illegal state transitions throw `InvalidDataException`.],
    [A2 adapter interfaces], [System needed testable concrete adapters.], [Added `ManualTelemetrySource` and `SimulatedGatewayAdapter`.], [External integrations remain replaceable.],
    [A2 narrative observer descriptions], [Callbacks risked concrete controller coupling.], [Defined narrow interfaces (`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener`).], [Maintained low coupling between application controllers.],
    [A2 wide conceptual scope], [Reporting was independent of the four core areas.], [Added `Report` entity, `ReportProcessor` controller, and `ReportPanel` UI tab for administrative reporting.], [Implemented Task T12 with zero changes to existing transactional layers.],
    [A2 Invoice-Payment 1-to-1 assumption], [Partial payments require multiple payments per invoice.], [Updated relationship to 1-to-Many with `InvoicePartiallyPaidState`.], [Supported partial cash/card payment scenarios.],
    [A2 ServiceOffering-Branch conceptual link], [Branch availability check was not enforced during order entry.], [Added `Branch.registerServiceOffering()`; origin branch check deferred.], [Documented as a minor scope boundary in Section 3.2.],
  )),
  caption: [Summary of design revisions from Assignment 2 to Assignment 3 based on implementation reviews.],
) <tbl-revision-summary>

= Detailed Design

== Design approach and responsibility allocation

The detailed design keeps the Entity-Control-Boundary structure from Assignment 2. Domain entities store business data and enforce state rules. Application controllers coordinate user requests. UI boundaries handle input and display output, and infrastructure classes isolate database persistence. This follows several GRASP principles (Controller, Information Expert, Low Coupling, Indirection) as described by Larman @larman2004uml.

#colbreak()
#figure(
  styled-table((1.65fr, 2.35fr, 4.85fr), (
    th[Package / layer], th[Key classes], th[Responsibility],
    [`smartfm.ui`, `smartfm.ui.gui`], [`Launcher`, `SmartFmMainFrame`, five GUI panels], [Boundary layer. Collects and displays information only; it calls controller public operations and displays domain/controller validation messages.],
    [`smartfm.application`], [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`, `Bootstrap`], [Application layer. The four GRASP Controllers receive system events, coordinate entities, publish observer events, and invoke the persistence gateway.],
    [`smartfm.domain.*` (`customer`, `order`, `shipment`, `billing`, `fleet`, `catalog`)], [`Customer`, `Order`, `Consignment`, `Shipment`, `Vehicle`, `Driver`, `Invoice`, `Payment`, `Receipt`, state/strategy interfaces], [Domain layer. Divided into six domain sub-packages. Owns business information, lifecycle state, pricing/payment behaviour, and entity-level validation.],
    [`smartfm.infrastructure`], [`DataStore`], [Infrastructure layer. Opens the local SQLite database and uses a versioned normalized schema for branches, people and resources, catalogue, orders, shipments, invoices, payments, receipts, and association links. It reads and replaces the aggregate rows inside one SQLite transaction; it is the only persistence mechanism.],
    [`smartfm.common`], [`Validators`, `Money`, `InvalidDataException`, `InvalidCredentialsException`], [Small shared utilities. Validation rules are reused by controllers/boundaries rather than copied between interfaces.],
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
          +calculateQuote(distanceKm, totalWeightKg, isPeakPeriod) double
      }
      class IPaymentStrategy {
          <<interface>>
          +process(paymentId, amount) boolean
          +getMethod() PaymentMethod
      }
      class ITelemetrySource {
          <<interface>>
          +stageLocation(shipmentId, rawLocation) void
          +readLocation(shipmentId) String
      }
      class IPaymentGateway {
          <<interface>>
          +verifyTransaction(paymentId, amount) boolean
      }
  
      %% ============ State hierarchies (State pattern) ============
      class OrderState {
          <<abstract>>
          +approve(order) void
          +reject(order, reason) void
          +cancel(order) void
          +name() String
      }
      class OrderSubmittedState { +name() = Submitted }
      class OrderApprovedState { +name() = Approved }
      class OrderRejectedState { +name() = Rejected }
      class OrderCancelledState { +name() = Cancelled }
  
      class ShipmentState {
          <<abstract>>
          +pickUp(shipment) void
          +transit(shipment) void
          +deliver(shipment) void
          +name() String
      }
      class ShipmentAssignedState { +name() = Assigned }
      class ShipmentPickedUpState { +name() = Picked Up }
      class ShipmentInTransitState { +name() = In Transit }
      class ShipmentDeliveredState { +name() = Delivered }
  
      class InvoiceState {
          <<abstract>>
          +applyPayment(invoice, amount) void
          +name() String
      }
      class InvoiceUnpaidState { +name() = Unpaid }
      class InvoicePartiallyPaidState { +name() = Partially Paid }
      class InvoicePaidState { +name() = Paid }
  
      class PaymentState {
          <<abstract>>
          +verify(payment) void
          +fail(payment, reason) void
          +settle(payment) void
          +name() String
      }
      class PaymentPendingState { +name() = Pending }
      class PaymentVerifiedState { +name() = Verified }
      class PaymentSettledState { +name() = Settled }
      class PaymentFailedState { +name() = Failed }
  
      %% ============ Enumerations ============
      class DutyState {
          <<enumeration>>
          OFF_DUTY
          AVAILABLE
          DISPATCHED
          ON_BREAK
      }
      class VehicleStatus {
          <<enumeration>>
          AVAILABLE
          DISPATCHED
          MAINTENANCE
          INACTIVE
      }
      class StaffRole {
          <<enumeration>>
          DISPATCHER
          BRANCH_MANAGER
          FLEET_ADMINISTRATOR
          HR_STAFF
          SYSTEM_ADMINISTRATOR
          DRIVER
      }
      class PaymentMethod {
          <<enumeration>>
          CASH
          CARD
          DIGITAL_WALLET
      }
  
      %% ============ Controllers ============
      class OrderProcessor {
          <<control>>
          -DataStore store
          +registerCustomer(name, gender, dob, phone, email, address) Customer
          +submitOrder(custId, svcId, originId, destId, distKm, pickupDate, consignments) Order
          +approveOrder(orderId) Invoice
          +rejectOrder(orderId, reason) void
          +cancelOrder(orderId) void
      }
      class DispatchManager {
          <<control>>
          -DataStore store
          +assignShipment(orderId, vehicleId, driverId) Shipment
          +findAvailableVehicles(branchId, weightKg, volumeM3) List
          +findAvailableDrivers(branchId) List
          +onOrderApproved(order) void
      }
      class ShipmentTracker {
          <<control>>
          -DataStore store
          -ITelemetrySource telemetry
          +confirmPickup(shipmentId, location) void
          +confirmInTransit(shipmentId, location) void
          +confirmDelivery(shipmentId, location) void
      }
      class PaymentProcessor {
          <<control>>
          -DataStore store
          -IPaymentGateway gateway
          +submitPayment(invoiceId, amount, method) Receipt
      }
  
      %% ============ Infrastructure ============
      class DataStore {
          <<repository>>
          -Connection conn
          +load() void
          +save() void
          +customers() Map
          +orders() Map
      }
      class ManualTelemetrySource {
          -Map staged
          +stageLocation(shipmentId, rawLocation) void
          +readLocation(shipmentId) String
      }
      class SimulatedGatewayAdapter {
          +verifyTransaction(paymentId, amount) boolean
      }
  
      %% ============ People ============
      class Person {
          <<abstract>>
          #String id
          #String fullName
          #String phone
          #String email
      }
      class Customer {
          -CustomerStatus status
          -List orderIds
          +recordOrder(orderId) void
      }
      class StaffMember {
          -StaffRole role
          -String homeBranchId
          +getRole() StaffRole
      }
      class Driver {
          -String licenseNumber
          -DutyState dutyState
          +setDutyState(state) void
          +isAvailable() boolean
      }
  
      %% ============ Core Domain ============
      class Order {
          -String id
          -OrderState state
          -double quotedAmount
          -List consignments
          +approve() void
          +reject(reason) void
          +cancel() void
          +addConsignment(c) void
      }
      class Consignment {
          -String id
          -double weightKg
          -double volumeM3
          +getWeightKg() double
      }
      class ServiceOffering {
          -String id
          -String name
          -String pricingTariffId
          +isAvailableAt(branchId) boolean
      }
      class PricingTariff {
          -double baseRate
          -double perKmRate
          -double perKgRate
          +calculateQuote(distanceKm, totalWeightKg, isPeakPeriod) double
      }
      class Branch {
          -String id
          -String name
          -String city
          +registerVehicle(id) void
          +registerDriver(id) void
      }
      class Vehicle {
          -String id
          -double maxWeightCapacityKg
          -VehicleStatus status
          +canCarry(weightKg, volumeM3) boolean
          +isAvailable() boolean
      }
      class Shipment {
          -String id
          -ShipmentState state
          -String lastKnownLocation
          +pickUp() void
          +transit() void
          +deliver() void
          +updateLocation(loc) void
      }
      class Invoice {
          -String id
          -double totalAmount
          -double outstandingBalance
          -InvoiceState state
          +applyPayment(paymentId, amount) void
          +isSettled() boolean
      }
      class Payment {
          -String id
          -double amount
          -PaymentState state
          +verify() void
          +settle() void
          +fail(reason) void
      }
      class Receipt {
          -String id
          -LocalDateTime issuedAt
          +toString() String
      }
  
      %% ============ State Generalization ============
      OrderState <|-- OrderSubmittedState
      OrderState <|-- OrderApprovedState
      OrderState <|-- OrderRejectedState
      OrderState <|-- OrderCancelledState
      ShipmentState <|-- ShipmentAssignedState
      ShipmentState <|-- ShipmentPickedUpState
      ShipmentState <|-- ShipmentInTransitState
      ShipmentState <|-- ShipmentDeliveredState
      InvoiceState <|-- InvoiceUnpaidState
      InvoiceState <|-- InvoicePartiallyPaidState
      InvoiceState <|-- InvoicePaidState
      PaymentState <|-- PaymentPendingState
      PaymentState <|-- PaymentVerifiedState
      PaymentState <|-- PaymentSettledState
      PaymentState <|-- PaymentFailedState
  
      %% ============ Generalization ============
      Person <|-- Customer
      Person <|-- StaffMember
      StaffMember <|-- Driver
  
      %% ============ Realization ============
      IPricingStrategy <|.. PricingTariff
      IPaymentStrategy <|.. CashPaymentStrategy
      IPaymentStrategy <|.. GatewayPaymentStrategy
      ITelemetrySource <|.. ManualTelemetrySource
      IPaymentGateway <|.. SimulatedGatewayAdapter
  
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
      PaymentProcessor ..> Invoice
      PaymentProcessor ..> DataStore
      PaymentProcessor --> IPaymentGateway
      PaymentProcessor --> IPaymentStrategy
  
      %% ============ Domain associations ============
      Customer \"1\" --> \"1..*\" Order
      Order \"1\" *-- \"1..*\" Consignment
      Order \"1\" --> \"1\" ServiceOffering
      Order \"1\" --> \"0..1\" Shipment
      Order \"1\" --> \"1\" Invoice
      ServiceOffering \"1\" --> \"1\" PricingTariff

      Branch \"1\" o-- \"1..*\" Vehicle
      Branch \"1\" o-- \"1..*\" Driver
      Shipment \"1\" --> \"1\" Vehicle
      Shipment \"1\" --> \"1\" Driver

      Invoice \"1\" *-- \"1..*\" Payment
      Payment \"1\" --> \"0..1\" Receipt
  
      %% ============ State usage ============
      Order --> OrderState
      Shipment --> ShipmentState
      Invoice --> InvoiceState
      Payment --> PaymentState
      Driver ..> DutyState
      Vehicle ..> VehicleStatus
      StaffMember ..> StaffRole
      Payment ..> PaymentMethod
  "),
  caption: [Final implementation class diagram showing application controllers, domain entities, state and strategy patterns, and persistence relationships.],
) <fig-final-class-model>

== GRASP Controller assignments

A GRASP Controller is a non-UI object that handles incoming system events for a use-case session or operational domain @larman2004uml. SmartFM has one application controller per business area. UI event handlers do not construct domain entities or change state directly. Instead, `Launcher` creates a `Bootstrap` instance that wires controllers and event listeners. UI actions then pass all requests to these controller operations.

#colbreak()
#figure(
  styled-table((1.75fr, 2.25fr, 3.0fr, 1.95fr), (
    th[GRASP Controller], th[System events received], th[Delegation and collaboration], th[Why this is the Controller],
    [`OrderProcessor`], [`registerCustomer()`, `submitOrder()`, `approveOrder()`, `rejectOrder()`, `cancelOrder()`], [Coordinates `Customer`, `Consignment`, `Order`, and `Invoice`; fires order-approved and invoice-created events.], [Represents the order-management use-case session; keeps UI free of domain rules.],
    [`DispatchManager`], [`assignShipment(orderId, vehicleId, driverId)`, `findAvailableVehicles()`, `findAvailableDrivers()`], [Checks branch affinity, capacity, and availability; creates `Shipment` and fires shipment-assigned event.], [Represents the dispatcher-facing dispatch use case; retains human decision.],
    [`ShipmentTracker`], [`confirmPickup()`, `confirmInTransit()`, `confirmDelivery()`], [Delegates state transitions to `ShipmentState` subclasses and records telemetry through `ITelemetrySource`.], [Receives tracking events and delegates transition legality to the state object.],
    [`PaymentProcessor`], [`submitPayment(invoiceId, amount, method)`], [Validates against outstanding balance, selects `IPaymentStrategy`, invokes `SimulatedGatewayAdapter` for card payments, settles invoices, and issues immutable `Receipt`.], [Represents payment processing; keeps gateway details out of domain models.],
  )),
  caption: [Explicit GRASP Controller allocation.],
) <tbl-grasp-controller>

== Lifecycle, patterns, and dynamic constraints

We used the State pattern to enforce lifecycle rules so that illegal transitions are caught at the point of request rather than discovered later in corrupted data. Each lifecycle uses a polymorphic class hierarchy: concrete state subclasses override only the transitions they permit and inherit default rejection from the abstract base. Orders move from Submitted to Approved, Rejected (with reason), or Cancelled. Shipments progress strictly from Assigned to Picked Up to In Transit to Delivered, with no shortcuts. Invoices go from Unpaid to Partially Paid or Paid depending on the outstanding balance, and Payments go from Pending to Verified to Settled, or to Failed at any point before settlement. Any out-of-order transition throws an `InvalidDataException`. For example, a shipment cannot be marked Delivered without first passing through Picked Up and In Transit. An early bug during development confirmed this guard was worth the sixteen concrete State subclasses across the four hierarchies.

#figure(
  styled-table((1.7fr, 3.15fr, 4.1fr), (
    th[Pattern / GRASP principle], th[Concrete implementation], th[Reason and resulting constraint],
    [State], [Four abstract hierarchies with sixteen concrete subclasses (e.g. `OrderSubmittedState`, `ShipmentAssignedState`, `InvoiceUnpaidState`, `PaymentPendingState`)], [Moves rules out of large conditional controllers. Each state accepts only its legal next operation.],
    [Observer], [Listener interfaces for order approval, invoice creation, and shipment assignment], [Coordinates operational areas without a publisher referring to a concrete subscriber class.],
    [Strategy], [`IPaymentStrategy` (`CashPaymentStrategy` vs `GatewayPaymentStrategy`); `IPricingStrategy` / `PricingTariff`], [`PaymentProcessor` delegates cash and card processing through `IPaymentStrategy`. `IPricingStrategy` / `PricingTariff` provides pluggable pricing via `calculateQuote(distanceKm, totalWeightKg, isPeakPeriod)` (Section 3.2).],
    [Adapter / Protected Variations], [`SimulatedGatewayAdapter` (implements `IPaymentGateway`), `ManualTelemetrySource` (implements `ITelemetrySource`)], [External systems are accessed through stable interfaces (`verifyTransaction()`, `stageLocation()`/`readLocation()`), allowing replacement with real integrations later.],
    [Creator / Information Expert], [Controllers create aggregates; entities/states own transition knowledge], [Construction occurs where inputs are available; invariant checks occur where knowledge resides.],
    [Indirection / Low Coupling], [`DataStore` and listener interfaces], [Controllers do not expose JDBC/SQL or concrete cross-controller dependencies to UI/domain layers.],
  )),
  caption: [Patterns and GRASP principles realised by the detailed design.],
) <tbl-pattern-grasp>

=== SQLite database design

`DataStore` is the persistence gateway, filling the role that Assumption A1 from Assignment 2 left open, while keeping domain models independent of database logic. It connects to the embedded SQLite database (`data/smartfm.db`) using the pinned Xerial JDBC driver. All database operations use prepared statements within explicit transactions.

When saving, `DataStore` atomically updates the normalized aggregate tables. When loading, it reconstructs domain objects, relationships, and state hierarchies in dependency order. The system checks for schema version 3 on startup and rejects incompatible database versions, requiring a database reset if an older schema is found.

#figure(
  image("images/db.png", width: 95%),
  caption: [Entity-Relationship diagram of the normalized SQLite database schema managed by `DataStore`.],
) <fig-db-schema>

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
  caption: [Normalized SQLite schema owned by `DataStore`. All writes happen in one transaction with foreign keys enabled.],
) <tbl-sqlite-schema>

== Selected use-case sequence diagrams

The four sequence diagrams below show the main implemented use cases. Each diagram shows the controller methods that the GUI boundary calls. Section 4.1 maps these interactions to source code, and Section 4.3 provides execution evidence for each flow.

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant C as Customer / GUI Panel
    participant OP as OrderProcessor<br/>«GRASP Controller»
    participant DOM as Customer, Consignment, Order
    participant DS as DataStore

    C->>OP: registerCustomer(name, gender, dob, phone, email, address)
    OP->>DOM: create and validate Customer
    OP->>DS: stage customer in aggregate
    C->>OP: submitOrder(custId, svcId, originId, destId, distKm, date, consignments)
    OP->>DOM: create Consignment(s) and Order
    OP->>DS: stage order; return id
  "),
  caption: [UC-01 / UC-02: customer registration and order submission. The boundary sends each system event to `OrderProcessor`, which creates and validates domain objects and persists changes to SQLite through `DataStore`.],
) <fig-seq-order>

#figure(
  mermaid("
sequenceDiagram
    autonumber
    participant D as Dispatcher / GUI Panel
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
    participant O as Operator / GUI Panel
    participant ST as ShipmentTracker<br/>«GRASP Controller»
    participant TS as ManualTelemetrySource / ShipmentState
    participant DS as Shipment / DataStore

    O->>ST: confirmPickup / confirmInTransit / confirmDelivery(shipmentId, location)
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
    participant C as Customer / GUI Panel
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

== Justification of changes and non-changes

=== Class-level changes and non-changes

All fourteen core domain classes from Assignment 2 (Customer, Order, Consignment, Shipment, Vehicle, Driver, Branch, ServiceOffering, PricingTariff, Invoice, Payment, Receipt, and the Person hierarchy) are in the final implementation with the same responsibilities. The four State hierarchies and core interfaces (`IPaymentGateway`, `IPaymentStrategy`, `IPricingStrategy`, `ITelemetrySource`) were also kept. The only additions are components that Assignment 2 explicitly deferred: `DataStore` for persistence, concrete adapters, `Bootstrap` for startup wiring, listener interfaces, and the UI boundary classes. Table 1 in Section 1 lists every revision; the paragraphs below explain the reasoning for the main changes.

The main class-level change was updating the `Invoice` to `Payment` relationship from 1-to-1 to 1-to-Many. During implementation, we found that a customer paying a 500-dollar invoice with a 200-dollar cash deposit followed by a 300-dollar card payment was impossible under the 1-to-1 constraint. The new `InvoicePartiallyPaidState` tracks the remaining balance across multiple `Payment` objects. Each `Payment` remains immutable once settled.

Features outside the four operational areas, such as authentication or role-based access (`StaffMember`, `StaffRole`, `SystemConfiguration`), remain in the domain model without UI bindings. We deferred these deliberately rather than deliver half-built features. The `Report` class and its coordinating controller `ReportProcessor` are fully implemented (Task T12) and exposed via the `ReportPanel` UI tab.

=== Responsibilities and collaborators

The responsibility split from Assignment 2 (entities own business rules, controllers coordinate workflows, boundaries handle I/O) carried over without change. The one new collaborator is `DataStore`, which controllers receive at construction time so domain entities stay persistence-agnostic.

The biggest responsibility-level refinement was replacing narrative observer callbacks with typed listener interfaces (`OrderApprovedListener`, `InvoiceCreatedListener`). In Assignment 2, we wrote that "DispatchManager subscribes to order events," but during coding that wording turned out to be ambiguous: did it mean automatic dispatch or just a notification? Defining narrow interfaces made the answer clear. `OrderProcessor` fires an event, `DispatchManager.onOrderApproved` flags the order as dispatch-ready, and a human dispatcher must still call `assignShipment(...)` to allocate resources.

=== Dynamic aspects: bootstrap and interactions

Assignment 2 did not specify how the system starts up or when data is saved; those decisions were made during implementation.

On first launch, `DataStore` creates `data/smartfm.db`, builds all tables in a single transaction, and seeds demonstration records (two branches, three vehicles, three drivers, and three service offerings). On later launches it detects the existing schema (version 3) and loads domain objects directly. `Bootstrap` then wires the four controllers and registers their event listeners in dependency-safe order. For example, `DispatchManager` is registered as an `OrderApprovedListener` on `OrderProcessor` before any orders can be approved.

We chose to persist after every state mutation rather than only on exit, so that user actions are immediately committed to disk. The interaction order matters: order approval updates the order and creates the invoice _before_ notifying listeners, dispatch stages shipment and resource changes _before_ firing `shipmentAssigned`, and payments generate a receipt only _after_ settlement succeeds. These sequences match the diagrams in Section 2.4.

== Architecture style(s)

SmartFM uses two complementary architecture styles: a *Layered Architecture* for structural organisation and an *Event-Driven Architecture* for cross-subsystem communication. We chose this combination because a pure layered design would have forced `OrderProcessor` to call `DispatchManager` directly when an order is approved, creating tight coupling between two independent business areas. Adding event connectors at the application layer keeps the dispatch decision with the human operator while notifying the tracking subsystem automatically.

The system has four architectural components:
1. *Presentation:* `SmartFmMainFrame` and the Swing panel classes (`smartfm.ui.gui`).
2. *Order and Billing:* `OrderProcessor`, `PaymentProcessor`, and their domain entities.
3. *Fleet and Dispatch:* `DispatchManager`, `ShipmentTracker`, and their domain entities.
4. *Persistence:* The `DataStore` database gateway.

These components communicate through two connector types. *Synchronous downward calls* follow the layer ordering: UI views call controller methods, controllers coordinate domain entities, and controllers call `DataStore`. *Event connectors* operate within the application layer: order approval, invoice creation, and shipment assignment publish events through narrow listener interfaces, so no publisher needs to know which concrete class handles the event.

Three architectural constraints enforce these rules:
1. Domain classes never import presentation or application packages (verified by the package structure).
2. `DataStore` is accessed only through controllers. UI and domain classes never touch JDBC.
3. Event publishers depend only on listener interfaces, not on concrete subscriber classes.

= Design Quality

== Good aspects of the Assignment 2 design

The CRC cards from Assignment 2 mapped almost one-to-one to controller methods. For example, `OrderProcessor`'s three core responsibilities became `registerCustomer()`, `submitOrder()`, and `approveOrder()` with nothing extra bolted on. The CRC description was specific enough to code from directly. Defining lifecycle tables early was equally useful: each table row became a concrete State subclass, and writing JUnit tests for invalid transitions was straightforward because the expected behaviour was already written down.

Design patterns chosen during Assignment 2 also worked well in practice. The Adapter pattern let us build `SimulatedGatewayAdapter` for development and swap it for a real payment gateway later without touching `PaymentProcessor`. The Observer pattern kept controllers decoupled. When order approval needed to notify `PaymentProcessor` about a newly created invoice, we registered it as an `InvoiceCreatedListener` rather than adding a direct call inside `OrderProcessor`.

The four controllers maintain high cohesion: each one owns a single business area and delegates domain logic to the entities it coordinates. Coupling stays low because the UI depends on controller methods (not domain internals) and cross-controller communication flows through abstract listener interfaces.

== Missing or ambiguous aspects

Assignment 2 deliberately excluded UI and persistence details, which made sense for a high-level design but left gaps to fill during coding. We had to define input-validation rules (e.g. phone format, non-negative cargo weight), error-feedback flows for the GUI, the full SQLite schema, and the bootstrap/seeding sequence. These additions were substantial (`DataStore` alone grew to nearly 800 lines), but they did not contradict the original design. They extended it into areas that Assignment 2 had flagged as out of scope.

The main ambiguity was whether dispatch should be automatic or manual. Assignment 2 described `DispatchManager` as "subscribing to order approval events," which our team initially read as automatic assignment. During implementation, we realised this contradicted the SRS requirement for human dispatchers to choose vehicles and drivers. Resolving this took two team discussions before we settled on the current approach: the event notifies `DispatchManager` that an order is ready, but a dispatcher must still call `assignShipment(...)` explicitly.

Two minor design gaps remain in the implementation:

1. *Branch service validation:* `OrderProcessor.submitOrder()` does check whether a `ServiceOffering` is available at the origin branch via `offering.isAvailableAt(originBranchId)`, but the GUI does not dynamically filter the service dropdown by branch. A richer branch-aware UI could improve usability in future iterations.
2. *Pricing Strategy wiring:* `IPricingStrategy` and `PricingTariff` exist as designed, but `OrderProcessor` calls `PricingTariff.calculateQuote()` directly instead of going through `ServiceOffering`. The indirection layer is ready for future pricing models but is not exercised today.

== Flaws or errors in the initial design

The most consequential flaw was the dispatch ambiguity discussed in Section 3.2. In hindsight, we should have drawn at least a basic dispatch screen wireframe during Assignment 2. A simple sketch showing a "Select Vehicle" dropdown and an "Assign" button would have made the manual-dispatch requirement obvious and saved two days of team debate during implementation.

The second flaw was omitting any persistence contract. Assignment 2's Assumption A1 acknowledged that "data access is deferred," but it said nothing about _when_ to save or _how_ to initialise. This forced us to design the entire `DataStore` transaction model from scratch. It worked out, but even a brief paragraph in the original design would have helped.

The third flaw was the 1-to-1 constraint between `Invoice` and `Payment`. We only discovered this was a problem when trying to implement a scenario where a customer pays in two instalments: cash first, then card. The fix (1-to-Many with `InvoicePartiallyPaidState`) was straightforward, but walking through realistic payment scenarios during design would have caught it earlier.

Finally, `ServiceOffering` was documented as delegating to `IPricingStrategy`, but the delegation was never listed in the CRC collaborators. During coding, we wired `PricingTariff` directly into `OrderProcessor` rather than routing through `ServiceOffering`. The strategy pattern is structurally present but not fully exercised.

== Level of interpretation required

Overall, the Assignment 2 design required moderate interpretation. The parts that were well specified (entity attributes, State transition tables, controller responsibilities, and pattern contracts) translated to code with little guesswork. The areas that needed the most interpretation were:

- *Persistence timing:* When should the system save? We chose "after every mutation" rather than "on exit only" so that user actions are committed to disk right away (Section 2.5.3).
- *Input validation:* Assignment 2 defined what data each entity holds but not what counts as valid input. We added regex-based phone and email validation, non-negative weight checks, and non-blank name enforcement in `smartfm.common.Validators`.
- *Adapter behaviour:* The interfaces were defined, but how a simulated gateway or manual telemetry source should behave was left open. We kept both adapters simple. `SimulatedGatewayAdapter` always approves and `ManualTelemetrySource` accepts free-text locations, making them easy to replace with real integrations.
- *Dispatch workflow:* As discussed in Sections 3.2 and 3.3, the original observer description was ambiguous about automation versus notification.

== Lessons learnt

Building SmartFM taught us several things that would change how we approach OO design next time.

*Specify state behaviour, not just state names.* The lifecycle tables in Assignment 2 were our most useful design artefact. Because each row already defined legal transitions, writing State subclasses was mechanical. We knew which methods to allow and which to reject. By contrast, the observer descriptions were vague enough that we spent two days debating whether dispatch was automatic or manual. Next time, we would specify observer semantics with the same precision as state transitions: what triggers the event, what the listener is allowed to do, and what still requires human action.

*Walk through realistic scenarios during design.* The Invoice-Payment multiplicity flaw would have been caught immediately if we had traced a partial-payment scenario (for example, "200 cash now, 300 card later") through the CRC cards. In future designs, we would run at least one scenario per use case through the design model before calling it complete.

*Wire patterns end-to-end or document why not.* We defined `IPricingStrategy` and `PricingTariff` but never connected them through `ServiceOffering`. The pattern looks good on the class diagram, but in the running code, `OrderProcessor` calls `PricingTariff` directly. A pattern declared but not exercised adds complexity without value. Next time, we would either complete the wiring or explicitly mark the interface as a future extension point.

*Include persistence and UI sketches early.* Assignment 2 deferred both, which was acceptable for a high-level design but meant we had to make major architectural decisions (transaction boundaries, schema versioning, validation rules) during coding without design guidance. Even a one-paragraph persistence contract and a rough UI wireframe would have reduced the interpretation effort.

*Invest in test automation from day one.* Our JUnit suite (76 test executions across 17 test classes) and the automated `ScreenshotDriver` paid for themselves many times over. Every time we changed a State class or refactored `DataStore`, the tests caught regressions within seconds. Working with Java 26 also taught us a practical lesson: SQLite JDBC requires the flag `--enable-native-access=ALL-UNNAMED`. This is easy to miss and would block execution without the provided Makefile.

= Implementation and Testing

== Mapping design to code

SmartFM is implemented in Java 26 using a standard Maven project layout. The design elements and sequence diagrams map directly to the source code.

*Coding standards and metrics:* The codebase follows the Google Java Style Guide @google2023javastyle. It uses standard naming conventions, explicit control blocks, and concise Javadoc comments. Source files compile with zero lint warnings under `javac -Xlint:all`. We verify correctness with 76 automated JUnit 5 test executions across 17 test classes (including parameterized tests that expand to multiple cases), covering domain states, event pipelines, SQLite persistence, and Swing GUI components. All tests pass.

*Development environment:* We developed on Windows using PowerShell 7.6 and OpenJDK 26.0.2. The application needs Java 26 and the bundled library JARs in `lib/`. It runs locally without external database servers. You can build with Maven, GNU Make, or standard `javac`.

#figure(
  styled-table((2.0fr, 2.65fr, 3.8fr), (
    th[Design element / sequence diagram], th[Production code], th[Implementation match],
    [Presentation boundary], [`smartfm.ui.Launcher`, `SmartFmMainFrame`, GUI panels], [GUI obtains `Bootstrap` on startup and invokes controller operations.],
    [UC-01/UC-02, @fig-seq-order], [`OrderProcessor`, `Customer`, `Consignment`, `Order`, `Invoice`], [`OrderProcessor` registers customers, calculates quotes, handles approval/cancellation, and generates invoices.],
    [UC-03, @fig-seq-dispatch], [`DispatchManager`, `Vehicle`, `Driver`, `Shipment`], [`DispatchManager` checks resource prerequisites, creates shipments, and fires assignment events.],
    [UC-04, @fig-seq-tracking], [`ShipmentTracker`, `ManualTelemetrySource`, `ShipmentState`], [`ShipmentTracker` delegates state updates to `ShipmentState` subclasses and records telemetry.],
    [UC-05, @fig-seq-payment], [`PaymentProcessor`, `IPaymentStrategy`, `SimulatedGatewayAdapter`], [`PaymentProcessor` validates balances, delegates cash/card strategies, invokes adapter, and generates receipts.],
    [T12 / Administrative Reports], [`ReportProcessor`, `Report`, `ReportPanel`], [`ReportProcessor` aggregates metrics across `DataStore` entities and presents KPI cards, tables, and documents in `ReportPanel`.],
    [Persistence / indirection], [`smartfm.infrastructure.DataStore`], [`DataStore` manages SQLite JDBC operations inside atomic transactions.],
    [Bootstrap / observer wiring], [`Bootstrap`, listener interfaces, `IdGenerator`], [Seeds initial database records and wires listener interfaces in dependency-safe order.],
  )),
  caption: [Traceability from detailed design and selected sequence diagrams to Java source.],
) <tbl-design-code-map>

*Task coverage.* The table below maps each SRS task (from Assignment 1) to its implementation status. Nine of fifteen tasks are fully implemented. The remaining six are either partially supported or outside the four-area scope we selected.

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
    [T12: Generate Reports], [Full], [Implemented via `ReportProcessor` and `ReportPanel` across financial, fleet, branch, and commercial order metrics.],
    [T13: Update Customer], [Not implemented], [Customer status can be changed programmatically but no update UI is provided.],
    [T14: Cancel/Modify Order], [Partial], [Cancellation is implemented; modification of submitted order fields is not supported.],
    [T15: Manage Config], [Not implemented], [`SystemConfiguration` is loaded at startup but no admin UI for changing values is provided.],
  )),
  caption: [SRS task coverage: nine tasks fully implemented, one partially supported, and five tasks are out of scope.],
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
    [`src/main/java/smartfm/ui/`, `src/main/java/smartfm/ui/gui/`], [Swing desktop GUI presentation layer over application controllers.],
    [`scenarios/`], [Test scenario scripts for automated UI evidence drivers.],
    [`tools/java/`], [GUI screenshot automation driver.],
  )),
  caption: [Standard project layout and package organisation.],
) <tbl-project-layout>

== Compilation and Execution

*Prerequisites:* Building and running the application needs JDK 26. SQLite is embedded, so no external database or network configuration is needed. All required library JARs are declared in `pom.xml` and stored in `lib/`. Running on Java 26 requires `--enable-native-access=ALL-UNNAMED` for SQLite JDBC native library loading. Run commands from the project root directory using one of the methods below.

*Using Maven (recommended):*

#console(```
mvn test          # Runs all 76 automated JUnit 5 tests
mvn package       # Compiles and builds the self-contained executable JAR
java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar
```) 

*Using Makefile:*

#console(```
make compile      # Compiles Java sources with -Xlint:all
make run          # Launches GUI interface
make jar          # Builds target/smartfm.jar
```)



Data is stored locally in the embedded SQLite database `data/smartfm.db`. Delete this database and any `-wal`/`-shm` sidecar files (or run `make reset`) to return to the seeded state: two branches, three vehicles, three drivers, and three service offerings. No external database server, credentials, or network service is required.

#figure(
  image("images/compilation.png", width: 95%),
  caption: [Compilation and test execution evidence: Maven build executing all 76 automated JUnit 5 tests successfully and packaging the self-contained executable JAR.],
) <fig-compilation>

=== GUI execution screenshots

The screenshots below were generated by running `tools/java/smartfm/ui/gui/ScreenshotDriver.java`. The driver automates user actions and captures the application window directly across all scenarios. The key screenshots illustrating home screen, valid/invalid inputs, outputs, exit state, and compilation evidence are embedded in the report figures below.

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/00_home_screen_empty.png", width: 100%),
    image("images/01b_customer_registration_validation_errors.png", width: 100%),
  ),
  caption: [Empty customer-registration home screen (left) and rejected invalid phone/email input with inline messages (right).],
) <fig-gui-empty-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/01c_customer_registration_success.png", width: 100%),
    image("images/02f_order_management_order_cancelled.png", width: 100%),
  ),
  caption: [Accepted customer input and successful account creation (left); a customer change of mind cancels an order without deleting unrelated data (right).],
) <fig-gui-input-change>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/03d_fleet_dispatch_shipment_created.png", width: 100%),
    image("images/04b_shipment_tracking_invalid_transition_rejected.png", width: 100%),
  ),
  caption: [Successful vehicle/driver assignment creates a shipment (left); an illegal delivery-before-pickup transition is rejected by the State pattern (right).],
) <fig-gui-dispatch-tracking-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/04e_shipment_tracking_delivered.png", width: 100%),
    image("images/05d_billing_payment_settled.png", width: 100%),
  ),
  caption: [Successful delivery transition (left); simulated payment completion, receipt issuance, and a paid invoice (right). No real banking transaction is performed.],
) <fig-gui-completion>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/06a_reports_financial_summary.png", width: 100%),
    image("images/06b_reports_fleet_utilization.png", width: 100%),
  ),
  caption: [Administrative report generation UI: financial and revenue summary report (left); fleet asset utilization and dispatch report (right).],
) <fig-gui-reports>

#figure(
  image("images/06_final_state_before_exit.png", width: 75%),
  caption: [Final application state immediately before normal exit. Closing the window invokes the registered handler, commits the normalized `DataStore` rows to SQLite, and exits cleanly.],
) <fig-gui-exit>

To regenerate all screenshots on a machine with JDK 26 and GNU Make, run `make screenshots`. The driver resets demonstration data, executes the test scenarios, saves the screenshots, and exits.

== Testing

System testing covers compiler linting, automated unit and integration tests, scenario-based acceptance testing, and persistence verification.

*Automated testing:* The JUnit 5 test suite (`src/test/java/smartfm/`) produces 76 test executions via `mvn test`, distributed across 17 test classes containing 65 written test methods (including four `@ParameterizedTest` methods that expand to multiple cases). The tests cover:
1. *Common Layer:* Currency formatting, timestamp rendering, and field validators (`MoneyTest`, `ValidatorsTest`).
2. *Domain Layer:* Entity invariants, cargo aggregation, state transitions, receipt issuance, and pricing tariffs across domain packages.
3. *Application Layer:* Event dispatch, shipment creation, resource allocation, and payment settlement across all four controllers.
4. *Infrastructure Layer:* Saving and reloading normalized aggregates in SQLite (`DataStoreTest`).
5. *Core E2E Workflows:* Full business flow execution from registration to payment settlement and database recovery (`SmartFmEndToEndTest`).
6. *Swing GUI E2E:* Interactive GUI testing on the Event Dispatch Thread covering validation errors, dispatch, and window closure (`SmartFmGuiEndToEndTest`).
7. *GUI Persistence:* Real-time SQLite auto-save verification upon UI state mutation (`GuiContextAndPersistenceTest`).
8. *Coverage Helpers:* GUI component event handling and edge-case form input helpers (`SmartFmGuiCoverageTest`).

All 76 test executions complete in under 5 seconds with zero failures.

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



After running Scenario 05, `data/smartfm.db` contains committed database rows for two customers, three orders, one delivered shipment, one paid invoice, two settled payments, and two receipts. The table schema is set to version 3 with foreign keys enabled. Re-launching the application verifies that application state persists correctly across separate process runs.

= Conclusion

SmartFM shows that a well-structured Assignment 2 design can turn into working software with relatively few structural surprises. The core entities, State patterns, and controller responsibilities survived implementation largely intact. The changes we made (adding persistence, replacing vague observer descriptions with typed listeners, and relaxing the Invoice-Payment multiplicity) came from concrete problems found during coding rather than design trends.

The system compiles cleanly, passes all 76 automated test executions, and runs the four business workflows end-to-end through its Swing GUI. Deferred features such as report generation and service browsing can be added later without restructuring the layered architecture. If we were to start this project again, we would spend more time on persistence contracts, UI sketches, and scenario walkthroughs during the design phase. However, the overall approach of GRASP Controllers, lifecycle State classes, and event-driven subsystem communication turned out to be a solid foundation.

= References

#bibliography("refs.bib", title: none, style: "harvard-cite-them-right")

= Appendices

== Appendix A: Assignment 2 Object Design (Complete Submission) <appendix-asm2>

The complete Assignment 2 Object Design submission is attached below so this report is self-contained. References such as “Assignment 2 lifecycle table” and “Assignment 2 Assumption A1” refer to this attached document.

#counter("appendix").update(1)
#colbreak()

#for page-num in range(1, 32) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm2.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}
