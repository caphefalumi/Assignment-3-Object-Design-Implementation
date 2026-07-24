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
    edge((1, 2.1), (3, 2.1), "->", label: "3: stage customer in aggregate", label-pos: .5)
    edge((0, 2.8), (1, 2.8), "->", label: "4: submitOrder(customer, consignments)", label-pos: .5)
    edge((1, 3.35), (2, 3.35), "->", label: "5: create Consignment(s) and Order", label-pos: .5)
    edge((1, 3.9), (3, 3.9), "->", label: "6: stage order; return id", label-pos: .5)
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
    edge((1, 1.55), (2, 1.55), "->", label: "2: verify approved / available / branch / capacity", label-pos: .5)
    edge((1, 2.1), (2, 2.1), "->", label: "3: create Shipment; allocate resources", label-pos: .5)
    edge((1, 2.65), (3, 2.65), "->", label: "4: stage shipment and resource updates", label-pos: .5)
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
    edge((1, 3.2), (3, 3.2), "->", label: "5: stage accepted status and location", label-pos: .5)
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
    edge((1, 3.2), (3, 3.2), "->", label: "5: settle, issue Receipt, stage aggregate", label-pos: .5)
  }
)

#outline(title: [Table of Contents])
#colbreak()

#heading(level: 1, numbering: none)[Introduction]

The Smart Fleet Management System (SmartFM) handles customer registration, order placement, dispatch, shipment tracking, billing, payment, and receipt generation. Assignment 2 defined the system's high-level design, CRC responsibilities, lifecycle states, and design patterns. This report presents the running Java 26 implementation built from that design and evaluates the architectural decisions made during development.

The report is organized as follows: Section 1 outlines revisions to Assignment 2; Section 2 details the class design and sequence diagrams; Section 3 evaluates design quality; Section 4 summarizes lessons learned; Section 5 details the architectural style; and Section 6 provides code mappings, build instructions, test results, and execution evidence. The full Assignment 2 submission is attached in Appendix A.

The implemented system covers four core operational areas: Order Management, Fleet Dispatch, Shipment Tracking, and Billing and Payment. Both a Swing graphical user interface (GUI) and a command-line interface (CLI) run on top of the same application controllers. The GUI serves as the primary interface, while the CLI provides repeatable scenario scripts for verification.

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
    [A2 Invoice–Payment 1-to-1 assumption], [Partial payments require multiple payments per invoice.], [Updated relationship to 1-to-Many with `InvoicePartiallyPaidState`.], [Supported partial cash/card payment scenarios.],
    [A2 ServiceOffering–Branch conceptual link], [Branch availability check was not enforced during order entry.], [Added `Branch.registerServiceOffering()`; origin branch check deferred.], [Documented as a minor scope boundary in Section 3.2.],
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



#let uml-box(pos, name, stereotype: none, attributes: (), methods: (), width: 3.1cm, fill: rgb("#f0f4f8")) = node(
  pos,
  rect(
    width: width, stroke: .65pt + rgb("#1a3a5c"), radius: 2pt, fill: fill, inset: 0pt,
    stack(
      dir: ttb,
      rect(width: 100%, fill: rgb("#1a3a5c"), inset: (x: 2pt, y: 2.2pt), radius: (top: 2pt))[
        #align(center)[
          #if stereotype != none [#text(size: 4.5pt, fill: white, font: "Consolas")[«#stereotype»\ ]]
          #text(size: 5.5pt, weight: "bold", fill: white)[#name]
        ]
      ],
      if attributes.len() > 0 [
        #rect(width: 100%, stroke: (bottom: .35pt + rgb("#1a3a5c")), inset: (x: 2.5pt, y: 1.5pt))[
          #align(left)[
            #set text(size: 4.2pt, font: "Consolas")
            #for attr in attributes [ #attr \ ]
          ]
        ]
      ],
      if methods.len() > 0 [
        #rect(width: 100%, stroke: none, inset: (x: 2.5pt, y: 1.5pt))[
          #align(left)[
            #set text(size: 4.2pt, font: "Consolas")
            #for m in methods [ #m \ ]
          ]
        ]
      ]
    )
  ),
  stroke: none, fill: none
)

