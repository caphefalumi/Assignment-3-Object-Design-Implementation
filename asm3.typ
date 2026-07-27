#import "ieee.typ": *
#import "@preview/mmdr:0.2.2": *

#show: ieee.with(
  title: "SWE30003 Assignment 3\nObject Design Implementation and Reflection",
  sub_title: "Smart Fleet Management System",
  date_of_submission: "3rd August 2026",
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
#set heading(numbering: "1.")
= Introduction

SmartFM is the fleet-logistics desktop application our team designed in Assignment 2 and has now implemented in Java 26. It covers customer registration, order placement, dispatch, shipment tracking, billing, and payment. This report explains how the high-level design became running code, what we revised during implementation, and what that process taught us.

Section 2 records revisions from Assignment 2. Section 3 covers the detailed class design, sequence diagrams, and architecture. Section 4 discusses design quality and lessons learned. Section 5 maps design to code, gives build and run instructions, and presents execution and test evidence. Appendix A contains the full Assignment 2 submission.

We built four transactional business areas (Order Management, Fleet Dispatch, Shipment Tracking, and Billing & Payment) plus administrative reporting (Task T12) via `ReportProcessor`. The Swing GUI (`smartfm.ui.gui`) collects input and shows results; it delegates every business request to application controllers and holds no domain rules of its own.

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
    [A2 shipment-milestone observer description], [Assignment 2 also described notifications after pickup, transit, and delivery, but no such listener was needed by the implemented workflows.], [Retained only order approval, invoice creation, and shipment-assignment events; milestone actions remain explicit `ShipmentTracker` calls.], [The implemented Observer scope is now explicit.],
    [A2 Order-Shipment multiplicity], [The conceptual model allowed multiple shipments per order, while implementation creates at most one shipment per order.], [Changed the association from 1-to-Many to 1-to-0..1 and rejects duplicate assignments.], [The class model now matches `DispatchManager`.],
    [A2 Customer-Order and Order-Invoice multiplicities], [The original model required an order and invoice immediately, although registration precedes order creation and invoicing occurs only after approval.], [Changed Customer-Order to `1-to-0..*` and Order-Invoice to `1-to-0..1`.], [The associations now reflect the actual lifecycle.],
    [A2 Branch resource multiplicities], [The original model allowed a branch to have no resources; the revised diagram accidentally stated `1..*` although the implementation does not enforce a minimum.], [Restored Branch-to-Vehicle and Branch-to-Driver to `1-to-0..*`.], [The model matches the domain classes and seeded-data behavior.],
    [A2 wide conceptual scope], [`Report`'s data-holder design was already scoped in Assignment 2 (Assumption A13; CRC card, Appendix A), but no coordinating controller or UI existed.], [Added the missing `ReportProcessor` controller and `ReportPanel` UI tab to realize the existing `Report` design.], [Implemented Task T12 with zero changes to existing transactional production code.],
    [A2 Invoice-Payment relationship was underspecified], [The `Payment` CRC card described one transaction, but the original model did not clearly define multiple payments per invoice.], [Changed the association to 1-to-Many and added `InvoicePartiallyPaidState`.], [Supported partial cash/card payment scenarios.],
    [A2 package and channel scope], [Assignment 2 grouped domain classes into broader packages and assumed web/mobile/staff portals; Assignment 3 uses a reorganised domain package structure and a Swing desktop boundary.], [Split domain packages and implemented the Swing GUI; web and mobile portals remain outside this submission.], [The implementation scope is explicit.],
    [A2 ServiceOffering-Branch conceptual link], [A2 described branch coverage conceptually but specified no enforcement point.], [Added `Branch.registerServiceOffering()` and made `OrderProcessor.submitOrder()` reject orders whose origin branch is outside `ServiceOffering.isAvailableAt(...)`.], [Origin-branch coverage is now enforced at order entry (Section 3.2).],
  )),
  caption: [Summary of design revisions from Assignment 2 to Assignment 3 based on implementation reviews.],
) <tbl-revision-summary>

= Detailed Design

== Design approach and responsibility allocation

The detailed design keeps the Entity-Control-Boundary structure from Assignment 2. Domain entities store business data and enforce state rules. Application controllers coordinate user requests. UI boundaries handle input and display output, and infrastructure classes isolate database persistence. This follows several GRASP principles (Controller, Information Expert, Low Coupling, Indirection) as described by Larman @larman2004uml.