#let final-class-model() = diagram(
  spacing: (2.3cm, 1.1cm),
  {
    // Row 0: Controllers & Infrastructure
    uml-box((0, 0), "OrderProcessor", stereotype: "controller",
      attributes: ("- store: DataStore", "- listeners: List"),
      methods: ("+ registerCustomer(...)", "+ submitOrder(...)", "+ approveOrder(id)"))
    uml-box((1, 0), "DispatchManager", stereotype: "controller",
      attributes: ("- store: DataStore"),
      methods: ("+ assignShipment(...)", "+ onOrderApproved(...)"))
    uml-box((2, 0), "ShipmentTracker", stereotype: "controller",
      attributes: ("- store: DataStore", "- telemetry: ITelemetrySource"),
      methods: ("+ recordMilestone(...)", "+ recordDelivery(...)"))
    uml-box((3, 0), "PaymentProcessor", stereotype: "controller",
      attributes: ("- store: DataStore", "- gateway: IPaymentGateway"),
      methods: ("+ submitPayment(...)"))
    uml-box((4, 0), "DataStore", stereotype: "infrastructure", fill: rgb("#fff4db"),
      attributes: ("- conn: Connection", "- version: int = 3"),
      methods: ("+ load()", "+ save()", "+ customers()", "+ orders()"))

    // Row 1: Core Domain Entities
    uml-box((0, 1), "Customer",
      attributes: ("- id: String", "- fullName: String", "- phone: String"),
      methods: ("+ recordOrder(id)"))
    uml-box((1, 1), "Order",
      attributes: ("- id: String", "- state: OrderState", "- quotedAmount: double"),
      methods: ("+ approve()", "+ cancel()", "+ addConsignment(...)"))
    uml-box((2, 1), "ServiceOffering",
      attributes: ("- id: String", "- name: String", "- tariffId: String"),
      methods: ("+ isAvailableAt(branchId)"))
    uml-box((3, 1), "Branch",
      attributes: ("- id: String", "- name: String", "- city: String"),
      methods: ("+ addVehicle(...)", "+ addDriver(...)"))
    uml-box((4, 1), "Invoice",
      attributes: ("- id: String", "- amount: double", "- state: InvoiceState"),
      methods: ("+ recordPayment(...)", "+ isSettled()"))

    // Row 2: Secondary Domain & Resources
    uml-box((0, 2), "Consignment",
      attributes: ("- id: String", "- weightKg: double", "- desc: String"),
      methods: ("+ getWeightKg()"))
    uml-box((1, 2), "Shipment",
      attributes: ("- id: String", "- state: ShipmentState", "- location: String"),
      methods: ("+ pickup()", "+ deliver()", "+ updateLocation(...)"))
    uml-box((2, 2), "Vehicle",
      attributes: ("- id: String", "- capacityKg: double", "- status: String"),
      methods: ("+ assignToShipment()"))
    uml-box((3, 2), "Driver",
      attributes: ("- licenseNo: String", "- dutyState: DutyState"),
      methods: ("+ setDutyState(...)"))
    uml-box((4, 2), "Payment",
      attributes: ("- id: String", "- amount: double", "- state: PaymentState"),
      methods: ("+ settle()"))

    // Row 3: Support, Abstractions & Governance
    uml-box((0, 3), "Person / StaffMember", stereotype: "abstract",
      attributes: ("- id: String", "- fullName: String", "- role: StaffRole"),
      methods: ("+ getRole()"))
    uml-box((1, 3), "Receipt",
      attributes: ("- id: String", "- paymentId: String", "- issuedAt: DateTime"),
      methods: ("+ getFormattedReceipt()"))
    uml-box((2, 3), "OrderState / ShipmentState", stereotype: "abstract",
      attributes: ("- stateName: String"),
      methods: ("+ approve()", "+ pickup()", "+ deliver()"))
    uml-box((3, 3), "PricingTariff / IPricingStrategy", stereotype: "strategy",
      attributes: ("- baseRate: double", "- kmRate: double"),
      methods: ("+ calculateQuote(...)"))
    uml-box((4, 3), "ITelemetrySource / Adapter", stereotype: "adapter",
      attributes: ("- locations: Map"),
      methods: ("+ recordMilestone()", "+ getLatestCoordinates()"))

    // Connections with labels and multiplicities
    edge((0, 0), (0, 1), "->", label: "1", label-pos: .2, stroke: .7pt + rgb("#1a3a5c"))
    edge((0, 0), (1, 1), "->", label: "1", label-pos: .2, stroke: .7pt + rgb("#1a3a5c"))
    edge((1, 0), (1, 2), "->", label: "1", label-pos: .2, stroke: .7pt + rgb("#1a3a5c"))
    edge((2, 0), (1, 2), "->", label: "1", label-pos: .2, stroke: .7pt + rgb("#1a3a5c"))
    edge((3, 0), (4, 2), "->", label: "1", label-pos: .2, stroke: .7pt + rgb("#1a3a5c"))
    edge((0, 1), (1, 1), "->", label: "1..*", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 1), (0, 2), "->", label: "1..*", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 1), (2, 1), "->", label: "1", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 1), (1, 2), "->", label: "0..1", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((3, 1), (2, 2), "->", label: "1..*", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((3, 1), (3, 2), "->", label: "1..*", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 2), (2, 2), "->", label: "1", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 2), (3, 2), "->", label: "1", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((4, 1), (4, 2), "->", label: "1..*", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((4, 2), (1, 3), "->", label: "1", label-pos: .8, stroke: .65pt + rgb("#1a3a5c"))
    edge((1, 1), (2, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((1, 2), (2, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((4, 1), (2, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((4, 2), (2, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((2, 1), (3, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((3, 0), (3, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((2, 0), (4, 3), "->", stroke: .55pt + rgb("#6d7f8f"), dash: "dashed")
    edge((0, 0), (4, 0), "->", stroke: .55pt + rgb("#c0392b"), dash: "dotted")
    edge((1, 0), (4, 0), "->", stroke: .55pt + rgb("#c0392b"), dash: "dotted")
    edge((2, 0), (4, 0), "->", stroke: .55pt + rgb("#c0392b"), dash: "dotted")
    edge((3, 0), (4, 0), "->", stroke: .55pt + rgb("#c0392b"), dash: "dotted")
  }
)
#figure(
  align(center, scale(73%, reflow: true, final-class-model())),
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

The State pattern enforces valid entity lifecycle transitions. Orders move from Submitted to Approved, Rejected, or Cancelled. Shipments move from Assigned through Picked Up and In Transit to Delivered. Invoices transition from Unpaid to Partially Paid or Paid. Payments move from Pending through Verified to Settled or Failed. Out-of-order state transitions throw an `InvalidDataException`, preventing invalid data from being saved.

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

`DataStore` serves as the persistence gateway, fulfilling Assumption A1 from Assignment 2 while keeping domain models independent of database logic. It connects to the embedded SQLite database (`data/smartfm.db`) using the pinned Xerial JDBC driver. All database operations use prepared statements within explicit transactions.

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

The four sequence diagrams below illustrate the core implemented use cases. Each diagram shows the exact controller methods invoked by the GUI and CLI boundaries. Section 6.1 maps these interactions directly to source code, and Section 6.3 provides execution evidence for each flow.

#figure(
  align(center, sequence-order()),
  caption: [UC-01 / UC-02: customer registration and order submission. The boundary sends each system event to `OrderProcessor`; it creates and validates domain objects, then stages them in the shared aggregate for the UI boundary to commit on a clean exit.],
) <fig-seq-order>

#figure(
  align(center, sequence-dispatch()),
  caption: [UC-03: dispatcher assigns a vehicle and driver to an approved order. `DispatchManager` checks the dispatch constraints, updates the shared aggregate, and notifies `ShipmentTracker`; the UI/CLI boundary commits the aggregate on a clean exit.],
) <fig-seq-dispatch>

#figure(
  align(center, sequence-tracking()),
  caption: [UC-04: tracking a shipment milestone. The adapter normalises location input, while `ShipmentState` decides whether the requested transition is legal.],
) <fig-seq-tracking>

#figure(
  align(center, sequence-payment()),
  caption: [UC-05: billing and payment. `PaymentProcessor` validates the amount before strategy/gateway processing; a receipt is issued only after settlement.],
) <fig-seq-payment>

#heading(level: 2, numbering: none)[2.5 Justification of changes and non-changes]

#heading(level: 3, numbering: none)[2.5.1 Class-level changes and non-changes]

The fourteen core domain classes from Assignment 2 remain unchanged in responsibility, including `Customer`, `Order`, `Consignment`, `Shipment`, `Vehicle`, `Driver`, `Branch`, `ServiceOffering`, `PricingTariff`, `Invoice`, `Payment`, `Receipt`, and the `Person` inheritance hierarchy. The four State hierarchies and core interfaces (`IPaymentGateway`, `IPaymentStrategy`, `IPricingStrategy`, `ITelemetrySource`) were also preserved. The implementation adds only previously deferred components: `DataStore`, concrete adapters, `Bootstrap`, listener interfaces, and UI boundary classes.

One key refinement changed the relationship between `Invoice` and `Payment`. The original SRS specified a 1-to-1 relationship. To support partial payments (such as a cash deposit followed by a card payment), this was updated to a 1-to-Many relationship. An `Invoice` tracks multiple payment IDs, while `InvoicePartiallyPaidState` manages the remaining balance. Settled `Payment` objects remain immutable.

Features outside the four operational areas were deferred. The `Report` class remains in the design model but is not implemented. Similarly, authentication and role-based access control classes (`StaffMember`, `StaffRole`, `SystemConfiguration`) remain as domain support without UI bindings.

#heading(level: 3, numbering: none)[2.5.2 Responsibilities and collaborators]

The original responsibility assignments remain intact: entities enforce business rules, controllers coordinate workflows, and UI boundaries handle user interaction. Controllers now receive `DataStore` as a collaborator to manage persistence without cluttering domain entities.

Narrative observer callbacks were replaced with explicit listener interfaces (`OrderApprovedListener` and `InvoiceCreatedListener`). As a result, `OrderProcessor` no longer depends directly on concrete dispatch or payment classes. When `OrderProcessor` approves an order, `DispatchManager.onOrderApproved` flags the order as ready, but resource allocation requires an explicit `assignShipment` call by a dispatcher.

#heading(level: 3, numbering: none)[2.5.3 Dynamic aspects: bootstrap and interactions]

System startup is managed through `Bootstrap` and `DataStore`. During initialization, `DataStore` checks `data/smartfm.db` and verifies that the schema matches version 3.

On the first launch, `DataStore` runs a transaction to create all database tables and seed initial records for branches, vehicles, drivers, and service offerings. On subsequent launches, it skips seeding and loads existing domain entities directly from SQLite. Once `DataStore` is ready, `Bootstrap` creates the four controllers and registers their event listeners.

Data persistence happens automatically during runtime. UI and CLI actions save aggregate changes to SQLite after state mutations and upon exit. During order approval, the system updates the order and invoice before notifying listeners. Dispatch updates shipment and resource allocations before firing `shipmentAssigned`. Payments generate a receipt only after successful settlement. These interactions correspond directly to the sequence diagrams in Section 2.4.

#heading(level: 1, numbering: none)[#text("3. Design Quality")]

#heading(level: 2, numbering: none)[3.1 Good aspects of the Assignment 2 design]

The CRC responsibilities from Assignment 2 translated cleanly into implementation. Each business operation maps to a clear controller entry point. Defining lifecycle tables early made it straightforward to build concrete State classes and test invalid state transitions. Design patterns like Strategy, Adapter, and Observer successfully isolated external concerns such as payment gateways and telemetry.

The implementation maintains high cohesion and low coupling. Responsibilities are divided cleanly across the four controllers: order processing in `OrderProcessor`, vehicle allocation in `DispatchManager`, shipment tracking in `ShipmentTracker`, and payment handling in `PaymentProcessor`. Coupling remains low because the UI layers depend on controller interfaces, and event publishers communicate through abstract listeners.

#heading(level: 2, numbering: none)[3.2 Missing or ambiguous aspects]

The original design excluded UI and persistence details. While appropriate for Assignment 2, this required defining input validation, error handling, database persistence, and initialization logic during implementation. Concrete implementations for payment gateway and telemetry adapters were also added.

The main design ambiguity involved `DispatchManager` reacting to approved orders. Automatic dispatch contradicted the requirement for human dispatchers to select vehicles and drivers. The revised design maintains event notifications but requires an explicit dispatch call.

Three minor implementation gaps remain:

1. *Branch service validation:* `Branch.registerServiceOffering()` tracks available services, but `OrderProcessor` does not check if an order's origin branch supports the chosen service. Enforcing this requires branch-filtered selection lists across the UI.
2. *Pricing Strategy wiring:* The `IPricingStrategy` interface and `PricingTariff` class exist, but `OrderProcessor` calls `PricingTariff.calculateQuote()` directly instead of delegating through `ServiceOffering`. The strategy structure remains available for future pricing models.
3. *SRS task scope:* Of the fifteen SRS tasks (T1–T15), eight are fully implemented (T1, T3–T9) and one is partially implemented (T14 supports cancellation but not order modifications). Six administrative tasks (T2, T10–T13, T15) were deferred, meeting the brief requirement to cover at least four business areas.

#heading(level: 2, numbering: none)[3.3 Flaws or errors in the initial design]

The primary design flaw was the contradiction between automatic and manual dispatch. Assignment 2 implied that order approval automatically triggered dispatch, whereas operational rules require a dispatcher to assign resources manually. A second limitation was omitting a persistence interface, leaving startup and save strategies undefined until implementation.

A third flaw was the SRS 1-to-1 restriction between `Invoice` and `Payment`. This blocked standard partial-payment workflows, such as paying a deposit in cash and settling the rest by card. Updating this to a 1-to-Many relationship solved the issue.

Finally, Assignment 2 stated that `ServiceOffering` delegated to `IPricingStrategy`, but the method calls were not wired into `ServiceOffering`. Controllers call `PricingTariff` directly instead.

#heading(level: 2, numbering: none)[3.4 Level of interpretation required]

The Assignment 2 design required moderate interpretation during coding. Core domain entities, State transitions, and controller roles were clearly defined and implemented directly. Interpretation was mainly needed for UI field validation, SQLite persistence, adapter implementations, and manual dispatch workflows. Table 1 and Section 2.5 document these choices.

#heading(level: 1, numbering: none)[#text("4. Lessons Learnt")]

First, state transitions and operational workflows must be fully specified before writing code. Detailed State tables prevented logic errors during implementation, whereas ambiguous observer callbacks required manual resolution.

Second, domain multiplicity assumptions should be validated early. The SRS 1-to-1 rule for invoices and payments proved too restrictive for partial payments. In financial domains, supporting 1-to-Many relationships is usually necessary.

Third, design patterns must be fully wired to provide value. The `IPricingStrategy` interface was implemented but not connected to `ServiceOffering`. Reviewing pattern interactions during design would have identified this gap earlier.

Fourth, modern runtimes require early test automation and environment configuration. Building JUnit tests, Swing GUI tests on the Event Dispatch Thread (EDT), and automated screenshot drivers made verifying state transitions straightforward. Working with Java 26 and SQLite JDBC also required configuring native access flags (`--enable-native-access=ALL-UNNAMED`) to ensure stable database operations.

Future object-oriented designs should specify basic persistence contracts and UI sketches early. Observer relationships should distinguish human notifications from automated actions, and pattern connections should be verified before coding starts.

#heading(level: 1, numbering: none)[#text("5. Architecture Style(s)")]

SmartFM combines a Layered Architecture Style for structural organization with an Event-Driven Architecture Style for subsystem communication.

The system consists of four primary components:
1. *Presentation:* `SmartFmConsoleApp`, `SmartFmMainFrame`, and Swing panels.
2. *Order and Billing:* `OrderProcessor`, `PaymentProcessor`, and associated domain entities.
3. *Fleet and Dispatch:* `DispatchManager`, `ShipmentTracker`, and associated domain entities.
4. *Persistence:* `DataStore` database gateway.

Communication relies on two connector types. Downward calls execute synchronously: UI views call controller methods, controllers coordinate domain entities, and controllers invoke `DataStore`. Event connectors operate within the application layer: order approval, invoice creation, and shipment assignment publish events through narrow listener interfaces. This allows subsystems to interact without tight coupling.

Three architectural rules enforce this design:
1. Domain classes never import presentation or application packages.
2. `DataStore` is accessed exclusively through controllers.
3. Event publishers depend on listener interfaces rather than concrete subscriber classes.

#heading(level: 1, numbering: none)[#text("6. Implementation and Testing")]

#heading(level: 2, numbering: none)[6.1 Mapping design to code]

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
    [T1: Register Customer], [✅ Full], [Implemented via `OrderProcessor.registerCustomer()` with field-level validation.],
    [T2: Browse Services], [❌ Not implemented], [Service catalogue exists but no browse/search UI is provided.],
    [T3: Place Order], [✅ Full], [Implemented via `OrderProcessor.submitOrder()` with consignment creation and quote calculation.],
    [T4: Process/Approve Order], [✅ Full], [Dispatcher approve/reject with reason; `OrderState` pattern guards transitions.],
    [T5: Assign Resources], [✅ Full], [Implemented via `DispatchManager.assignShipment()` with capacity and availability checks.],
    [T6: Track Shipment], [✅ Full], [Implemented via `ShipmentTracker.confirmPickup/InTransit/Delivery()` with State pattern guards.],
    [T7: Record Milestones], [✅ Full], [Covered by T6; manual location input through `ManualTelemetrySource` adapter.],
    [T8: Process Payment], [✅ Full], [Implemented via `PaymentProcessor.submitPayment()` with cash/gateway strategies.],
    [T9: Generate Receipt], [✅ Full], [Immutable `Receipt` created automatically upon payment settlement.],
    [T10: Manage Vehicles], [❌ Not implemented], [Vehicle records are seeded during bootstrap but no CRUD UI is provided.],
    [T11: Manage Drivers], [❌ Not implemented], [Driver records are seeded during bootstrap but no CRUD UI is provided.],
    [T12: Generate Reports], [❌ Not implemented], [`Report` class is designed (Assignment 2) but explicitly deferred as out of scope.],
    [T13: Update Customer], [❌ Not implemented], [Customer status can be changed programmatically but no update UI is provided.],
    [T14: Cancel/Modify Order], [⚠️ Partial], [Cancellation is implemented; modification of submitted order fields is not supported.],
    [T15: Manage Config], [❌ Not implemented], [`SystemConfiguration` is loaded at startup but no admin UI for changing values is provided.],
  )),
  caption: [SRS task coverage: eight tasks fully implemented (✅), one partially supported (⚠️), six deferred or out of scope (❌).],
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

#heading(level: 2, numbering: none)[6.2 Compilation and Execution]

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

The screenshots below were generated by running `tools/java/smartfm/ui/gui/ScreenshotDriver.java`. The driver automates user actions and captures the application window directly. The full set of 26 screenshots is stored in `implementation/screenshots/`. The selection below illustrates the core system features.

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("implementation/screenshots/00_home_screen_empty.png", width: 100%),
    image("implementation/screenshots/01b_customer_registration_validation_errors.png", width: 100%),
  ),
  caption: [GUI evidence: empty customer-registration home screen (left) and rejected invalid phone/email input with inline messages (right).],
) <fig-gui-empty-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("implementation/screenshots/01c_customer_registration_success.png", width: 100%),
    image("implementation/screenshots/02f_order_management_order_cancelled.png", width: 100%),
  ),
  caption: [GUI evidence: accepted customer input and successful account creation (left); a customer change of mind cancels an order without deleting unrelated data (right).],
) <fig-gui-input-change>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("implementation/screenshots/03d_fleet_dispatch_shipment_created.png", width: 100%),
    image("implementation/screenshots/04b_shipment_tracking_invalid_transition_rejected.png", width: 100%),
  ),
  caption: [GUI evidence: successful vehicle/driver assignment creates a shipment (left); an illegal delivery-before-pickup transition is rejected by the State pattern (right).],
) <fig-gui-dispatch-tracking-validation>

#figure(
  grid(columns: (1fr, 1fr), gutter: 7pt,
    image("implementation/screenshots/04e_shipment_tracking_delivered.png", width: 100%),
    image("implementation/screenshots/05d_billing_payment_settled.png", width: 100%),
  ),
  caption: [GUI evidence: successful delivery transition (left); simulated payment completion, receipt issuance, and a paid invoice (right). No real banking transaction is performed.],
) <fig-gui-completion>

#figure(
  image("implementation/screenshots/06_final_state_before_exit.png", width: 75%),
  caption: [Final application state immediately before normal exit. Closing the window invokes the registered handler, commits the normalized `DataStore` rows to SQLite, and exits; the recorded CLI scenarios independently verify that the database is restored in a later process.],
) <fig-gui-exit>

To regenerate all screenshots on a machine with JDK 26 and GNU Make, run `make screenshots` inside `implementation/`. The driver resets demonstration data, executes the test scenarios, saves the screenshots, and exits.

#heading(level: 2, numbering: none)[6.3 Testing]

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

SmartFM converts the Assignment 2 design into a functional Java 26 application featuring GUI and CLI interfaces, embedded SQLite persistence, four operational areas, and GRASP Controllers. The implementation preserves key design choices from Assignment 2, including cohesive controller roles, lifecycle State classes, and decoupled event listeners.

Compilation logs and scenario transcripts verify the core workflows from customer registration to payment settlement, including invalid input handling and state machine guards. Traceability tables and sequence diagrams map UI events to controller logic, domain rules, and database persistence. Deferred features, such as report generation, can be added in future iterations using the existing layered architecture.

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