#figure(
  styled-table((1.65fr, 2.35fr, 4.85fr), (
    th[Package / layer], th[Key classes], th[Responsibility],
    [`smartfm.ui`, `smartfm.ui.gui`], [`Launcher`, `SmartFmMainFrame`, `GuiContext`, six GUI panels], [Boundary layer. Collects and displays information only; it calls controller public operations and displays domain/controller validation messages.],
    [`smartfm.application`], [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`, `ReportProcessor`, `Bootstrap`], [Application layer. The four core transactional GRASP Controllers receive system events, coordinate entities, publish observer events, and stage changes in the persistence gateway; `ReportProcessor` separately coordinates administrative reporting (Task T12).],
    [`smartfm.domain.*` (`customer`, `order`, `shipment`, `billing`, `fleet`, `catalog`, `report`)], [`Customer`, `Order`, `Consignment`, `Shipment`, `Vehicle`, `Driver`, `Invoice`, `Payment`, `Receipt`, `Report`, `ReportCategory`, `SystemConfiguration`, state/strategy interfaces], [Domain layer. Divided into seven domain sub-packages. Owns business information, lifecycle state, pricing/payment behaviour, and entity-level validation. `SystemConfiguration` (in `catalog`) is a read-only startup data-holder.],
    [`smartfm.infrastructure`], [`DataStore`], [Infrastructure layer. Opens the local SQLite database and uses a versioned normalized schema for branches, people and resources, catalogue, orders, shipments, invoices, payments, receipts, and association links. It reads and replaces the aggregate rows inside one SQLite transaction; it is the only persistence mechanism.],
    [`smartfm.common`], [`Validators`, `Money`, `InvalidDataException`, `InvalidCredentialsException`], [Small shared utilities. Validation rules are reused by controllers/boundaries rather than copied between interfaces.],
  )),
  caption: [Layered package design and responsibility allocation.],
) <tbl-layered-design>

The complete model does not fit legibly on a single page, so we present it as three complementary views: the application and infrastructure view (@fig-class-controllers), the domain entity view (@fig-final-class-model), and the lifecycle and enumeration view (@fig-state-hierarchies). Together they contain the principal application, infrastructure, domain, and lifecycle classes; common utilities, UI support classes, and implementation-only helpers are omitted for readability.

#figure(
  mermaid("
  classDiagram
      direction TB

      %% ============ Application controllers ============
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
          +onShipmentAssigned(shipment) void
      }
      class PaymentProcessor {
          <<control>>
          -DataStore store
          -IPaymentGateway gateway
          +submitPayment(invoiceId, amount, method) Receipt
          +onInvoiceCreated(invoice) void
      }
      class ReportProcessor {
          <<control>>
          -DataStore store
          +generateFinancialReport(from, to) Report
          +generateFleetReport(from, to) Report
          +generateBranchReport(branchId, from, to) Report
          +generateOrderSummaryReport(from, to) Report
      }
      class Bootstrap {
          -DataStore store
          +run() void
          +getOrderProcessor() OrderProcessor
      }

      %% ============ Observer interfaces ============
      class OrderApprovedListener {
          <<interface>>
          +onOrderApproved(order) void
      }
      class InvoiceCreatedListener {
          <<interface>>
          +onInvoiceCreated(invoice) void
      }
      class ShipmentAssignedListener {
          <<interface>>
          +onShipmentAssigned(shipment) void
      }

      %% ============ Adapter interfaces and implementations ============
      class ITelemetrySource {
          <<interface>>
          +stageLocation(shipmentId, rawLocation) void
          +readLocation(shipmentId) String
      }
      class IPaymentGateway {
          <<interface>>
          +verifyTransaction(paymentId, amount) boolean
      }
      class IPaymentStrategy {
          <<interface>>
          +process(paymentId, amount) boolean
          +getMethod() PaymentMethod
      }
      class ManualTelemetrySource {
          -Map staged
          +stageLocation(shipmentId, rawLocation) void
          +readLocation(shipmentId) String
      }
      class SimulatedGatewayAdapter {
          +verifyTransaction(paymentId, amount) boolean
      }
      class CashPaymentStrategy {
          +process(paymentId, amount) boolean
          +getMethod() PaymentMethod
      }
      class GatewayPaymentStrategy {
          -IPaymentGateway gateway
          -PaymentMethod method
          +process(paymentId, amount) boolean
          +getMethod() PaymentMethod
      }

      %% ============ Persistence gateway ============
      class DataStore {
          <<repository>>
          +loadFrom(databasePath) DataStore$
          +saveTo(databasePath) void
          +customers() Map
          +orders() Map
          +shipments() Map
          +invoices() Map
          +payments() Map
      }

      %% ============ Realization ============
      OrderApprovedListener <|.. DispatchManager
      InvoiceCreatedListener <|.. PaymentProcessor
      ShipmentAssignedListener <|.. ShipmentTracker
      ITelemetrySource <|.. ManualTelemetrySource
      IPaymentGateway <|.. SimulatedGatewayAdapter
      IPaymentStrategy <|.. CashPaymentStrategy
      IPaymentStrategy <|.. GatewayPaymentStrategy

      %% ============ Wiring and connectors ============
      Bootstrap ..> OrderProcessor
      Bootstrap ..> DispatchManager
      Bootstrap ..> ShipmentTracker
      Bootstrap ..> PaymentProcessor
      Bootstrap ..> ReportProcessor
      OrderProcessor --> OrderApprovedListener
      OrderProcessor --> InvoiceCreatedListener
      DispatchManager --> ShipmentAssignedListener
      ShipmentTracker --> ITelemetrySource
      PaymentProcessor --> IPaymentStrategy
      PaymentProcessor --> IPaymentGateway
      GatewayPaymentStrategy --> IPaymentGateway
      OrderProcessor --> DataStore
      DispatchManager --> DataStore
      ShipmentTracker --> DataStore
      PaymentProcessor --> DataStore
      ReportProcessor --> DataStore
  "),
  caption: [Application and infrastructure view: the five GRASP Controllers, the three Observer listener interfaces they publish through, the adapter and strategy interfaces with their concrete implementations, and the `DataStore` persistence gateway. The domain entities each controller coordinates are listed in @tbl-grasp-controller and detailed in @fig-final-class-model.],
) <fig-class-controllers>

#figure(
  mermaid("
  classDiagram
      direction TB

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

      %% ============ Commercial and ordering ============
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
          +addCoveredBranch(branchId) void
          +isAvailableAt(branchId) boolean
      }
      class IPricingStrategy {
          <<interface>>
          +calculateQuote(distanceKm, totalWeightKg, isPeakPeriod) double
      }
      class PricingTariff {
          -double baseRate
          -double perKmRate
          -double perKgRate
          +calculateQuote(distanceKm, totalWeightKg, isPeakPeriod) double
      }

      %% ============ Fleet and resources ============
      class Branch {
          -String id
          -String name
          -String city
          +registerVehicle(id) void
          +registerDriver(id) void
          +registerServiceOffering(id) void
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

      %% ============ Billing and settlement ============
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

      %% ============ Reporting and configuration ============
      class Report {
          -String id
          -String title
          -ReportCategory category
          -Map metrics
          -String content
          +getMetrics() Map
      }
      class ReportCategory {
          <<enumeration>>
          FINANCIAL
          FLEET
          BRANCH
          ORDER_SUMMARY
      }
      class SystemConfiguration {
          <<data-holder>>
          -int maxFailedLoginAttempts
          -double defaultPeakMultiplier
          -int sessionTimeoutMinutes
          +bootstrap() SystemConfiguration$
      }

      %% ============ Generalization and realization ============
      Person <|-- Customer
      Person <|-- StaffMember
      StaffMember <|-- Driver
      IPricingStrategy <|.. PricingTariff

      %% ============ Associations ============
      Customer \"1\" --> \"0..*\" Order
      Order \"1\" *-- \"1..*\" Consignment
      Order \"1\" --> \"1\" ServiceOffering
      Order \"1\" --> \"0..1\" Shipment
      Order \"1\" --> \"0..1\" Invoice
      ServiceOffering \"1\" --> \"1\" PricingTariff
      ServiceOffering \"1\" --> \"1..*\" Branch
      Branch \"1\" o-- \"0..*\" Vehicle
      Branch \"1\" o-- \"0..*\" Driver
      Shipment \"1\" --> \"1\" Vehicle
      Shipment \"1\" --> \"1\" Driver
      Invoice \"1\" *-- \"0..*\" Payment
      Payment \"1\" --> \"0..1\" Receipt
      Report ..> ReportCategory
  "),
  caption: [Domain entity view: the `Person` hierarchy, the commercial, fleet and billing entities with their final multiplicities (including the clarified `Invoice` to `Payment` 1-to-Many relationship for partial payments), the `ServiceOffering` branch-coverage association added in Assignment 3, and the read-only `SystemConfiguration` data-holder. The lifecycle state objects referenced by `Order`, `Shipment`, `Invoice` and `Payment` are expanded in @fig-state-hierarchies.],
) <fig-final-class-model>


#figure(
  grid(columns: (1fr, 1fr), gutter: 10pt, row-gutter: 14pt,
    mermaid("
  classDiagram
      direction LR
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
      class Order
      OrderState <|-- OrderSubmittedState
      OrderState <|-- OrderApprovedState
      OrderState <|-- OrderRejectedState
      OrderState <|-- OrderCancelledState
      Order --> OrderState
  "),
    mermaid("
  classDiagram
      direction LR
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
      class Shipment
      ShipmentState <|-- ShipmentAssignedState
      ShipmentState <|-- ShipmentPickedUpState
      ShipmentState <|-- ShipmentInTransitState
      ShipmentState <|-- ShipmentDeliveredState
      Shipment --> ShipmentState
  "),
    mermaid("
  classDiagram
      direction LR
      class InvoiceState {
          <<abstract>>
          +applyPayment(invoice, amount) void
          +name() String
      }
      class InvoiceUnpaidState { +name() = Unpaid }
      class InvoicePartiallyPaidState { +name() = Partially Paid }
      class InvoicePaidState { +name() = Paid }
      class Invoice
      InvoiceState <|-- InvoiceUnpaidState
      InvoiceState <|-- InvoicePartiallyPaidState
      InvoiceState <|-- InvoicePaidState
      Invoice --> InvoiceState
  "),
    mermaid("
  classDiagram
      direction LR
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
      class Payment
      PaymentState <|-- PaymentPendingState
      PaymentState <|-- PaymentVerifiedState
      PaymentState <|-- PaymentSettledState
      PaymentState <|-- PaymentFailedState
      Payment --> PaymentState
  "),
  ),
  caption: [Lifecycle view: the four abstract State classes and their fifteen concrete subclasses, one hierarchy per quadrant (order, shipment, invoice, payment). Each concrete subclass overrides only the transitions it permits and inherits `InvalidDataException` rejection from its abstract base, so the owning entity never needs a transition conditional. The `InvoicePartiallyPaidState` in the lower-left hierarchy is the subclass added in Assignment 3 for partial payments.],
) <fig-state-hierarchies>

#figure(
  mermaid("
  classDiagram
      direction TB
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
      class Driver
      class Vehicle
      class StaffMember
      class Payment
      Driver ..> DutyState
      Vehicle ..> VehicleStatus
      StaffMember ..> StaffRole
      Payment ..> PaymentMethod
  "),
  caption: [The four domain enumerations and the entities that own them. `StaffRole.DRIVER` is set by the `Driver` constructor rather than independently, so it cannot diverge from the `Driver` subclass (Section 3.5.1).],
) <fig-enumerations>


== GRASP Controller assignments

A GRASP Controller is a non-UI object that handles incoming system events for a use-case session or operational domain @larman2004uml. SmartFM has one application controller per business area. UI event handlers do not construct domain entities or change state directly. Instead, `Launcher` creates a `Bootstrap` instance that wires controllers and event listeners. UI actions then pass all requests to these controller operations.

#figure(
  styled-table((1.75fr, 2.25fr, 3.0fr, 1.95fr), (
    th[GRASP Controller], th[System events received], th[Delegation and collaboration], th[Why this is the Controller],
    [`OrderProcessor`], [`registerCustomer()`, `submitOrder()`, `approveOrder()`, `rejectOrder()`, `cancelOrder()`], [Coordinates `Customer`, `Consignment`, `Order`, and `Invoice`; checks origin-branch service coverage via `ServiceOffering.isAvailableAt()`; fires order-approved and invoice-created events.], [Represents the order-management use-case session; keeps UI free of domain rules.],
    [`DispatchManager`], [`onOrderApproved(order)`, `assignShipment(orderId, vehicleId, driverId)`, `findAvailableVehicles()`, `findAvailableDrivers()`], [Receives the order-approved event but does not auto-dispatch; checks branch affinity, capacity, and availability, creates `Shipment`, and fires the shipment-assigned event.], [Represents the dispatcher-facing dispatch use case; retains the human assignment decision.],
    [`ShipmentTracker`], [`onShipmentAssigned(shipment)`, `confirmPickup()`, `confirmInTransit()`, `confirmDelivery()`], [Receives the shipment-assigned event to track the new shipment, delegates state transitions to `ShipmentState` subclasses, and records telemetry through `ITelemetrySource`.], [Receives tracking events and delegates transition legality to the state object.],
    [`PaymentProcessor`], [`onInvoiceCreated(invoice)`, `submitPayment(invoiceId, amount, method)`], [Receives invoice-created notifications, validates payments against outstanding balance, selects `IPaymentStrategy`, invokes `SimulatedGatewayAdapter` for card payments, settles invoices, and issues immutable `Receipt`.], [Represents payment processing; keeps gateway details out of domain models.],
    [`ReportProcessor`], [`generateFinancialReport()`, `generateFleetReport()`, `generateBranchReport()`, `generateOrderSummaryReport()`], [Aggregates metrics across `Branch`, `Order`, `Shipment`, `Payment`, `Vehicle`, and `Driver` via `DataStore`; compiles the result into a `Report`.], [Represents the administrative reporting use case (Task T12), separate from the four core transactional controllers.],
  )),
  caption: [Explicit GRASP Controller allocation.],
) <tbl-grasp-controller>

Assignment 2 linked `ServiceOffering` to `Branch` conceptually but never named the class responsible for enforcing that link. We assigned it to `ServiceOffering` as the Information Expert for its own branch coverage: `Branch.registerServiceOffering()` records which services a branch supports, `ServiceOffering.addCoveredBranch()` mirrors the association, and `ServiceOffering.isAvailableAt(branchId)` answers the question. `OrderProcessor.submitOrder()` calls this check before creating the `Order` and raises `InvalidDataException` when a customer selects a service their origin branch does not support, so an unsupported route can never reach the pricing or dispatch stages.

== Lifecycle, patterns, and dynamic constraints

We used the State pattern to enforce lifecycle rules so that illegal transitions are caught at the point of request rather than discovered later in corrupted data. Each lifecycle uses a polymorphic class hierarchy: concrete state subclasses override only the transitions they permit and inherit default rejection from the abstract base. Orders move from Submitted to Approved, Rejected (with reason), or Cancelled. Shipments progress strictly from Assigned to Picked Up to In Transit to Delivered, with no shortcuts. Invoices go from Unpaid to Partially Paid or Paid depending on the outstanding balance, and Payments go from Pending to Verified to Settled, or to Failed at any point before settlement. Any out-of-order transition throws an `InvalidDataException`. For example, a shipment cannot be marked Delivered without first passing through Picked Up and In Transit. An early bug during development confirmed this guard was worth the fifteen concrete State subclasses across the four hierarchies.

#figure(
  styled-table((1.7fr, 3.15fr, 4.1fr), (
    th[Pattern / GRASP principle], th[Concrete implementation], th[Reason and resulting constraint],
    [State], [Four abstract hierarchies with fifteen concrete subclasses (e.g. `OrderSubmittedState`, `ShipmentAssignedState`, `InvoiceUnpaidState`, `PaymentPendingState`)], [Moves rules out of large conditional controllers. Each state accepts only its legal next operation.],
    [Observer], [Listener interfaces for order approval, invoice creation, and shipment assignment], [Coordinates operational areas without a publisher referring to a concrete subscriber class.],
    [Strategy], [`IPaymentStrategy` (`CashPaymentStrategy` vs `GatewayPaymentStrategy`); `IPricingStrategy` / `PricingTariff`], [`PaymentProcessor` delegates cash and card processing through `IPaymentStrategy`. `IPricingStrategy` is defined for pluggable pricing but is not currently invoked polymorphically: `OrderProcessor` calls the concrete `PricingTariff.calculateQuote(distanceKm, totalWeightKg, isPeakPeriod)` directly (see Section 4.3).],
    [Adapter / Protected Variations], [`SimulatedGatewayAdapter` (implements `IPaymentGateway`), `ManualTelemetrySource` (implements `ITelemetrySource`)], [External systems are accessed through stable interfaces (`verifyTransaction()`, `stageLocation()`/`readLocation()`), allowing replacement with real integrations later.],
    [Creator / Information Expert], [Controllers create aggregates; entities/states own transition knowledge], [Construction occurs where inputs are available; invariant checks occur where knowledge resides.],
    [Indirection / Low Coupling], [`DataStore` and listener interfaces], [Controllers do not expose JDBC/SQL or concrete cross-controller dependencies to UI/domain layers.],
  )),
  caption: [Patterns and GRASP principles realised by the detailed design.],
) <tbl-pattern-grasp>

=== SQLite database design

`DataStore` is the persistence gateway, filling the role that Assumption A1 from Assignment 2 left open, while keeping domain models independent of database logic. It connects to the embedded SQLite database (`data/smartfm.db`) using the pinned Xerial JDBC driver. All database operations use prepared statements within explicit transactions.

When saving, `DataStore` atomically updates the normalized aggregate tables. When loading, it reconstructs domain objects, relationships, and state hierarchies in dependency order. The system checks the stored schema version on startup and rejects any version other than 3, requiring a database reset before the application will run.

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

The four sequence diagrams below show the main implemented use cases. Each diagram shows the controller methods that the GUI boundary calls. Section 5.1 maps these interactions to source code, and Section 5.2.1 provides execution evidence for each flow.

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
  caption: [UC-01 / UC-02: customer registration and order submission. The boundary sends each system event to `OrderProcessor`, which creates and validates domain objects and stages changes in `DataStore`; `GuiContext` commits them to SQLite after the successful UI action.],
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
  caption: [UC-03: dispatcher assigns a vehicle and driver to an approved order. `DispatchManager` checks dispatch constraints, stages the shipment and resource updates in `DataStore`, and notifies `ShipmentTracker`; after the successful controller call, `GuiContext` commits the mutation to SQLite.],
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

The core domain classes used in Assignment 2's daily workflows (Customer, Order, Consignment, Shipment, Vehicle, Driver, Branch, ServiceOffering, PricingTariff, Invoice, Payment, Receipt, SystemConfiguration, and the Person hierarchy) are in the final implementation with the same responsibilities. `SystemConfiguration` is discussed no further below because it carried over verbatim as the passive data-holder Assignment 2 specified: `Bootstrap` loads the single instance as its first internal startup step, after `DataStore` has been loaded by the GUI context, and nothing mutates it afterwards. The four State hierarchies and core interfaces (`IPaymentGateway`, `IPaymentStrategy`, `IPricingStrategy`, `ITelemetrySource`) were also kept. The additions are components that Assignment 2 deferred or left uncoordinated: `DataStore` for persistence, concrete adapters, `Bootstrap` for startup wiring, the `IdGenerator` helper (a utility omitted from the class views for space), listener interfaces, the UI boundary classes, and the `ReportProcessor` controller that Assignment 2's `Report` CRC card specified without an owner (Section 4.2). Table 1 in Section 2 lists every revision; the paragraphs below explain the reasoning for the main changes.

The main class-level change was clarifying and implementing the `Invoice` to `Payment` relationship as 1-to-Many. Assignment 2 did not clearly specify whether an invoice could have multiple payments; during implementation, a customer paying a 500-unit invoice with a 200-unit cash deposit followed by a 300-unit card payment exposed the missing multiplicity rule. The new `InvoicePartiallyPaidState` tracks the remaining balance across multiple `Payment` objects. Each `Payment` remains immutable once settled.

Features outside the four operational areas, such as authentication or role-based access (`StaffMember`, `StaffRole`, `SystemConfiguration`), remain in the domain model without UI bindings. We deferred these deliberately rather than deliver half-built features. The `Report` class and its coordinating controller `ReportProcessor` are fully implemented (Task T12) and exposed via the `ReportPanel` UI tab.

One clarification on the `Person` hierarchy: `StaffRole` includes a `DRIVER` value alongside the five back-office roles, which could look like a second, competing way to represent a driver next to the `Driver` subclass. It is not. `Driver`'s constructor passes `StaffRole.DRIVER` to `super(...)` unconditionally, so the role is derived from the concrete class rather than set independently, and the two representations cannot diverge. `Driver` remains the single source of driver identity (it alone owns `licenseNumber` and `dutyState`, per Assignment 2 Simplification #1); the enum value exists only so that `StaffMember.getRole()` returns a total function for every person in the system.

=== Responsibilities and collaborators

The responsibility split from Assignment 2 (entities own business rules, controllers coordinate workflows, boundaries handle I/O) carried over without change. The one new collaborator is `DataStore`, which controllers receive at construction time so domain entities stay persistence-agnostic.

The biggest responsibility-level refinement was replacing narrative observer callbacks with typed listener interfaces (`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener`). Assignment 2 also described notifications after shipment milestones, but the implementation does not publish milestone events: `ShipmentTracker` receives only `onShipmentAssigned(shipment)` and then handles pickup, transit, and delivery through explicit controller calls. In Assignment 2, we wrote that "DispatchManager subscribes to order events," but during coding that wording turned out to be ambiguous: did it mean automatic dispatch or just a notification? Defining narrow interfaces made the answer clear. `OrderProcessor` fires an event, `DispatchManager.onOrderApproved` receives the notification without auto-dispatching, and a human dispatcher must still call `assignShipment(...)` to allocate resources.

=== Dynamic aspects: bootstrap and interactions

Assignment 2 did not specify how the system starts up or when data is saved; those decisions were made during implementation.

On first launch, the GUI context calls `DataStore.loadFrom(...)`, which creates `data/smartfm.db` and builds all tables in a single transaction; on later launches it detects schema version 3 and reconstructs the persisted domain objects. The GUI context then constructs `Bootstrap`. When `Bootstrap.run()` begins, its first internal step is `SystemConfiguration.bootstrap()`, followed by seeding demonstration records when the branch store is empty. The seed data contains two branches, three vehicles, three drivers, one dispatcher staff member, three service offerings, and three pricing tariffs. `Bootstrap` then constructs all five controllers and registers event listeners among the four transactional ones in dependency-safe order; `ReportProcessor` needs no listener registration because it only reads state. For example, `DispatchManager` is registered as an `OrderApprovedListener` on `OrderProcessor` before any orders can be approved.

The GUI context calls `DataStore.saveTo(...)` after each successful user mutation, so changes made through the desktop application are committed immediately. Direct controller callers that do not use `GuiContext` must invoke the persistence boundary explicitly. The save operation is transactional: order approval updates the order and creates the invoice before notifying listeners, dispatch stages shipment and resource changes before firing `shipmentAssigned`, and payments generate a receipt only after settlement succeeds.

== Architecture style(s)

SmartFM uses two complementary architecture styles: a *Layered Architecture* for structural organisation and an *Event-Driven Architecture* for cross-subsystem communication. We chose this combination because a pure layered design would have forced `OrderProcessor` to call `DispatchManager` directly when an order is approved, creating tight coupling between two independent business areas. Adding event connectors at the application layer keeps the dispatch decision with the human operator while notifying the tracking subsystem automatically.

The system has five architectural components:
1. *Presentation:* `SmartFmMainFrame` and the Swing panel classes (`smartfm.ui.gui`).
2. *Order and Billing:* `OrderProcessor`, `PaymentProcessor`, and their domain entities.
3. *Fleet and Dispatch:* `DispatchManager`, `ShipmentTracker`, and their domain entities.
4. *Reporting:* `ReportProcessor` and its `Report` aggregation across the other components' entities.
5. *Persistence:* The `DataStore` database gateway.

These components communicate through two connector types. *Synchronous downward calls* follow the layer ordering: UI views call controller methods, controllers coordinate domain entities and stage changes through `DataStore`, and `GuiContext` invokes the transactional save boundary. *Event connectors* operate within the application layer: order approval, invoice creation, and shipment assignment publish events through narrow listener interfaces, so no publisher needs to know which concrete class handles the event.

Three architectural constraints enforce these rules:
1. Domain classes never import presentation or application packages (verified by the package structure).
2. `DataStore` is the only JDBC boundary. Controllers and `GuiContext` use its public persistence methods; UI panels and domain classes never touch JDBC directly.
3. Event publishers depend only on listener interfaces, not on concrete subscriber classes.

#figure(
  scale(x: 75%, y: 75%, reflow: true, mermaid("
flowchart TB
    subgraph PL[Presentation Layer]
        P[Presentation component<br/>SmartFmMainFrame + six Swing panels]
    end
    subgraph AL[Application Layer]
        OB[Order and Billing component<br/>OrderProcessor, PaymentProcessor]
        FD[Fleet and Dispatch component<br/>DispatchManager, ShipmentTracker]
        RP[Reporting component<br/>ReportProcessor]
    end
    subgraph DL[Domain Layer]
        DOM[Domain entities, four state hierarchies,<br/>strategy and adapter interfaces]
    end
    subgraph IL[Infrastructure Layer]
        DS[Persistence component<br/>DataStore SQLite gateway]
    end

    P --> OB
    P --> FD
    P --> RP
    OB --> DOM
    FD --> DOM
    OB --> DS
    FD --> DS
    RP --> DS
    OB -.-> FD
  ")),
  caption: [Component-and-connector view of SmartFM’s layered and event-driven architecture. Solid arrows show synchronous calls; the dashed arrow shows the order-approved event connector.],
) <fig-architecture-components>

= Design Quality (Discussion of Assignment 2 Design)

This section compares the Assignment 2 design with the Java we shipped: what carried over, what we had to invent, and where the original model was wrong.

== Good aspects of the Assignment 2 design

Several parts of the Assignment 2 design mapped into Java with little reinterpretation:

1. The CRC cards for the GRASP Controllers lined up almost one-to-one with controller methods. `OrderProcessor`'s CRC responsibilities became `registerCustomer()`, `submitOrder()`, and `approveOrder()` with almost no redesign, which kept those classes cohesive.
2. The lifecycle state tables were the design artifact we used most. Each matrix row became a GoF `State` subclass (`OrderSubmittedState`, `ShipmentInTransitState`), so illegal-transition checks and the matching unit tests were mostly mechanical to write.
3. Specifying Adapter interfaces early meant we could ship `SimulatedGatewayAdapter` for development and later swap in a real banking gateway without editing `PaymentProcessor`.
4. Observer events kept the application controllers from taking hard compile-time dependencies on each other. Order approval notifies `PaymentProcessor` through `InvoiceCreatedListener` without `OrderProcessor` naming that class.
5. Domain entities stay free of UI and JDBC imports. Presentation code talks only to application controllers, which matches the Low Coupling and High Cohesion intent from GRASP.

== Missing aspects from the original design

Assignment 2 left several implementation details open on purpose. During coding we still had to fill these gaps:

1. Persistence was deferred under Assumption A1, so the SQLite schema, SQL, and the transactional `DataStore` gateway had no design counterpart.
2. Entity attributes were named, but input validation was not. We defined phone and email regexes, non-negative cargo weight limits, and non-blank name checks in `smartfm.common.Validators`.
3. The UI boundary was deferred, so we designed the Swing desktop GUI (`smartfm.ui.gui`) from scratch, including inline banners (`ResultBanner`, `ValidatedField`) and form reset behaviour.
4. Startup wiring was missing. `Bootstrap` seeds branches, vehicles, drivers, and service offerings into SQLite when the database is first created.
5. Interface contracts (`IPaymentGateway`, `ITelemetrySource`) existed, but concrete simulation behaviour did not. `SimulatedGatewayAdapter` returns deterministic authorization codes; `ManualTelemetrySource` formats GPS coordinate strings.

== Flawed aspects of the original design

Coding also exposed problems in the Assignment 2 model itself:

1. Assignment 2 said `DispatchManager` "subscribes to order approval events." We first read that as automatic vehicle dispatch, which conflicts with the SRS rule that a human dispatcher assigns resources. It took two team discussions to settle that the event only notifies; `assignShipment(...)` remains a separate, explicit call.
2. The Invoice-to-Payment multiplicity was underspecified. A partial-payment case (200 cash, then 300 card against a 500-unit invoice) forced the issue. We made the association 1-to-Many and added `InvoicePartiallyPaidState`.
3. The UML showed a pricing Strategy abstraction, but the `ServiceOffering` CRC card never clearly owned pricing delegation. In the running code, `OrderProcessor` calls `PricingTariff.calculateQuote()` directly, so the strategy indirection is unused.
4. Persistence timing was deferred. We decided that `GuiContext` saves `DataStore` after each successful UI mutation, while direct controller callers must call `saveTo(...)` themselves; each save stays transactional.

== Level of interpretation required

Overall, Assignment 2 needed a moderate amount of interpretation:

- Low interpretation (already well specified): domain entity shapes, State transition tables, GRASP Controller method boundaries, and Adapter interface contracts. These translated to Java with almost no ambiguity.
- High interpretation (we had to decide while coding):
  - Whether to auto-commit after each UI transaction or buffer writes until exit.
  - Regex validation rules and how form controls surface errors.
  - Stub behaviour for the payment gateway and telemetry source.
  - Whether an observer notification should run a use case automatically or only update a pending queue for a human operator.

== Lessons learnt

Building SmartFM showed us where our Assignment 2 design held up well and where our assumptions fell apart once we wrote real code.

*Specify Observer semantics and GRASP Controller boundaries precisely.* The State pattern lifecycle tables were our most effective design artifact because each row defined exact transition rules, making `OrderState` and `ShipmentState` implementation straightforward. By contrast, the Observer pattern descriptions were vague. The event description for `OrderApprovedListener` left it unclear whether `DispatchManager` (our GRASP Application Controller) should assign vehicles automatically upon notification or wait for explicit input from the Presentation Layer. This ambiguity took two days of team debate to resolve. Next time, we would define event triggers, payload contracts, and controller boundaries before writing code.

*Test domain multiplicities against realistic use cases.* Sequence diagrams help catch structural mistakes early, but only if you trace edge cases through them. Assignment 2 did not make the Invoice-Payment multiplicity explicit, and a partial-payment scenario (a 200-unit cash deposit followed by a 300-unit card payment) exposed that omission. Tracing the multi-payment scenario through `Invoice` (the Information Expert for billing balances) made the need for a 1-to-Many relationship and `InvoicePartiallyPaidState` clear.

*Keep design patterns connected in runtime code.* We created `IPricingStrategy` and `PricingTariff` to handle pricing variations (applying Strategy and Protected Variations). But in the running code, `OrderProcessor` calls `PricingTariff.calculateQuote()` directly instead of delegating through `ServiceOffering` (the Information Expert for branch offerings). A pattern that exists on a class diagram but gets bypassed in code adds indirection without providing value. Future designs should either route calls all the way through or explicitly state why delegation is deferred.

*Define persistence contracts and layer boundaries early.* Deferring UI and persistence details made sense for a high-level Assignment 2 design, but it left architectural boundaries unmapped. Building the Infrastructure Layer (`DataStore` as a Pure Fabrication gateway) meant inventing transaction boundaries, schema versioning, and validation rules in `smartfm.common.Validators` while already writing code. A short layered architecture note (Presentation -> Application -> Domain -> Infrastructure) written during Assignment 2 would have cut that guesswork.

*Use automated tests to enforce architectural rules.* The 82 JUnit 5 tests across 18 test classes caught regressions while we refactored. Edits to `DataStore` SQL or additions like `ReportProcessor` were checked against domain state rules and controller workflows on the next `mvn test`. Java 26 also forced a practical runtime detail: SQLite JDBC needs `--enable-native-access=ALL-UNNAMED` to load native libraries, which we put in the Makefile.

= Implementation and Testing

== Mapping design to code

SmartFM is implemented in Java 26 under a standard Maven layout. The design elements and sequence diagrams map to the source paths listed below.

*Coding standards and metrics:* The codebase follows the Google Java Style Guide @google2023javastyle: standard naming, explicit control blocks, and short Javadoc. Sources compile with zero lint warnings under `javac -Xlint:all`. Correctness is checked by 82 JUnit 5 test executions across 18 test classes (including parameterized cases), covering domain states, event pipelines, SQLite persistence, and Swing GUI behaviour. All tests pass.

*Development environment:* Development was on Windows 11 with IntelliJ IDEA, PowerShell 7.6, and OpenJDK 26.0.2. The app needs Java 26 and the JARs under `lib/`. It runs locally with no external database server. Builds work with Maven, GNU Make, or plain `javac`.

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
    [T12: Generate Reports], [Full (functional)], [Implemented via `ReportProcessor` and `ReportPanel` across financial, fleet, branch, and commercial order metrics. Functionally complete; automated metric assertions pass, but no scripted GUI acceptance scenario is included (see Section 5.3).],
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
    [`src/main/java/smartfm/domain/`], [Seven domain sub-packages owning entities, lifecycle state hierarchies, strategy/adapter contracts, `Report` (`domain/report`), and `SystemConfiguration` (`domain/catalog`).],
    [`src/test/java/smartfm/`], [JUnit 5 unit, integration, and E2E test suite covering all layers.],
    [`src/main/java/smartfm/application/`], [Four core GRASP Controllers plus `ReportProcessor`, observer interfaces, bootstrap, and ID generation.],
    [`src/main/java/smartfm/infrastructure/`], [The `DataStore` SQLite persistence gateway.],
    [`src/main/java/smartfm/ui/`, `src/main/java/smartfm/ui/gui/`], [Swing desktop GUI presentation layer over application controllers.],
    [`tools/java/`], [GUI screenshot automation driver.],
  )),
  caption: [Standard project layout and package organisation.],
) <tbl-project-layout>

== Compilation and Execution

*Prerequisites:* Building and running the application requires JDK 26 (e.g., OpenJDK 26.0.2). SQLite is embedded via JDBC (`lib/sqlite-jdbc-3.46.1.0.jar`), so no external database server, network setup, or database credentials are needed. Running on Java 26 requires the JVM flag `--enable-native-access=ALL-UNNAMED` for SQLite JDBC native library loading.

*Step-by-step setup and execution guide for external evaluators:*

1. *Extract the submission package:* Unzip the project files to a local directory on any Windows, macOS, or Linux machine with JDK 26 installed.
2. *Compile and run tests:* Open a terminal in the `implementation/` directory and execute `mvn test`. This runs Checkstyle in the Maven `validate` phase (0 violations) and executes all 82 automated JUnit 5 tests. `make compile` is available if you only want to compile the sources with `-Xlint:all`.
3. *Launch the GUI application:* Execute `make run` (or build the executable shaded JAR via `mvn package` and run `java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar`). The SmartFM desktop interface will launch on the first of six tabs, "Register Customer", followed by "1. Order Management", "2. Fleet Dispatch", "3. Shipment Tracking", "4. Billing and Payment", and "5. Reports".
4. *Reset demonstration data (optional):* State is persisted locally in `data/smartfm.db`. To reset the system to its initial seeded state (2 branches, 3 vehicles, 3 drivers, 1 dispatcher, 3 service offerings, 3 pricing tariffs), execute `make reset` or delete `data/smartfm.db*`.

*Build tool options summary:*

*Option A: Maven Build & Execution (Recommended)*

+ `mvn test`: validates Checkstyle (0 errors) and runs all 82 JUnit 5 tests.
+ `mvn package`: compiles and packages the self-contained executable JAR in `target/`.
+ `java --enable-native-access=ALL-UNNAMED -jar target/smartfm.jar`: launches the packaged application.

*Option B: GNU Make Shortcuts*

+ `make compile`: compiles Java sources with `-Xlint:all` to `target/classes`.
+ `make run`: launches the desktop GUI.
+ `make reset`: cleans compiled classes and resets SQLite database state.

#figure(
  image("images/compilation.png", width: 95%),
  caption: [Compilation and test execution evidence: console transcript of `mvn clean package`, showing 0 Checkstyle violations, all 82 automated JUnit 5 tests passing across the 18 test classes, and the self-contained executable JAR being packaged. Absolute project paths are abbreviated to `<project>`.],
) <fig-compilation>

=== GUI execution screenshots

The screenshots below come from `tools/java/smartfm/ui/gui/ScreenshotDriver.java`, which drives the GUI and captures the window for each scenario. The figures show the home screen, valid and invalid input paths, successful outputs, and the state just before exit.

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/00_home_screen_empty.png", width: 100%),
    image("images/01b_customer_registration_validation_errors.png", width: 100%),
  ),
  caption: [Empty customer-registration home screen (left) and rejected invalid phone/email input with inline messages (right).],
) <fig-gui-empty-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/02a_order_management_empty.png", width: 100%),
    image("images/02b_order_management_invalid_weight.png", width: 100%),
  ),
  caption: [Empty Order Management tab at the start of Scenario 02 (left); a negative consignment weight is rejected before the consignment is added (right).],
) <fig-gui-order-empty-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("images/01c_customer_registration_success.png", width: 100%),
    image("images/02f_order_management_order_cancelled.png", width: 100%),
  ),
  caption: [Accepted customer input and successful account creation (left); a customer change of mind cancels an order without deleting unrelated data (right).],
) <fig-gui-input-change>

#figure(
  image("images/02g_order_management_order_approved.png", width: 75%),
  caption: [Approval of order `ORD-0001` transitions it to Approved and creates invoice `INV-0001` with the quoted amount as its outstanding balance.],
) <fig-gui-order-approved>

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
    image("images/05b_billing_payment_exceeds_balance_rejected.png", width: 100%),
    image("images/05c_billing_payment_partial_success.png", width: 100%),
  ),
  caption: [A payment above the outstanding balance is rejected before any `Payment` object is created (left); an accepted partial cash deposit moves the invoice to Partially Paid and leaves the remaining balance outstanding (right).],
) <fig-gui-payment-validation-partial>

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

System testing covers compiler linting, automated unit and integration tests, scenario-based acceptance runs, and persistence checks.

*Automated testing:* `mvn test` runs 82 JUnit 5 executions from `src/test/java/smartfm/`, across 18 test classes with 71 written methods (four `@ParameterizedTest` methods expand into multiple cases). Coverage includes:
1. *Common layer:* currency formatting, timestamps, and field validators (`MoneyTest`, `ValidatorsTest`).
2. *Domain layer:* entity invariants, cargo aggregation, state transitions, receipt issuance, and pricing tariffs.
3. *Application layer:* event dispatch, shipment creation, resource allocation, and payment settlement on the four transactional controllers, plus per-metric report assertions, category dispatch, and date-range filtering (`ReportProcessorTest`; see note below).
4. *Infrastructure layer:* save and reload of normalized aggregates in SQLite (`DataStoreTest`).
5. *Core E2E workflows:* registration through payment settlement and database recovery (`SmartFmEndToEndTest`).
6. *Swing GUI E2E:* Event Dispatch Thread coverage of validation errors, dispatch, and window closure (`SmartFmGuiEndToEndTest`).
7. *GUI persistence:* SQLite save after UI mutations (`GuiContextAndPersistenceTest`).
8. *Coverage helpers:* GUI component events and edge-case form input (`SmartFmGuiCoverageTest`).

All 82 executions finish in under 5 seconds with zero failures.

*Note on reporting coverage:* Table 7 marks T12 as "Full (functional)" because all four report categories generate correctly in `ReportPanel`. `ReportProcessorTest` adds automated metric checks but there is no separate scripted GUI acceptance scenario. Those six tests drive state through the transactional controllers first, then assert individual metrics: billed, collected, and outstanding amounts by invoice state; vehicle, driver, and shipment-state counts before and after delivery; branch-scoped versus all-branch resource counts; order-state and freight totals; category dispatch including the financial fallback; and date-range filtering. Reporting is absent from @tbl-scenario-summary because it only reads state.

*Scenario-based acceptance testing:* The five scenarios below exercise the core use cases, including both valid and invalid inputs, state transitions, and persistence.

#figure(
  styled-table((1.1fr, 1.8fr, 2.7fr, 3.1fr), (
    th[Scenario], th[Use Case / Area], th[User Entry & Verification Path], th[Evidence & Outcome],
    [01 Customer], [Customer Registration (UC-01)], [Enter details. Invalid phone/email is rejected; valid input creates customer record.], [Customer `CUS-0001` created (@fig-gui-empty-validation, @fig-gui-input-change).],
    [02 Order], [Order Management (UC-02)], [Select customer/route. Negative cargo weight is rejected (@fig-gui-order-empty-validation); submitted order can be cancelled or approved.], [`ORD-0002` cancelled (@fig-gui-input-change); approving `ORD-0001` creates invoice `INV-0001` (@fig-gui-order-approved).],
    [03 Dispatch], [Fleet Dispatch (UC-03)], [Select approved order and compatible vehicle/driver. Missing order selection is rejected.], [Shipment `SHP-0001` created (@fig-gui-dispatch-tracking-validation).],
    [04 Tracking], [Shipment Tracking (UC-04)], [Record milestones. Delivery before pickup is rejected by State pattern; sequential progress succeeds.], [Delivered state achieved (@fig-gui-completion).],
    [05 Payment], [Billing & Payment (UC-05)], [Select invoice and amount. Overpayment is rejected and a partial cash deposit is accepted (@fig-gui-payment-validation-partial); card settlement clears the balance.], [Receipt issued, invoice Paid (@fig-gui-completion).],
  )),
  caption: [Scenario instructions, validation paths, and execution evidence.],
) <tbl-scenario-summary>



After Scenario 05, `data/smartfm.db` holds two customers, two orders (`ORD-0001` Approved, `ORD-0002` Cancelled), one delivered shipment, one paid invoice with a zero outstanding balance, two settled payments (cash and card), and two receipts. The schema is version 3 with foreign keys enabled. Starting the application again confirms that state survives a separate process run.

= Conclusion

The Assignment 2 design survived implementation more intact than we expected. Core entities, State hierarchies, and controller responsibilities mostly kept their original shape. Where we did change things (adding `DataStore`, replacing narrative observer callbacks with typed listeners, and opening Invoice-Payment to 1-to-Many), a concrete coding problem forced the change rather than a desire for a neater diagram.

The finished system compiles with zero lint warnings, passes all 82 automated test executions, and runs the four transactional workflows plus Task T12 reporting through the Swing GUI. Features we left out, such as service browsing and vehicle CRUD, can sit on the existing layers later. Next time we would lock down persistence timing, UI sketches, and a few edge-case walkthroughs earlier in the design phase; those were the gaps that cost us the most interpretation time.

= References

#bibliography("refs.bib", title: none, style: "harvard-cite-them-right")

= Appendices

== Appendix A: Assignment 2 Object Design (Complete Submission) <appendix-asm2>

Our full Assignment 2 Object Design submission is attached below. Any mention of Assignment 2 in this report, such as the lifecycle table or Assumption A1, points to this document.

#counter("appendix").update(1)
#colbreak()

#for page-num in range(1, 34) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm2.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}
