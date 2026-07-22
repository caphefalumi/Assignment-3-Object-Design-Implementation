#import "ieee.typ": *
#import "@preview/wordometer:0.1.5": total-words, word-count
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#show: word-count

#show: ieee.with(
  title: "SWE30003 Assignment 2 \n Object Design",
  sub_title: " Smart Fleet Management System",
  date_of_submission: "19th July 2026",
  header-left: "Assignment 2",
  header-right: "Swinburne University of Technology",
  authors: (
    (
      name: "Dang Duy Toan",
      studentid: [105508402],
      email: "105508402@student.swin.edu.au",
      signature: image("images/toan_signature.png", width: 50%)
    ),
    (
      name: "Phan Le Minh Hieu",
      studentid: [105543377],
      email: "105543377@student.swin.edu.au",
      signature: image("images/hieu_sign.jpg", width: 60%)
    ),
    (
      name: "Vo Ngoc Nam",
      studentid: [105551859],
      email: "105551859@student.swin.edu.au",
      signature: image("images/Nam_signature.png", width: 70%)
    ),
    (
      name: "Lam An Thinh",
      studentid: [105508512],
      email: "105508512@student.swin.edu.au",
      signature: image("images/thinh_signature.png", width: 30%)
    )
  ),
  
  bibliography-file: "refs.bib",
)
// #align(right)[
//   *Word Count:* #context total-words
// ]

#set par(
  first-line-indent: (amount: 1.5em, all: true),
)

#show table: set text(size: 8.5pt)
#show table: it => {
  show raw: it => {
    if it.block {
      it
    } else {
      let formatted = it.text
        .replace(".", ".\u{200b}")
        .replace("(", "(\u{200b}")
        .replace(",", ",\u{200b}")
      text(size: 1.05em)[#formatted]
    }
  }
  it
}

#let header-fill   = rgb("#1a3a5c")   // dark navy for header rows
#let alt-row-fill  = rgb("#f0f4f8")   // light blue-grey for alternating rows
#let border-stroke = 0.5pt + rgb("#9db3c8")

// Renders a table header cell in white bold text on the navy background
#let th(content) = table.cell(
  fill: header-fill,
  text(fill: white, weight: "bold", content),
)

#set heading(numbering: "1.")
#outline(title: [Table of Contents])
#colbreak()

#heading(level: 1, numbering: none)[Executive Summary]

ABC-Trans is a Vietnamese logistics and transportation company that serves department stores and supermarkets nationwide. Manual processes and disconnected local systems cause slow service, frequent vehicle unavailability, and customer dissatisfaction. Assignment 1 outlined the Software Requirements Specification (SRS). This included the core requirements, entities, actors, and tasks for the Smart Fleet Management (SmartFM) system.

This report takes the requirements from the SRS to design the high-level, object-oriented structure of SmartFM. Following Responsibility-Driven Design (RDD), we came up with an architecture of twenty core classes, six design pattern abstractions, and two decoupling interfaces (28 elements in total). We documents each class and interface using a CRC card to specify its responsibilities and collaborators. To keep the business logic clean and robust, we combined standard heuristics like Information Expert and Separation of Concerns with several Gang-of-Four design patterns. Specifically, we used the Factory Method for controlled creation, the Observer pattern for event-driven decoupling, and polymorphic State and Strategy hierarchies to handle complex object lifecycles and pricing rules. We also set up a strict bootstrap sequence to keep our references clean during startup, and verified the entire design by mapping out four major operational scenarios with UML sequence diagrams.

This high-level design does not dive into user interfaces or database schemas. Instead, these classes are meant to act as the in-memory interface to a database later on. Assignment 1 is attached as an appendix.

= Introduction

== Document Overview

This document lays out our high-level object-oriented design for the Smart Fleet Management System (SmartFM). It serves as the blueprint for our upcoming implementation in Assignment 3.

Instead of jumping straight into UML classes diagrams, we start by detailing our assumptions, simplifications, and trade-offs. From there, we identify our candidate classes and document them using Class-Responsibility-Collaborator (CRC) cards and a unified class diagram. The middle sections explain the reasoning behind our design choices, drawing on design heuristics and standard Gang-of-Four patterns. Finally, we map out a startup sequence and validates the design against four core operational scenarios.

== Outlook of Solution

Our design center on a unified object model that coordinates fleet assets, drivers, orders, shipments, and billing across all branches. Long-term storage is handled by a shared database. This keep our domain classes clean and in-memory, separating data persistence from the client-facing channels.

We split this object model into three layers. At the bottom are our core *domain classes* like `Customer`, `Vehicle`, `Driver`, `Order`, and `Shipment`. They hold state and run local validation. Above them, *coordinating controllers* like `OrderProcessor`, `DispatchManager`, `ShipmentTracker`, and `PaymentProcessor` manage multi-step business workflows. Finally, lightweight *data-holder classes* like `SystemConfiguration` act as read-only containers for settings loaded at startup.

When the system start, a bootstrap sequence initializes these controllers and configurations in a strict, dependency-safe order. This setup ensures everything is consistent before the system accepts any requests.

This single set of core classes supports all three client channels (the customer web portal, customer mobile app, and staff web portal). We don't need separate classes for different portals at this high-level stage.

== Trade-offs and Object Design

Designing SmartFM forced us to make some tough trade-offs. Because no design is perfect, we had to balance theoretical completeness with everyday maintainability.

The first challenge were balancing real-world detail against class bloat. It was tempting to create unique subclasses for every single back-office role. While precise, that would have left us with a tangled web of tiny, empty classes. We kept the design clean by grouping all office roles into a single `StaffMember` class and using role-based access control (RBAC) attributes instead. This keep our class hierarchy flat while still meeting all security requirements.

Our second trade-off was deciding where to put our workflow coordination logic. Putting complex, multi-step business rules directly inside domain objects like `Vehicle` or `Invoice` would cause them to balloon into unmaintainable god classes. To prevent this, we move workflow coordination into four dedicated controllers. This keeps our domain classes lightweight, focused, and responsible only for holding their own state and running local validation checks.

=== Naming Convention

To keep the codebase consistent across the team, we adopted a clear naming scheme. Class names use singular PascalCase, like `Customer` or `ServiceOffering`, matching the real-world terminology from our SRS. Interfaces also use PascalCase but start with an 'I' and describe a capability, like `IPaymentGateway`. For internal variables, we use camelCase with a leading underscore, while constants are written in UPPER_SNAKE_CASE. Since this is high-level design, we left out specific method signatures and attribute lists to avoid cluttering the document with premature implementation details.

=== Boundary Cases

Our domain classes validate incoming data before updating their internal state. We enforce several basic boundary rules across the system. Text inputs must fit within sensible character limits, and numeric fields, like weight capacity, shipping distance, and payment amount, must be positive numbers. We also validate dates to make sure scheduled pickups do not point to the past, and we require an `Order` to have at least one `Consignment` before it can go through. For payments, the system immediately rejects any `Payment` that exceeds the outstanding balance on the target `Invoice`. The class receiving the input will always responsible for running these checks, rejecting bad data before any state change is committed.

=== Invalid Password or Username Exception

Authentication and security are handled by a separate infrastructure service that verifies credentials before letting anyone touch our domain model. If a login fail, the system throws an `InvalidCredentialsException` and shows a generic error message. This prevents brute-force attacks by not revealing whether the username or password was the incorrect field. We also enforce a lock-out limit: after five failed login attempts in a row, the system locks the account automatically, and an administrator must step in to unlock it.

=== Invalid Data Exception

If any input fails validation, the class throws an `InvalidDataException`. This handles common mistakes like putting letters in numeric fields, passing negative numbers where positive values are required, or submitting strings that are too long. Enforcing these rules directly inside our domain classes stop bad data right at the system boundary, protecting our persistent database from getting corrupted.

== Documentation and Guidelines for Interface

The table below defines the identifier naming rules applying throughout this design document and in subsequent implementation work.

#figure(
  table(
    columns: (2fr, 5fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,

    // ---- fill: header navy, then alternate white / light-blue ----
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    // ---- header row ----
    th[Identifier], th[Rules], 

    // ---- data rows ----
    [Classes],
    [Descriptive, singular, PascalCase. Names correspond to domain vocabulary from Assignment 1.],
   

    [Interfaces],
    [PascalCase, named as a noun or adjective phrase that describes a capability or contract.],
   

    [Variables],
    [Short, meaningful, camelCase, prefixed with a leading underscore character.],


    [Constants],
    [UPPER\_SNAKE\_CASE.],

    [Methods],
    [Excluded from this initial design document.],

    [Data-holder classes],
    [We identify data-holder classes explicitly in the class list and CRC section. Distinguished from full domain classes throughout the design discussion.],
  ),
  caption: [Documentation and Guidelines for Interface],
) <tbl-interface-guidelines>


== Definitions, Acronyms, and Abbreviations
#figure(
  table(
    columns: (2fr, 8fr),
    align: (left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,

    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    // ---- header row ----
    th[Term], th[Full Form or Definition],

    // ---- data rows ----
    [ABC-Trans],
    [The client company. A Vietnamese logistics and transportation company serving retail and supermarket chains nationwide.],

    [SmartFM],
    [Smart Fleet Management System. The centralised software system being designed in this document.],

    [ODD],
    [Object Design Document. This document.],

    [SRS],
    [Software Requirements Specification. The Assignment 1 document produced by this group.],

    [RDD],
    [Responsibility-Driven Design. The object design method applied in this assignment.],

    [CRC],
    [Class-Responsibility-Collaborator. The card format used to document each candidate class.],

    [UML],
    [Unified Modelling Language. The standard notation used for the class diagram.],

    [OO],
    [Object-Oriented. The programming paradigm applied in this design.],

    [RBAC],
    [Role-Based Access Control. The access model governing which staff roles may perform which system operations.],

    [GPS],
    [Global Positioning System. Vehicle-mounted hardware that streams location data to `ShipmentTracker`.],

    [Branch],
    [A physical operational location of ABC-Trans that manages its own fleet and driver pool.],

    [Order],
    [A formal customer request for shipment service submitted through SmartFM.],

    [Shipment],
    [The physical execution and operational tracking of an approved Order.],

    [Consignment],
    [A specific package or set of goods included within a single Order.],

    [Dispatch],
    [The act of assigning an available Vehicle and Driver to fulfil an approved Order.],

    [Invoice],
    [A billing document generated automatically by the system upon Order approval.],

    [Receipt],
    [An immutable confirmation document generated after a verified Payment has been processed.],

    [PricingTariff],
    [A structured rate schedule defining the billing rules for a ServiceOffering under specific conditions.],

    [ServiceOffering],
    [A defined logistics service tier available at one or more Branches.],

    [Bootstrap],
    [The initialisation sequence in which the system creates all necessary objects at startup in a defined order.],

    [God Class],
    [An anti-pattern in which one class accumulates too many unrelated responsibilities. Avoided in this design through the RDD approach.],
  ),
  caption: [Definitions, Acronyms, and Abbreviations],
) <tbl-definitions>

= Problem Analysis

Our Assignment 1 SRS established the core requirements, domain entities, actors, and tasks for SmartFM. Here, we analyze those requirements to make our high-level design choices. This section details our scoping assumptions, simplifications, design justifications, and the classes we decided to discard.


== Assumptions

These assumptions outline the scope of our design and help guide our responsibility assignments.

*A1*. All system data is stored in a single, shared relational database. Persistent classes interact with it through a data access layer, which is outside the scope of this high-level design.

*A2*. Classes validate their own internal data. We do not use a single, global validation class.

*A3*. A separate security service handles logins and sessions. Our domain classes assume the caller has already been authenticated with the correct permissions.

*A4*. A driver belongs to exactly one branch at any given time. Reassigning a driver is an admin task coordinated by HR staff using the `StaffMember` class.

*A5*. A vehicle belongs to exactly one branch at a time. Reassigning a vehicle is handled by fleet administrators using the `StaffMember` class.

*A6*. A dispatcher must approve an order before a shipment is created. The system never instantiates a `Shipment` for an unapproved `Order`.

*A7*. The system automatically generates an `Invoice` when an order is approved, calculating the amount by running the selected `ServiceOffering` through the `PricingTariff` rules.

*A8*. Once created, a `Receipt` is completely immutable. Users can view or print receipts, but they cannot edit them. The system keeps all receipt records indefinitely for auditing.

*A9*. On-board GPS hardware streams real-time coordinates to the `ShipmentTracker`. This design does not specify the hardware model or connection protocol.

*A10*. Customer discounts and loyalty programs are out of scope. Our design makes it easy to add these behaviors later without rewriting the core domain model.

*A11*. SmartFM is accessed via three portals (customer web, customer mobile, and staff web). We do not design UI classes here; our domain and controller classes are shared across all three channels.

*A12*. Branch staff record cash payments manually. Digital payments go through third-party gateways. `PaymentProcessor` is the only class in our design that interacts with these external gateways.

*A13*. One `Report` class handles all reports. We do not need different classes for daily, monthly, or divisional reports. The caller simply specifies the type, date range, and scope as parameters when creating a report.

*A14*. `SystemConfiguration` is a simple data-holder class containing system-wide limits (like login attempt thresholds or session timeouts). The system loads it once at startup, and other classes query it when needed.

== Simplifications

We simplified a few areas of the design to keep complexity down while keeping all the required features:

First, we use a single `StaffMember` class to model back-office roles like Dispatcher, BranchManager, FleetAdministrator, HRStaff, and SystemAdministrator. Instead of creating five near-empty subclasses, we represent these roles as an attribute on `StaffMember` itself. This attribute is managed by role-based access control (RBAC), keeping our class hierarchy flat. `Driver` remains a distinct subclass of `StaffMember` because drivers have unique operational requirements like shift hours, license tracking, and duty states. This inheritance lets `Driver` reuse the login and authentication behaviors of `StaffMember` while adding mobile-login and tracking attributes.

Second, a single `Vehicle` class handles standard trucks, refrigerated units, and flatbeds. The vehicle type and its capabilities are stored as simple attributes rather than subclasses. This keeps our class list short and avoids unnecessary inheritance.

Third, a single `Consignment` class represents all cargo types, from regular goods to refrigerated or oversized shipments. We store requirements like temperature thresholds or fragility as simple attributes instead of setting up a complex subclass tree.

Finally, a single `Report` class manages all reporting intervals, such as daily, weekly, or annual views. The caller specifies the report type and time range as parameters, avoiding the need for multiple, highly similar report classes.

== Design Justification

We started identifying candidate classes by mapping the domain entities from our SRS straight to object design classes. Next, we reviewed the task descriptions to find behaviors and tasks that needed a clear home. Whenever a workflow felt too complex or involved multiple domain classes, we created a dedicated controller class to manage the process.

To keep our objects balanced and cohesive, we followed Responsibility-Driven Design (RDD) and regularly checked for bloated 'god classes'. If any class accumulated more than five primary responsibilities, we split it up or delegated some of its work to other classes.

Our design separates `Order` and `Shipment` completely. An order is a stable, commercial contract. A shipment is the physical on-the-road execution of that contract. Decoupling them allows dispatchers to reassign trucks, update route milestones, or deal with breakdowns without changing the original, legally binding order or its invoice.

Similarly, we decoupled `PricingTariff` from `ServiceOffering`. The service offering define what we offer, like Cold Chain or Express, while the pricing tariff defines how the cost is calculated. This separation let finance teams update seasonal rates or distance fees without affecting the operational scheduling rules.

Every class in our final model has a unique job that cannot be handled by an existing class. This principle led us to create our four controllers and helped us spot and eliminate the seven redundant candidate classes listed below.

Lastly, we made sure to avoid duplicating domain data across classes. Actions like calculating invoices, verifying payments, and issuing receipts belong to single, focused classes. This prevent data synchronization issues, keeps our database mapping straightforward, and fits the modular goals of RDD.

== Discarded Class List

We proposed the following candidate classes during the analysis phase but excluded them from the final design with explicit justification.

- *GuestCustomer*: In Assignment 1, a guest customer is an unregistered user who browses services without logging in. We originally considered a separate `GuestCustomer` class. We discarded it because browsing services and looking up rates are already handled by `ServiceOffering` and `PricingTariff`, which do not need a customer object. Managing anonymous access is best handled by the web portal itself, outside our core object model.

- *TrackingLog*: We first proposed a `TrackingLog` class to store GPS location history for shipments. We discarded it because `ShipmentTracker` already handles real-time updates and manages active tracking. Writing coordinates to a history table is a database task, so we do not need a dedicated domain class for it.

- *NotificationService*: We considered a `NotificationService` class to send emails, text messages, or push alerts when order statuses change. We decided to defer this. Sending alerts is a technical infrastructure task rather than core business logic. We can integrate notification APIs later once our core domain model is stable.

- *UserAccount*: We thought about a `UserAccount` class to store passwords and session tokens. We discarded it because our security infrastructure handles credentials (see Assumption A3). `Customer` and `StaffMember` hold their own basic ID details without needing a separate authentication class.

- *LocationData*: We proposed a `LocationData` class to hold a GPS coordinate and a timestamp. We discarded it and put those fields directly into `ShipmentTracker`. A simple coordinate pair has too little behavior to justify its own class. `ShipmentTracker` manages the current position of active shipments and saves history to the database.

- *DriverSchedule*: We proposed `DriverSchedule` to track driver availability and shift history. However, driver availability and duty states are best kept directly inside the `Driver` class. Scheduling rules and assignment logic are managed by `DispatchManager`, so a separate schedule class would only add unnecessary coupling.

- *Inventory*: We proposed a `FleetInventory` class to maintain a master list of vehicles and statuses across branches. We discarded this because each `Branch` already tracks the vehicles registered to it. A separate inventory class would only duplicate this data, creating a bloated god-class and violating our RDD goal of keeping data close to the objects that own it.

= Candidate Classes

== Overview

This section introduces the high-level object-oriented model for SmartFM. We followed Responsibility-Driven Design (RDD) to design this system. RDD views a software system as a community of cooperating objects. We define each object by what it knows and what it does rather than its database schema or database attributes. Nailing down these responsibilities first helps us set clear boundaries before getting bogged down in variables, types, or method signatures.

By studying the entities, tasks, and workflows in our Assignment 1 SRS, we identified twenty core candidate classes, six design pattern abstractions, and two decoupling interfaces (28 elements total). We evaluated each candidate against three simple tests: does it represent a stable business concept, does it have a unique job, and would removing it leave a gap in our system? We intentionally left out user interface components, database tables, and external integrations at this stage. Deferring these technical details keeps our core domain model stable and independent of specific technology choices.

== Candidate Identification Process

We identified candidate classes by studying the domain description and requirements from Assignment 1. Our process followed three main steps:

1. We used core nouns in the business domain to form our initial list of candidate entities, such as customer, vehicle, driver, branch, invoice, and payment.
2. We looked at business workflows to spot coordinating and controlling tasks that did not belong in any single domain object. These led to our controller classes for order placement, scheduling, and payment processing.
3. We analyzed system actors like customers, drivers, and office staff to find common behaviors, which suggested inheritance hierarchies.

We then categorized our candidates using the Entity-Control-Boundary (ECB) pattern:

- *Entity classes* hold the data and local business rules the system must track. These include Customer, Order, Consignment, Shipment, Vehicle, Driver, Branch, Invoice, Payment, Receipt, ServiceOffering, PricingTariff, Report, and StaffMember.
- *Control classes* coordinate multi-step workflows that involve multiple entity classes. These are our controllers: OrderProcessor, DispatchManager, ShipmentTracker, and PaymentProcessor.
- *Boundary classes* manage interactions with users or external systems.

We only keep the entity, abstract, and control classes in this design document. We left out UI and boundary classes because user interfaces change frequently and should not be mixed with stable business logic.

== Candidate Class List

We organized our twenty core classes into six packages, put our six design pattern abstractions into a seventh package, and defined two decoupling interfaces. This keeps similar code together and minimizes dependencies across the system.

=== Commercial and Ordering Package

- *Customer*: A registered client or consumer who contracts our shipping services.
- *Order*: The commercial contract and service request submitted by a customer.
- *Consignment*: The actual packages or items tied to an order.
- *Shipment*: The physical execution of an approved order, managing vehicles, drivers, and delivery milestones.

=== Fleet and Resources Package

- *Vehicle*: A commercial delivery truck owned and run by a branch.
- *Driver*: A licensed driver employed by the company.
- *Branch*: A physical regional depot that manages its local pool of trucks and drivers.

=== Billing and Settlement Package

- *Invoice*: The billing document generated automatically once an order is approved.
- *Payment*: A single transaction recorded against an invoice.
- *Receipt*: An unchangeable proof of payment created when an invoice is settled.

=== Service and Pricing Catalog Package

- *ServiceOffering*: A specific service tier we offer, like Cold Chain or Express.
- *PricingTariff*: The pricing formulas and rates used to calculate costs for a service tier.

=== Personnel and Administration Package

- *Person*: An abstract base class holding shared details like names and contact info.
- *StaffMember*: An authenticated employee with role-based permissions.

=== System Control and Configuration Package

- *SystemConfiguration*: A data-holder class that stores system-wide constants and limits.
- *Report*: A class that pulls operational and financial numbers for management reports.
- *OrderProcessor*: A controller that handles order submissions, verification, and invoice creation.
- *DispatchManager*: A controller that schedules vehicles, assigns drivers, and creates shipments.
- *ShipmentTracker*: A controller that monitors real-time GPS telemetry and transit milestones.
- *PaymentProcessor*: A controller that integrates with payment gateways and verifies transactions.

=== Decoupling Interfaces

- *IPaymentGateway*: An interface that standardizes how we connect with external payment systems.
- *ITelemetrySource*: An interface that standardizes how we read GPS coordinates from different hardware.

=== Design Pattern Abstraction Package

- *OrderState*: An abstract class defining the contract for order lifecycle states, implemented by concrete states like Submitted, Approved, and Cancelled.
- *ShipmentState*: An abstract class defining the contract for shipment milestones, implemented by concrete states like Assigned, Picked Up, In Transit, and Delivered.
- *InvoiceState*: An abstract class defining the contract for invoice statuses, implemented by concrete states like Unpaid, Partially Paid, and Paid.
- *PaymentState*: An abstract class defining the contract for payment verification, implemented by concrete states like Pending, Verified, Settled, and Failed.
- *IPaymentStrategy*: A strategy interface for interchangeable payment methods, like cash or online gateways.
- *IPricingStrategy*: A strategy interface for interchangeable pricing models, like distance-based or peak-hour pricing.

=== Structural Modeling Decisions

We chose to model `Receipt` as a full domain class rather than a simple data-holder. While a receipt is immutable once created, it has active business responsibilities in our design. It verifies payment settlement, holds secure tax signatures, and maintains financial audit trails to comply with Vietnamese accounting laws. This makes retrieving a receipt an active process rather than just reading raw text from storage.

On the other hand, `SystemConfiguration` is designed as a passive data-holder. It has no behavior of its own and simply provides read-only access to system settings loaded at startup.

To implement the Gang-of-Four State and Strategy patterns cleanly, we explicitly list `OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState`, `IPaymentStrategy`, and `IPricingStrategy` in our class model. Instead of using simple status strings or numbers, which would lead to code cluttered with if-else statements, these state and strategy abstractions encapsulate lifecycles and business algorithms in separate classes. To keep this document concise, we provide CRC cards for these base abstractions. Their concrete subclasses, like `OrderSubmittedState` or `GatewayPaymentStrategy`, inherit these responsibilities directly.

== UML Overview

Our UML diagram organizes classes in a clean grid. Controllers sit on the top row, core domain entities occupy the middle, and support classes are placed on the bottom. This layout makes it easy to trace how control flows from our workflow controllers down into the domain model.

#let class-node(pos, name, superclass: none, stereotype: none, w: 2.1cm, h: 0.95cm) = {
  node(
    pos,
    rect(
      width: w,
      height: h,
      radius: 4pt,
      fill: rgb("#f0f4f8"),
      stroke: 1.0pt + rgb("#1a3a5c"),
      inset: 2pt,
      align(center + horizon)[
        #set text(size: 7.2pt, weight: "bold", fill: rgb("#1a3a5c"))
        #if stereotype != none [
          #text(size: 5.8pt, style: "italic", fill: rgb("#1a3a5c").lighten(20%))[#stereotype] \
        ]
        #name
        #if superclass != none [
          \ #text(size: 5.8pt, style: "italic", fill: rgb("#1a3a5c").lighten(30%))[#superclass]
        ]
      ]
    ),
    stroke: none,
    fill: none
  )
}

#let candidate-diagram() = diagram(
  spacing: (3.1cm, 1.8cm),
  {
    // Row -0.7: Decoupling Interfaces (External Volatility)
    class-node((3, -0.75), "ITelemetrySource", stereotype: "«interface»", w: 3.0cm)
    class-node((4, -0.75), "IPaymentGateway", stereotype: "«interface»", w: 3.0cm)

    // Row 0: Controllers & SystemConfiguration
    class-node((0, 0), "SystemConfiguration", stereotype: "«data-holder»", w: 3.2cm)
    class-node((1, 0), "OrderProcessor", w: 2.8cm)
    class-node((2, 0), "DispatchManager", w: 2.8cm)
    class-node((3, 0), "ShipmentTracker", w: 2.8cm)
    class-node((4, 0), "PaymentProcessor", w: 2.8cm)
    
    // Row 0.5: Common Demographics
    class-node((1.5, 0.5), "Person", stereotype: "«abstract»", w: 2.3cm)

    // Row 1: Core Domain Entities (Control / Key Contracts)
    class-node((0, 1), "Customer", superclass: "Person", w: 2.3cm)
    class-node((1, 1), "Order", w: 2.3cm)
    class-node((2, 1), "Shipment", w: 2.3cm)
    class-node((3, 1), "StaffMember", superclass: "Person", w: 2.3cm)
    class-node((4, 1), "Invoice", w: 2.3cm)
    
    // Row 2: Detail / Composition Layer
    class-node((0, 2), "ServiceOffering", w: 2.5cm)
    class-node((1, 2), "Consignment", w: 2.3cm)
    class-node((2, 2), "Vehicle", w: 2.3cm)
    class-node((3, 2), "Driver", superclass: "StaffMember", w: 2.3cm)
    class-node((4, 2), "Payment", w: 2.3cm)
    
    // Row 3: Support Layer / Leaves
    class-node((0, 3), "PricingTariff", w: 2.3cm)
    class-node((2, 3), "Branch", w: 2.3cm)
    class-node((3, 3), "Report", w: 2.3cm)
    class-node((4, 3), "Receipt", w: 2.3cm)

    // Design Pattern Abstractions
    class-node((0.5, 2.5), "IPricingStrategy", stereotype: "«interface»", w: 3.0cm)
    class-node((4.5, 0.5), "IPaymentStrategy", stereotype: "«interface»", w: 3.0cm)
    class-node((1.5, 1.5), "OrderState", stereotype: "«abstract»", w: 2.3cm)
    class-node((2.5, 1.5), "ShipmentState", stereotype: "«abstract»", w: 2.3cm)
    class-node((4.5, 1.5), "InvoiceState", stereotype: "«abstract»", w: 2.3cm)
    class-node((4.5, 2.5), "PaymentState", stereotype: "«abstract»", w: 2.3cm)

    // Connections (Edges)
    
    // 1. Generalization / Inheritance (hollow triangle points to base class: "-|>" in fletcher)
    edge((0, 1), (1.5, 0.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c")) // Customer -> Person
    edge((3, 1), (1.5, 0.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c")) // StaffMember -> Person
    edge((3, 2), (3, 1), "-|>", stroke: 0.8pt + rgb("#1a3a5c"))     // Driver -> StaffMember

    // 2. Compositions (filled diamond at owner end)
    // Order owns Consignment
    edge((1, 1), (1, 2), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))
    // Invoice owns Payment
    edge((4, 1), (4, 2), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))
    // Payment owns Receipt
    edge((4, 2), (4, 3), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))

    // 3. Aggregations (hollow diamond at container end)
    // Branch has Vehicles (1 -> 0..*)
    edge((2, 3), (2, 2), marks: ((inherit: "diamond", fill: white), none), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((2, 3), (2, 2), stroke: none, label: "0..*", label-pos: 0.85)
    
    // Branch has Drivers (1 -> 0..*)
    edge((2, 3), (3, 2), marks: ((inherit: "diamond", fill: white), none), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((2, 3), (3, 2), stroke: none, label: "0..*", label-pos: 0.85)

    // StaffMember is assigned to Branch (0..* -> 1)
    edge((3, 1), (2, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: "0..*", label-pos: 0.15)
    edge((3, 1), (2, 3), stroke: none, label: "1", label-pos: 0.85)

    // 4. Plain Associations with Multiplicities
    // Customer - Order (1 -> 1..*)
    edge((0, 1), (1, 1), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((0, 1), (1, 1), stroke: none, label: "1..*", label-pos: 0.85)

    // Order - ServiceOffering (0..* -> 1)
    edge((1, 1), (0, 2), stroke: 0.8pt + rgb("#1a3a5c"), label: "0..*", label-pos: 0.15)
    edge((1, 1), (0, 2), stroke: none, label: "1", label-pos: 0.85)

    // ServiceOffering - PricingTariff (1 -> 1)
    edge((0, 2), (0, 3), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((0, 2), (0, 3), stroke: none, label: "1", label-pos: 0.85)

    // Shipment - Vehicle (0..* -> 1)
    edge((2, 1), (2, 2), stroke: 0.8pt + rgb("#1a3a5c"), label: "0..*", label-pos: 0.15)
    edge((2, 1), (2, 2), stroke: none, label: "1", label-pos: 0.85)

    // Shipment - Driver (0..* -> 1)
    edge((2, 1), (3, 2), stroke: 0.8pt + rgb("#1a3a5c"), label: "0..*", label-pos: 0.15)
    edge((2, 1), (3, 2), stroke: none, label: "1", label-pos: 0.85)

    // Order - Shipment (1 -> 0..*)
    edge((1, 1), (2, 1), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((1, 1), (2, 1), stroke: none, label: "0..*", label-pos: 0.85)

    // Order - Invoice (1 -> 1)
    edge((1, 1), (4, 1), stroke: 0.8pt + rgb("#1a3a5c"), label: "1", label-pos: 0.15)
    edge((1, 1), (4, 1), stroke: none, label: "1", label-pos: 0.85)

    // 5. Controller Transient Coordination Dependencies (Dashed arrow: "->", dash: "dashed")
    // OrderProcessor
    edge((1, 0), (1, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((1, 0), (4, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    // DispatchManager
    edge((2, 0), (2, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((2, 0), (2, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    // ShipmentTracker
    edge((3, 0), (2, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((3, 0), (3, -0.75), "-|>", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    // PaymentProcessor
    edge((4, 0), (4, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((4, 0), (4, -0.75), "-|>", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    // Report queries Branch
    edge((3, 3), (2, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    // 6. Design Pattern State and Strategy Associations
    edge((1, 1), (1.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // Order has OrderState
    edge((2, 1), (2.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // Shipment has ShipmentState
    edge((4, 1), (4.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // Invoice has InvoiceState
    edge((4, 2), (4.5, 2.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // Payment has PaymentState
    edge((4, 0), (4.5, 0.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // PaymentProcessor uses IPaymentStrategy
    edge((4.5, 0.5), (4, -0.75), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed") // IPaymentStrategy uses IPaymentGateway
    edge((0, 2), (0.5, 2.5), "->", stroke: 0.8pt + rgb("#1a3a5c")) // ServiceOffering has IPricingStrategy
    edge((0, 3), (0.5, 2.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c")) // PricingTariff implements IPricingStrategy
  }
)

#figure(
  align(center, scale(70%, reflow: true, candidate-diagram())),
  caption: [SmartFM unified candidate class model with responsibility-only classes (native vector rendering).],
) <fig:uml>

== CRC Cards (Class Collaborations)

We used the Class-Responsibility-Collaborator (CRC) card tables below to specify what each of the twenty core candidate classes, six design pattern abstractions and two decoupling interfaces does and who it collaborates with. Each team member was responsible for specific classes to distribute the work evenly.

#let crc-card(name, super: "N/A", author: "", desc: [], rows: ()) = {
  block(
    width: 100%,
    stroke: border-stroke,
    radius: 4pt,
    fill: white,
    inset: 0pt,
    clip: true,
    breakable: false,
    [
      #table(
        columns: (1fr),
        align: left + horizon,
        inset: (x: 9pt, y: 7pt),
        stroke: none,
        fill: header-fill,
        [
          #text(fill: white, weight: "bold", size: 10.5pt)[CRC Card: #name]
          #if author != "" [ \ #text(fill: white.lighten(40%), size: 8pt)[Custodian: #author] ]
        ],
      )
      #v(-8pt)
      #block(
        inset: (x: 9pt, y: 7pt),
        [
          #text(weight: "bold")[Super Class:] #if super != "N/A" [ #super ] else [ N/A ] \
          #text(weight: "bold")[Description:] #desc
        ]
      )
      #v(-8pt)
      #table(
        columns: (1fr, 1fr),
        align: left + top,
        inset: (x: 9pt, y: 7pt),
        stroke: border-stroke,
        fill: (col, row) => if row == 0 { alt-row-fill } else { none },
        [*Responsibilities*], [*Collaborators*],
        ..rows.map(((resp, collab)) => (
          [#resp],
          [#collab]
        )).flatten()
      )
    ]
  )
}

#crc-card(
  "Person",
  super: "N/A",
  author: "Phan Le Minh Hieu",
  desc: [Abstract base class representing common demographic and identity attributes shared by all human entities within the system.],
  rows: (
    ("Knows primary identification details (ID, full name, gender, date of birth).", "N/A"),
    ("Knows contact details (phone number, email address, physical address).", "N/A"),
    ("Validates contact formats and name fields.", "InvalidDataException"),
  )
)

#v(1em)

#crc-card(
  "Customer",
  super: "Person",
  author: "Dang Duy Toan",
  desc: [Represents registered commercial clients (such as department stores or supermarket chains) contracting shipping services from ABC-Trans.],
  rows: (
    ("Knows account classification, registration date, and customer status (Active, Suspended).", "N/A"),
    ("Initiates order requests for freight transit.", "Order"),
    ("Accesses its associated invoices, payment history, and generated receipts through its commercial transactions.", "Invoice, Payment, Receipt"),
  )
)

#v(1em)

#crc-card(
  "StaffMember",
  super: "Person",
  author: "Lam An Thinh",
  desc: [Represents any authenticated internal employee of ABC-Trans with role-based system credentials and permissions.],
  rows: (
    ("Knows employee identification code, assigned role classification, and home operational branch.", "Branch"),
    ("Applies RBAC permissions after successful authentication to determine which administrative operations an authenticated employee may perform.", "SystemConfiguration"),
    ("Manages administrative resources and triggers workflows (e.g., dispatching, pricing, HR).", "Branch, OrderProcessor, DispatchManager"),
  )
)

#v(1em)

#crc-card(
  "Driver",
  super: "StaffMember",
  author: "Phan Le Minh Hieu",
  desc: [Represents licensed delivery drivers employed by ABC-Trans and assigned to a home branch to operate commercial vehicles.],
  rows: (
    ("Knows driving license number, license class eligibility, and expiration status.", "N/A"),
    ("Knows current duty state (Off-Duty, Available, Dispatched, On-Break).", "N/A"),
    ("Tracks and records cumulative driving duration and shift hours.", "SystemConfiguration"),
    ("Reports active shipment milestones and transit events via mobile app.", "Shipment, ShipmentTracker"),
  )
)

#v(1em)

#crc-card(
  "Order",
  super: "N/A",
  author: "Dang Duy Toan",
  desc: [Represents the legally and commercially binding contract between a Customer and ABC-Trans, defining transit parameters and cargo consignments.],
  rows: (
    ("Knows order ID, creation timestamp, requested pickup/delivery schedules, and status.", "N/A"),
    ("Composes and manages its structural cargo items.", "Consignment"),
    ("Knows its originating customer and chosen service parameters.", "Customer, ServiceOffering"),
    ("Calculates its own base commercial quote based on tariff rules.", "PricingTariff"),
    ("Advances its own contract state upon review (Submitted -> Approved/Cancelled).", "OrderProcessor"),
  )
)

#v(1em)

#crc-card(
  "Consignment",
  super: "N/A",
  author: "Dang Duy Toan",
  desc: [Represents the physical items, packages, or pallets associated with an Order, detailing cargo properties and storage constraints.],
  rows: (
    ("Knows consignment ID, weight parameters, volume metrics, and dimensions.", "N/A"),
    ("Knows physical handling rules (temperature range, fragile, hazardous).", "N/A"),
    ("Validates its own cargo physical measurements against structural capacity rules.", "InvalidDataException"),
  )
)

#v(1em)

#crc-card(
  "Shipment",
  super: "N/A",
  author: "Phan Le Minh Hieu",
  desc: [Represents the physical execution of an approved Order, managing the active logistics resources and transit tracking milestones.],
  rows: (
    ("Knows shipment ID, associated contract order, and assigned logistics resources.", "Order, Vehicle, Driver"),
    ("Knows current transit milestone state (Assigned, Picked Up, In Transit, Delivered).", "N/A"),
    ("Controls and enforces valid operational milestone transitions.", "InvalidDataException"),
    ("Validates requested milestone transitions, applies valid state changes, and notifies observers of successful transit milestone updates.", "ShipmentTracker"),
  )
)

#v(1em)

#crc-card(
  "Vehicle",
  super: "N/A",
  author: "Phan Le Minh Hieu",
  desc: [Represents a commercial delivery vehicle or truck owned by ABC-Trans and managed by a local branch.],
  rows: (
    ("Knows license plate number, vehicle make, cargo type, and physical storage type.", "N/A"),
    ("Knows operational payload limits (maximum weight capacity, maximum volume capacity).", "N/A"),
    ("Knows current utilization state (Available, Dispatched, Maintenance, Inactive).", "N/A"),
    ("Knows its associated branch registration.", "Branch"),
    ("Validates its own maximum payload capacity limits and registration details.", "InvalidDataException"),
  )
)

#v(1em)

#crc-card(
  "Branch",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Represents a regional physical terminal and operational hub of ABC-Trans in Vietnam, acting as the local resource inventory root.],
  rows: (
    ("Knows branch ID, geographical coordinates, contact information, and operating bounds.", "N/A"),
    ("Maintains and aggregates local physical assets and employee pools.", "Vehicle, Driver, StaffMember"),
    ("Queries and lists available local resources for shipment scheduling.", "Vehicle, Driver"),
  )
)

#v(1em)

#crc-card(
  "Invoice",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Represents the legal billing document issued automatically upon order approval, recording payments and outstanding balance.],
  rows: (
    ("Knows invoice ID, associated order contract, billing due date, and outstanding balance.", "Order"),
    ("Knows current payment status (Unpaid, Partially Paid, Paid).", "N/A"),
    ("Composes and manages payment transactions applied against its balance.", "Payment"),
    ("Recomputes outstanding balance and transitions billing status.", "Payment"),
  )
)

#v(1em)

#crc-card(
  "Payment",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Records a single monetary transaction submitted by a Customer to settle an Invoice's outstanding balance.],
  rows: (
    ("Knows payment transaction ID, target invoice, paid amount, and payment timestamp.", "Invoice"),
    ("Knows transaction verification state (Pending, Verified, Settled, Failed).", "N/A"),
    ("Knows selected transaction payment method (Cash, Card, Digital Wallet).", "N/A"),
    ("Updates verification status upon response from gateway controller.", "PaymentProcessor"),
  )
)

#v(1em)

#crc-card(
  "Receipt",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Represents an immutable proof-of-payment document generated after a Payment successfully transitions to the Settled state.],
  rows: (
    ("Knows receipt ID, originating payment reference, transaction details, and billing entity.", "Payment, Invoice"),
    ("Guarantees complete immutability of transaction evidence for tax compliance.", "N/A"),
  )
)

#v(1em)

#crc-card(
  "ServiceOffering",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Defines a specific service tier of logistics provided by ABC-Trans (e.g., Cold Chain, Express, Standard Freight).],
  rows: (
    ("Knows service tier ID, name, description, and operational bounds.", "N/A"),
    ("Knows the regional branch coverage supporting the service tier.", "Branch"),
    ("Validates order feasibility against service capabilities.", "Order"),
  )
)

#v(1em)

#crc-card(
  "PricingTariff",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Represents the mathematical pricing rules and rate configurations governing a ServiceOffering under various cargo conditions.],
  rows: (
    ("Knows tariff ID, target service offering, base rate, per-km rate, per-kg rate, and multipliers.", "ServiceOffering"),
    ("Calculates precise shipping quotes for a given cargo profile and distance.", "Order, Consignment"),
  )
)

#v(1em)

#crc-card(
  "Report",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Generates analytical insights and aggregated operational performance statistics for branches and executive management.],
  rows: (
    ("Knows report ID, category (Fleet, Financial, Branch), and time range.", "N/A"),
    ("Aggregates metrics and compiles administrative reports.", "Branch, Order, Shipment, Payment, Vehicle, Driver"),
  )
)

#v(1em)

#crc-card(
  "SystemConfiguration",
  super: "N/A",
  author: "Dang Duy Toan",
  desc: [Data-holder class storing global operational variables, security limits, and default constants.],
  rows: (
    ("Knows global system-wide security thresholds and timeout configurations.", "N/A"),
    ("Knows default mathematical pricing constants and operational parameters.", "N/A"),
    ("Exposes read-only parameters to query requests from system components.", "N/A"),
  )
)

#v(1em)

#crc-card(
  "OrderProcessor",
  super: "N/A",
  author: "Dang Duy Toan",
  desc: [Coordinating controller managing the complete lifecycle of customer requests from submission to billing initiation.],
  rows: (
    ("Coordinates order placement, cargo validation, and quote generation.", "Order, Consignment, PricingTariff, Customer"),
    ("Manages dispatcher review and updates order status.", "Order, StaffMember"),
    ("Acts as Factory Method to instantiate Invoice upon order approval.", "Order, Invoice"),
    ("Publishes order-approved and invoice-created events to system observers.", "DispatchManager, PaymentProcessor"),
  )
)

#v(1em)

#crc-card(
  "DispatchManager",
  super: "N/A",
  author: "Phan Le Minh Hieu",
  desc: [Coordinating controller managing scheduling decisions and resource assignments for approved shipments.],
  rows: (
    ("Listens to order approval events from the order controller.", "OrderProcessor"),
    ("Queries local branches to locate available vehicles and drivers.", "Branch, Vehicle, Driver"),
    ("Evaluates capacity margins and assigns resources to the delivery.", "Vehicle, Driver, Consignment, Order"),
    ("Acts as Factory Method to instantiate Shipment and transitions status.", "Shipment, Order"),
    ("Publishes shipment-created and resources-assigned events.", "ShipmentTracker"),
  )
)

#v(1em)

#crc-card(
  "ShipmentTracker",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Coordinating controller managing real-time GPS telemetry parsing and transit milestone updates.],
  rows: (
    ("Receives and normalizes GPS tracking streams via telemetry adapters.", "N/A"),
    ("Associates location data with active shipments.", "Shipment"),
    ("Instructs Shipment to update its current milestone.", "Shipment, Driver"),
    ("Maintains the current operational tracking state of active shipments, delegates historical tracking persistence to the infrastructure layer, and exposes real-time transit status queries.", "Shipment"),
  )
)

#v(1em)

#crc-card(
  "PaymentProcessor",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Coordinating controller managing digital gateway integrations, payment states, and receipt generation.],
  rows: (
    ("Listens to invoice creation events from the order controller.", "OrderProcessor"),
    ("Manages transactions through interchangeable payment strategies.", "Invoice, Payment"),
    ("Acts as Factory Method to create Payment and applies transaction state.", "Payment, Invoice"),
    ("Acts as Factory Method to issue immutable Receipt upon settlement.", "Receipt, Payment, Invoice"),
  )
)

#v(1em)

#crc-card(
  "IPaymentGateway",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Standard interface defining the programmatic contract for executing and verifying payments through external financial gateways and e-wallets.],
  rows: (
    ("Defines the standard contract for executing online transactions.", "Payment"),
    ("Defines the standard contract for querying payment verification state.", "N/A"),
  )
)

#v(1em)

#crc-card(
  "ITelemetrySource",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Standard interface defining the programmatic contract for receiving and normalizing GPS tracking and coordinate telemetry feeds from third-party hardware devices.],
  rows: (
    ("Defines the standard contract for receiving raw GPS tracking data.", "N/A"),
    ("Defines the standard contract for normalizing coordinate streams into transit logs.", "Shipment"),
  )
)

#v(1em)

#crc-card(
  "OrderState",
  super: "N/A",
  author: "Dang Duy Toan",
  desc: [Abstract base class representing the current lifecycle state of an Order. Concrete implementations (such as OrderSubmittedState and OrderApprovedState) encapsulate state-specific transition rules and behaviors.],
  rows: (
    ("Knows the active state context and transitional constraints.", "N/A"),
    ("Enforces and executes state transitions (e.g., approve or cancel) on behalf of the Order.", "OrderProcessor, Order"),
    ("Validates and handles operations allowed in the current state.", "InvalidDataException"),
  )
)

#v(1em)

#crc-card(
  "ShipmentState",
  super: "N/A",
  author: "Phan Le Minh Hieu",
  desc: [Abstract base class representing the current transit milestone state of a Shipment. Concrete implementations (such as ShipmentAssignedState and ShipmentInTransitState) encapsulate state-specific transit and tracking behaviors.],
  rows: (
    ("Knows the active milestone state context and transition rules.", "N/A"),
    ("Enforces valid operational milestone transitions and checks state feasibility.", "Shipment, ShipmentTracker"),
    ("Validates requested milestone changes and raises transition exceptions.", "InvalidDataException"),
  )
)

#v(1em)

#crc-card(
  "InvoiceState",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Abstract base class representing the billing and payment state of an Invoice. Concrete implementations (such as InvoiceUnpaidState and InvoicePaidState) manage state-specific calculations and payment applications.],
  rows: (
    ("Knows the active billing state context and payment settlement status.", "N/A"),
    ("Applies a payment transaction against the outstanding balance.", "Invoice, Payment"),
    ("Determines if the invoice is fully settled and transitions status.", "PaymentProcessor"),
  )
)

#v(1em)

#crc-card(
  "PaymentState",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Abstract base class representing the verification and settlement state of a Payment. Concrete implementations (such as PaymentPendingState and PaymentSettledState) manage gateway verification responses.],
  rows: (
    ("Knows the active payment transaction state and settlement progress.", "N/A"),
    ("Processes verification updates and advances state based on gateway response.", "Payment, PaymentProcessor"),
    ("Triggers the creation and issuance of an immutable Receipt upon settlement.", "Receipt"),
  )
)

#v(1em)

#crc-card(
  "IPaymentStrategy",
  super: "N/A",
  author: "Vo Ngoc Nam",
  desc: [Strategy interface defining the standard contract for interchangeable payment methods (e.g., GatewayPaymentStrategy, CashPaymentStrategy).],
  rows: (
    ("Defines the interface for executing and settling a transaction.", "Payment, Invoice"),
    ("Routes verification requests to physical cash handlers or external gateway adapters.", "IPaymentGateway"),
  )
)

#v(1em)

#crc-card(
  "IPricingStrategy",
  super: "N/A",
  author: "Lam An Thinh",
  desc: [Strategy interface defining the standard contract for interchangeable pricing and tariff calculation policies.],
  rows: (
    ("Defines the interface for calculating a precise commercial quote for cargo.", "Consignment"),
    ("Evaluates distance, cargo parameters, and peak multipliers to determine pricing.", "SystemConfiguration"),
  )
)

== Class Relationship Explanation

We used standard relationships to connect our classes and define how they interact. These include inheritance, composition, aggregation, and association.

*Inheritance* models strict *is-a* relationships. `Person` is an abstract base class holding common details like name and contact info. `StaffMember` inherits from `Person` and adds credentials and permissions. `Driver` inherits from `StaffMember` because drivers are employees but have additional attributes like license types and shift times. This setup avoids duplicating shared user fields. Our design pattern abstractions like `OrderState` and `IPaymentStrategy` also use inheritance to define standard contracts for their concrete subclasses.

*Composition* represents a strong relationship where one object owns another and manages its lifecycle. For example, an `Order` composes its `Consignment` items because a consignment has no meaning without a parent order; deleting an order would logically delete its consignments. Similarly, an `Invoice` owns the `Payment` records against it, and a `Payment` owns its `Receipt`. For state management, classes with complex lifecycles like `Order` and `Shipment` compose their active state objects, as these state instances only exist during the lifetime of their host object.

*Aggregation* models looser relationships where child objects can exist on their own. For instance, a `Branch` aggregates local `Vehicle` and `Driver` objects. If a branch closes, we do not delete its trucks and drivers; instead, we transfer them to another branch.

*Association* represents a simple operational link between classes. A `Customer` has a one-to-many link to `Order`. An `Order` references a `ServiceOffering`, which points to a `PricingTariff`. An `Order` can be fulfilled by one or more `Shipment` objects, allowing us to split consignments within a single commercial contract across separate trucks or schedules. Finally, controllers maintain temporary associations with the domain objects they coordinate during active workflows.

== Design Justification

We applied GRASP heuristics to decide where to place each responsibility:

*Customer and Person:* `Customer` is the *Information Expert* for customer profiles, managing its own details and order history. Putting shared demographic info in the abstract `Person` class reduces duplicate fields and keeps cohesion high.

*Order and Consignment:* An `Order` represents the commercial contract, while a `Consignment` represents the physical cargo. Splitting them lets us track weight, volume, and temperature rules on the consignment without cluttering the order itself. Under GRASP, the order is the *Creator* of its consignments.

*Shipment:* Separating `Shipment` from `Order` is an application of *Protected Variations*. An order is a stable financial agreement that should not change. A shipment is the practical execution of that agreement. It can change dynamically, such as swapping drivers or trucks, without altering the original order or invoice.

*Vehicle and Driver:* These classes are the *Information Experts* for vehicle capacities, driver licenses, and availability. Keeping these checks inside the respective classes ensures scheduling decisions are based on accurate, local data.

*Branch:* A `Branch` serves as the aggregation root for local vehicles and drivers. This keeps asset pools regional, making queries faster and keeping branches independent.

*Invoice, Payment, and Receipt:* We separated billing calculations (`Invoice`), transaction processing (`Payment`), and proof of payment (`Receipt`). The invoice acts as the *Creator* of the payment, which then triggers the receipt. This separation keeps our records auditable and compliant with accounting laws.

*ServiceOffering and PricingTariff:* Separating what we offer (`ServiceOffering`) from how we charge (`PricingTariff`) is another use of *Protected Variations*. We can adjust seasonal prices or add surcharges without changing our core service offerings.

*Report and SystemConfiguration:* Placing metrics in a separate `Report` class keeps our operational classes focused, maintaining *high cohesion*. `SystemConfiguration` is a *Pure Fabrication* class that holds system-wide settings without introducing mutable global variables.

*OrderProcessor, DispatchManager, ShipmentTracker, and PaymentProcessor:* These four controller classes act as *Facades* for our primary workflows. They prevent domain entities from getting bloated with complex coordination logic and insulate the inner domain model from portal-specific details.

Overall, our model distributes responsibility cleanly. Each class does one thing well, depends on as few collaborators as possible, and hides variation behind stable abstractions.

= Design Quality

This section evaluates our object design against Responsibility-Driven Design principles and the quality goals we set in Assignment 1. This review ensures our design is easy to maintain, extend, and implement in our upcoming coding work.

We intentionally left user interfaces, database schemas, and external systems out of our core model. This keeps our design focused strictly on business concepts like orders, shipments, vehicles, invoices, and payments. Our four workflow controllers manage all the coordination, isolating database calls, login checks, GPS protocols, and payment gateways from our core domain logic.

#figure(
  table(
    columns: (1.6fr, 3.2fr, 3.2fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Quality Attribute], th[Object Design Response], th[Relevant Classes or Boundaries],

    [Security],
    [Access-channel and authentication mechanisms are kept outside the domain model, while sensitive financial workflow responsibilities are isolated.],
    [`PaymentProcessor`, `Payment`, `Invoice`, `Receipt`, `StaffMember`],

    [Reliability],
    [Commercial records, operational execution, and financial evidence are separated so failure or change in one area does not corrupt another.],
    [`Order`, `Shipment`, `Invoice`, `Receipt`],

    [Performance],
    [High-frequency telemetry is isolated from transactional ordering and billing responsibilities.],
    [`ShipmentTracker`, `Shipment`, `Vehicle`],

    [Scalability],
    [Domain and controller boundaries mirror the modular architecture recommended in Assignment 1.],
    [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`],

    [Maintainability],
    [Classes are organised around cohesive domain concepts with explicit collaborator boundaries.],
    [`Customer`, `Branch`, `Driver`, `Vehicle`, `PricingTariff`, `ServiceOffering`],
  ),
  caption: [Quality Attribute Traceability to Object Design],
) <tbl-quality-traceability>

== Design Heuristics

Object-oriented heuristics are more than just theory; they served as the concrete rules that kept us from building a tangled mess. These guidelines helped keep our classes small, focused, and decoupled.

=== Responsibility-Driven Design

We built our model around Responsibility-Driven Design (RDD). Instead of asking what variables each class should store, we asked what behaviors it should perform. We were strict about this: a class only made the final list if it had a distinct, active job that no other class could do.

For example, it was tempting to merge `Order` and `Shipment`, but they represent two different things. An order is a commercial contract that should never change after approval. A shipment is the operational reality on the road. If a truck breaks down and a dispatcher has to swap vehicles in transit, that is a shipment update. The original commercial order and its invoice stay exactly as they were.

We also separated `ServiceOffering` and `PricingTariff` because they change for different reasons. The service offering defines what services we offer, while the pricing tariff defines how we calculate costs based on weight, distance, or season. This division protects our scheduling and dispatch system from changes in pricing policy.

We only added controllers where a workflow spans multiple domain classes. `OrderProcessor` handles order submission and approval, `DispatchManager` coordinates scheduling, `ShipmentTracker` manages real-time GPS coordinates, and `PaymentProcessor` handles gateways and receipts. These controllers are not 'god' managers; they are strictly limited to their specific use cases.

#figure(
  table(
    columns: (2fr, 3fr, 3fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Responsibility Area], th[Primary Owner], th[Main Collaborators],

    [Customer account and order request],
    [`Customer`, `OrderProcessor`],
    [`Order`, `Consignment`, `ServiceOffering`, `PricingTariff`],

    [Order approval and invoice triggering],
    [`OrderProcessor`],
    [`Order`, `Invoice`, `PricingTariff`, `StaffMember`],

    [Vehicle and driver assignment],
    [`DispatchManager`],
    [`Shipment`, `Vehicle`, `Driver`, `Branch`],

    [Real-time shipment tracking],
    [`ShipmentTracker`],
    [`Shipment`, `Vehicle`, `Driver`, `Branch`],

    [Payment verification and receipt generation],
    [`PaymentProcessor`],
    [`Invoice`, `Payment`, `Receipt`, `Customer`],

    [Reporting and configuration],
    [`Report`, `SystemConfiguration`],
    [`Branch`, `Order`, `Shipment`, `Vehicle`, `Driver`, `Payment`],
  ),
  caption: [Responsibility Allocation Across SmartFM Classes],
) <tbl-responsibility-allocation>

=== High Cohesion

Every class in our model organizes its responsibilities around a single, highly focused concept. Take `Vehicle` as an example. It does not calculate shipping rates or track driver shifts; it strictly manages vehicle identity, weight capacity, and maintenance status. Similarly, `Driver` deals only with licenses and shift hours. We were especially careful with billing. By splitting `Invoice`, `Payment`, and `Receipt` into separate classes, we ensure that a change to our tax-receipt format cannot break our payment validation logic. Small, cohesive classes make the design much easier to understand, allowing us to implement and test different modules in parallel without running into conflicts.

=== Low Coupling

Because tight coupling makes code hard to maintain, we worked to keep class dependencies as loose as possible. Our classes interact through clean, logical boundaries rather than internal details. For example, `Order` links to `Customer` and `Invoice` but knows nothing about how credit cards are verified or how GPS devices stream coordinates. Likewise, a `Shipment` links to a `Vehicle` and a `Driver` but is completely decoupled from pricing calculations. If ABC-Trans changes its GPS hardware next year, we will not need to touch `Shipment` or `Driver`. This decoupling matches the modular, event-driven structure we proposed in our SRS, making it straightforward to scale or refactor individual modules later.

=== Information Expert

Following GRASP guidelines, we placed each responsibility in the class that holds the information needed to complete it. In our model, `PricingTariff` is the expert for price calculations because it stores the base rates and weight modifiers. `Branch` manages local assets because it knows which vehicles and drivers are registered at its depot. Keeping behavior close to the data avoids having 'dumb' data-holder classes manipulated by external manager classes. If we need to update our pricing formulas, we only have to change `PricingTariff`.

=== Separation of Stable and Volatile Concepts

Separating stable concepts from volatile ones helps protect our core business rules. An `Order` is stable: it represents a permanent commercial contract. On the other hand, a `Shipment` is highly volatile because road conditions are unpredictable. If a truck breaks down, a dispatcher can assign a new vehicle and driver to the active `Shipment` without modifying the original `Order` or changing the invoice amount. The same applies to billing: a `ServiceOffering` (like Cold Chain) is a stable service capability, while its `PricingTariff` is volatile and can change due to fuel costs or seasonal surcharges. This separation helps us meet the reliability and auditing requirements of our system.

=== Avoidance of God Classes

We made sure to avoid god classes, which are those bloated objects that try to do everything and make code impossible to maintain. During our early brainstorming, we proposed classes like `Inventory`, `NotificationService`, and `UserAccount`. We soon realized these were design traps. A global `Inventory` class would duplicate data that our local `Branch` objects already manage. Similarly, sending emails or tracking credentials are infrastructure tasks. Leaving them out kept our core domain model clean and focused strictly on logistics.

=== Encapsulation of External Volatility

Our logistics platform must integrate with external systems like GPS hardware and payment gateways. These external services are volatile and can change their APIs without warning. To insulate our core domain, we encapsulated all external interactions behind strict controller boundaries: `ShipmentTracker` handles telemetry streams, and `PaymentProcessor` manages gateway transactions. If ABC-Trans upgrades its GPS hardware or switches payment providers, the changes remain confined to specific adapter implementations, leaving the rest of our shipment tracking and invoicing logic completely unaffected.

=== Design Heuristic Summary

#figure(
  table(
    columns: (2fr, 4fr, 4fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Heuristic], th[Application in SmartFM], th[Design Quality Impact],

    [Responsibility-Driven Design],
    [`Order`, `Shipment`, `Invoice`, `Payment`, `Vehicle`, `Driver`, and controller classes are selected according to clear business responsibilities.],
    [Prevents arbitrary class selection and gives each CRC card a defensible purpose.],

    [High Cohesion],
    [Each class groups responsibilities around one domain concept or one workflow area.],
    [Improves readability, reviewability, and maintainability for Assignment 3 implementation.],

    [Low Coupling],
    [Controllers coordinate workflows without exposing database, UI, GPS, or payment-gateway details to domain classes.],
    [Supports modular deployment and reduces the impact of changing external integrations.],

    [Information Expert],
    [Pricing rules belong to `PricingTariff`, dispatch context belongs to `Branch` and `DispatchManager`, and tracking state belongs to `ShipmentTracker`.],
    [Places business decisions where the necessary information already exists.],

    [Stable versus Volatile Separation],
    [`Order` is separated from `Shipment`, `ServiceOffering` is separated from `PricingTariff`, and `Receipt` is separated from `Payment`.],
    [Allows operational and financial rules to change without corrupting stable commercial records.],

    [Avoid God Classes],
    [Broad candidates such as `Inventory`, `UserAccount`, and `NotificationService` are not included as core domain classes.],
    [Keeps the object model focused and prevents excessive responsibility concentration.],
  ),
  caption: [Design Heuristic Summary],
) <tbl-design-heuristics>

= Design Patterns

In this section, we describe the design patterns we chose from the classic Gang-of-Four catalogue @gof1994. We selected patterns to solve specific problems from Assignment 1. Each pattern helps us meet our quality goals, such as maintainability, reliability, scalability, and extensibility.

== Creational Patterns

=== Factory Method Pattern

We used the Factory Method pattern to manage how objects are created during complex workflows, keeping creation rules out of our client classes. Instead of letting any class instantiate objects, we assigned this job to specific workflow controllers. While these controllers directly instantiate domain objects in a simple factory style, they represent our primary implementation of the GRASP *Creator* pattern, centralizing creation logic to protect object encapsulation.

`OrderProcessor` handles creating an `Order` and its `Consignment` items when a customer submits a request. Once an order is approved, this controller creates the `Invoice` using the selected `ServiceOffering` and `PricingTariff`. Centralizing this logic keeps `Customer`, `Invoice`, and `Consignment` decoupled from each other.

`PaymentProcessor` does something similar for billing: it only creates a `Payment` record after the gateway confirms a transaction, and only issues a `Receipt` once the payment is settled. This prevents premature receipts and keeps financial records accurate.

These rules ensure that our business rules are always followed. For instance, you cannot have an `Invoice` without an approved `Order`, or a `Receipt` without a verified `Payment`. The Factory Method pattern guarantees these lifecycle boundaries are never bypassed.

=== Singleton-Style Controlled Configuration Instance

`SystemConfiguration` is a data-holder class loaded once at startup. Having a single, controlled configuration instance ensures system settings like session timeouts, login limits, and default pricing rates stay consistent across all branches.

We kept this pattern simple. `SystemConfiguration` is not a god-object and does not manage workflows; it simply holds settings that other classes query. Loading it during bootstrap gives all dependent classes access to correct defaults as soon as they are created.

Using a read-only configuration instance keeps things consistent and avoids the testing headaches of mutable global singletons. We also avoided the service-locator anti-pattern, keeping `SystemConfiguration` strictly focused on simple data storage.

== Behavioural Patterns

=== Strategy Pattern

We used the Strategy pattern to isolate business rules that change independently of the classes using them. In Assignment 1, we highlighted two main areas of change: payment gateway integrations and pricing calculations.

To support various payment options like gateways, e-wallets, and cash, `PaymentProcessor` uses interchangeable strategies implementing the `IPaymentStrategy` interface, such as `GatewayPaymentStrategy` (which delegates tasks to `IPaymentGateway`) and `CashPaymentStrategy`. This avoids hardcoding provider-specific code into `Payment` or `Invoice`. As a result, we can swap payment gateways without touching our financial entities.

For pricing, `ServiceOffering` delegates to the `IPricingStrategy` interface. `PricingTariff` is a concrete strategy class that calculates costs based on distance, weight, and branch locations. Putting this logic in strategy objects lets us adjust rates or add peak surcharges, by adding a new strategy class like `PeakPricingStrategy`, without changing the stable `ServiceOffering` or `Order` classes.

This makes the system easy to extend. If ABC-Trans adds loyalty discounts or promotional campaigns later, we can implement them as new pricing strategies without altering existing class relationships.

=== Observer Pattern

The Observer pattern decouples event sources from downstream actions, ensuring state changes do not introduce tight dependencies. Key events in SmartFM include order approvals, resource assignments, delivery milestones, and payment confirmations.

For example, when a dispatcher approves an `Order`, the system must generate an invoice, alert dispatchers, and update logs. If `Order` had to call all these classes directly, it would become highly coupled. Instead, `Order` publishes an approval event, allowing other objects to listen and react through their controllers.

This decoupling aligns with the modular, event-driven architecture we proposed in Assignment 1. While our classes use the Observer pattern for in-memory events right now, these can easily translate into asynchronous domain events in a message queue later, allowing the system to handle delayed processing and error recovery.

=== State Pattern

The State pattern represents complex lifecycles explicitly, letting an object's behavior change based on its current state. Instead of relying on status flags and long if-else blocks, classes like `Order`, `Shipment`, `Invoice`, and `Payment` delegate state-specific behavior to separate state hierarchies: `OrderState`, `ShipmentState`, `InvoiceState`, and `PaymentState`.

Putting these lifecycles into dedicated state classes prevents invalid transitions, like marking a shipment as delivered before it has even been picked up. Each state class controls its own valid transitions. For example, when `Shipment.transit()` is called, the request is delegated to its active `ShipmentState` instance. This state object validates the action and updates the state pointer on the host `Shipment` object, keeping our lifecycle rules self-enforcing.

This explicit state management improves reliability and auditability, and it makes testing much easier since we can verify transitions against a clear state matrix.

#figure(
  table(
    columns: (1.6fr, 3.2fr, 3.2fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Lifecycle Class], th[Typical State Progression], th[Invalid Transition Prevented],

    [`Order`],
    [Submitted → Approved → Shipment Created, or Submitted → Cancelled],
    [Creating a shipment from an unapproved order.],

    [`Shipment`],
    [Assigned → Picked Up → In Transit → Delivered],
    [Marking delivery before pickup or vehicle assignment.],

    [`Invoice`],
    [Generated → Unpaid → Partially Paid → Paid, or Generated → Unpaid → Paid],
    [Generating a receipt while the invoice remains unpaid.],

    [`Payment`],
    [Pending → Verified → Settled, or Pending → Failed],
    [Applying a failed or duplicate payment to an invoice balance.],

    [`Receipt`],
    [Created → Retrieved],
    [Modifying financial proof after issue.],
  ),
  caption: [State Pattern Support for Lifecycle Integrity],
) <tbl-state-lifecycle>

== Structural Patterns

=== Facade Pattern

Our controller classes act as facades for cohesive groups of domain objects. By providing a single entry point, each facade coordinates multi-step workflows without exposing domain complexity to external clients.

`OrderProcessor` is the facade for the ordering workflow, including submission, validation, and invoicing. `DispatchManager` coordinates resource scheduling. `ShipmentTracker` exposes a unified interface for tracking shipments, and `PaymentProcessor` manages the billing facade.

These facades protect the domain layer from our multiple client channels (the web portals, mobile apps, and driver devices). Instead of letting these portals modify domain objects directly, they must go through our stable facades. This prevents inconsistent states and isolates our business logic.

Facades also simplify security checks by centralizing role-based access control. The controllers verify permissions before running a workflow, allowing our domain classes to focus purely on business rules.

=== Adapter Pattern

The Adapter pattern translates external interfaces into stable internal contracts, protecting our system from third-party changes. SmartFM uses adapters to connect with third-party payment gateways and GPS devices.

Payment systems like Stripe or VNPAY use completely different protocols and formats. Because of this, `PaymentProcessor` interacts with them through a generic interface. Concrete adapters translate our internal calls into provider-specific APIs, allowing us to support both domestic e-wallets and international credit cards without friction.

Similarly, GPS hardware vendors send location coordinates in unique formats. `ShipmentTracker` reads normalized data through a telemetry adapter instead of linking directly to hardware-specific protocols. This protects our tracking model from device upgrades and network changes. Under GRASP, these adapters and gateways are *Pure Fabrications*, designed specifically to insulate our domain model from external protocols.

=== Layered Controller Boundary

Our design separates the system into decoupled layers. Domain classes hold core business concepts, controllers coordinate use cases, and infrastructure handles database storage, security, and network connections.

This layered division supports the modular architecture we recommended in Assignment 1, preparing our codebase for future microservice or module splits by defining clean boundaries between billing, dispatch, and tracking.

We do not use UI-centric patterns like MVC because user interface design is out of scope here. In this document, a 'controller' refers strictly to a workflow coordinator rather than a presentation component. Keeping these concerns separate ensures database queries or screen flows never clutter our core business logic.

#figure(
  table(
    columns: (1.8fr, 1.4fr, 1.4fr, 1.4fr, 1.4fr, 1.4fr),
    align: (left + top, center + top, center + top, center + top, center + top, center + top),
    inset: (x: 7pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Pattern], th[Security], th[Reliability], th[Performance], th[Scalability], th[Maintainability],

    [Factory Method], [Medium], [High], [Low], [Low], [High],
    [Singleton-style Configuration], [Medium], [Medium], [Low], [Medium], [Medium],
    [Strategy], [High], [Medium], [Medium], [High], [High],
    [Observer], [Low], [High], [Medium], [High], [High],
    [State], [Medium], [High], [Low], [Low], [High],
    [Facade], [High], [Medium], [Medium], [Medium], [High],
    [Adapter], [High], [Medium], [Medium], [High], [High],
  ),
  caption: [Design Pattern Contribution to Quality Attributes],
) <tbl-pattern-quality>

#figure(
  table(
    columns: (2fr, 2.8fr, 2.8fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[External Variation], th[Protected Internal Boundary], th[Reason for Isolation],

    [Payment provider protocol],
    [`PaymentProcessor` with Adapter and Strategy],
    [Different card and e-wallet providers should not change `Invoice`, `Payment`, or `Receipt`.],

    [GPS device format],
    [`ShipmentTracker` with Adapter],
    [Vehicle tracking hardware may change without changing `Shipment` lifecycle rules.],

    [Pricing policy],
    [`PricingTariff` with Strategy],
    [Fuel surcharges, regional rules, and seasonal pricing can change independently of `ServiceOffering`.],

    [Domain event delivery],
    [Observer-style controller/event boundary],
    [Order approval, payment confirmation, and shipment updates can trigger downstream work asynchronously.],
  ),
  caption: [Isolation of Volatile External and Business Rules],
) <tbl-volatility-isolation>

=== Design Pattern Summary

#figure(
  table(
    columns: (1.8fr, 3fr, 4fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Pattern], th[Main Participants], th[Justification],

    [Factory Method],
    [`OrderProcessor`, `PaymentProcessor`, `Order`, `Invoice`, `Payment`, `Receipt`],
    [Controls creation of workflow-dependent objects and prevents invalid financial or order artefacts from being created independently.],

    [Singleton-style Configuration],
    [`SystemConfiguration`],
    [Provides one consistent set of system-wide configuration values during bootstrap and runtime without turning configuration into a god class.],

    [Strategy],
    [`PaymentProcessor`, `IPaymentStrategy`, `IPricingStrategy`, `PricingTariff`, `ServiceOffering`, `Payment`],
    [Allows payment providers and tariff policies to vary without changing stable domain classes.],

    [Observer],
    [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`, `Report`],
    [Decouples event sources from downstream reactions and aligns the OO design with the asynchronous event layer recommended in Assignment 1.],

    [State],
    [`Order`, `Shipment`, `Invoice`, `Payment`, `OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState`],
    [Makes lifecycle transitions explicit and reduces invalid operational or financial state changes.],

    [Facade],
    [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`],
    [Provides stable workflow entry points for multiple access channels while preserving domain class cohesion.],

    [Adapter],
    [`PaymentProcessor`, `ShipmentTracker`],
    [Isolates SmartFM from third-party payment gateway protocols and GPS hardware data formats.],
  ),
  caption: [Design Pattern Summary],
) <tbl-design-patterns>

= Bootstrap Process

== Overview

The bootstrap process defines the exact order in which SmartFM creates its long-lived objects at startup. This happens before any customer or staff member can make a request. A single startup function drives this sequence to enforce two main rules:

1. No object is created before its dependencies exist. This prevents any class from holding a reference to a missing collaborator.
2. Every Observer subject has its listeners registered before it fires its first event, so no messages are lost.

The startup sequence only instantiates long-lived, structural objects, including system settings, branches, vehicles, drivers, service offerings, and the four controllers. It does not create transactional objects like orders, shipments, invoices, payments, receipts, or reports. These are created on-demand using the Factory Method pattern (see Section 5.1) when a user triggers a workflow.

== Bootstrap Sequence

#figure(
  table(
    columns: (0.5fr, 2.2fr, 2.6fr, 4fr),
    align: (center + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Step], th[Action], th[Classes Created / Loaded], th[Dependency Rationale],

    [1],
    [Load system-wide configuration],
    [`SystemConfiguration`],
    [Loaded first because every other class may query session timeout, maximum failed login attempts, or default tariff values during its own construction.],

    [2],
    [Load the branch network],
    [`Branch` (one instance per operating location)],
    [Depends only on `SystemConfiguration`. `Branch` is the aggregation root for local resources, so it must exist before any resource that a branch owns.],

    [3],
    [Load fleet and personnel resources],
    [`Vehicle`, `Driver`, `StaffMember` instances with assigned roles (Dispatcher, BranchManager, FleetAdministrator, HRStaff, SystemAdministrator)],
    [Requires an existing `Branch` to aggregate into, per Assumptions A4 and A5. Each `Vehicle` and `Driver` registers with exactly one already-created `Branch`.],

    [4],
    [Load the commercial catalogue],
    [`ServiceOffering`, `PricingTariff`],
    [A `ServiceOffering` is available at one or more already-created `Branch` instances, and each `PricingTariff` is associated with a `ServiceOffering`. Both must exist before any `Order` can reference them (Assumption A7).],

    [5],
    [Instantiate the order workflow controller],
    [`OrderProcessor`],
    [Requires the catalogue from Step 4 to validate order requests. Created first among the controllers because it is the Observer-pattern subject for the order-approval and invoice-creation events that later controllers subscribe to.],

    [6],
    [Instantiate the dispatch controller],
    [`DispatchManager`],
    [Registers itself as an observer of `OrderProcessor` before any `Order` can be approved. Requires `Branch`, `Vehicle`, and `Driver` from Step 3 so it can query resource availability immediately once an order is approved.],

    [7],
    [Instantiate the tracking controller],
    [`ShipmentTracker`],
    [Registers itself as an observer of `DispatchManager` so that no vehicle-assignment event is missed once dispatch begins creating `Shipment` objects.],

    [8],
    [Instantiate the payment controller],
    [`PaymentProcessor`],
    [Registers itself as an observer of `OrderProcessor`'s invoice-creation event so every generated `Invoice` is known to the payment workflow before a `Customer` can submit a payment against it.],

    [9],
    [Accept external requests],
    [-],
    [`Customer`, `Order`, `Consignment`, `Shipment`, `Invoice`, `Payment`, `Receipt`, and `Report` objects are created afterwards, on demand, by the appropriate controller in response to a real transaction, and never during bootstrap.],
  ),
  caption: [SmartFM Bootstrap Sequence],
) <tbl-bootstrap-sequence>

#let bootstrap-diagram() = diagram(
  spacing: (2.1cm, 1.3cm),
  {
    class-node((1, 0), "SystemConfiguration", stereotype: "«data-holder»", w: 3.2cm)
    class-node((1, 1), "Branch")

    class-node((0, 2), "Vehicle")
    class-node((1, 2), "Driver")
    class-node((2, 2), "StaffMember")

    class-node((0, 3), "ServiceOffering")
    class-node((1, 3), "PricingTariff")

    class-node((1, 4), "OrderProcessor", w: 2.7cm)

    class-node((0, 5), "DispatchManager", w: 2.7cm)
    class-node((2, 5), "PaymentProcessor", w: 2.7cm)

    class-node((0, 6), "ShipmentTracker", w: 2.7cm)

    // creation dependencies
    edge((1, 0), (1, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (0, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (1, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (2, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (0, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((0, 3), (1, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 3), (1, 4), "->", stroke: 0.8pt + rgb("#1a3a5c"))

    // observer registration (dashed)
    edge((1, 4), (0, 5), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((1, 4), (2, 5), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((0, 5), (0, 6), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
  }
)

#figure(
  block(width: 100%, align(center, bootstrap-diagram())),
  caption: [Bootstrap creation order (solid arrows) and Observer registration order (dashed arrows).],
) <fig-bootstrap>

== Rationale

This startup order ensures referential integrity by design. We never instantiate a class until all its collaborators exist. For example, `Vehicle` and `Driver` are created only after their host `Branch` is set up. `PricingTariff` is created after the `ServiceOffering` it is linked to, and controllers are created only after the domain data they coordinate is loaded.

The controller creation order is also carefully planned. `OrderProcessor` is created first because it is the source of two key events: order approval and invoice creation. `DispatchManager` and `PaymentProcessor` register as observers of `OrderProcessor` as soon as they are constructed. `ShipmentTracker` registers with `DispatchManager` for the same reason. Creating the event source before the observers ensures we never lose events during startup.

This setup also matches our Singleton-style configuration and Facade patterns. `SystemConfiguration` is loaded once at the start and remains read-only. The startup function only creates the four controllers directly. Each controller then acts as a Facade that loads and manages its own domain objects, keeping the bootstrap routine simple and avoiding a bloated startup script.

== Post-Bootstrap Object Creation

We kept transactions and reports completely out of the startup process. `Order` and `Consignment` are only created when a customer submits an order, and `Shipment` is instantiated only when `DispatchManager` assigns a vehicle and a driver. `Invoice` is created when `OrderProcessor` approves an order, while `Payment` and `Receipt` are created by `PaymentProcessor` during billing. Finally, `Report` is only created when a user requests a specific report. This separation keeps the startup fast and ties object creation directly to real business events.

= Design Verification

== Purpose and Method

We verified our design by walking through four core operational scenarios using the CRC card method. For each scenario, we trace how objects send messages to one another, checking two things at every step:

1. The receiving class actually has that responsibility listed on its CRC card in Section 3.
2. The collaboration was already defined in Section 3 or Section 4.

We consider a scenario verified only if we can trace it from start to finish without inventing new classes, responsibilities, or relationships along the way.

These four scenarios correspond to our four controller classes. Together, they exercise every controller, key domain class, and design pattern from Section 5 at least once.

== Scenario 1: Order Placement and Approval

*Trigger.* A `Customer` submits a delivery request for one or more consignments through the customer portal.

*Preconditions.* The `Customer` account exists, and the requested `ServiceOffering` and its `PricingTariff` were loaded during bootstrap (@tbl-bootstrap-sequence, Step 4).

#figure(
  table(
    columns: (0.5fr, 3.0fr, 1.8fr, 3.2fr),
    align: (center + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Step], th[Message / Action], th[Responsible Class], th[Collaborators and Notes],

    [1], [Submit order request \ #raw("customer.placeOrder(details)")], [`Customer`], [Is the Creator of the new `Order` (Section 3.6) and passes its consignment details.],
    [2], [Validate consignment data \ #raw("consignment.validate()")], [`Consignment`], [Raises `InvalidDataException` on a non-positive weight or an over-length field, per Section 1.3.2, before any state commits.],
    [3], [Select service and compute quote \ #raw("tariff.calcQuote(order)")], [`ServiceOffering`, `PricingTariff`], [`PricingTariff` is the Information Expert for cost rules (Section 4.1.4), returning the quoted amount to `OrderProcessor`.],
    [4], [Route request to the order workflow \ #raw("op.submitOrder(order)")], [`OrderProcessor`], [Is the Facade (Section 5.3.1) for the ordering use case, holding the `Order` in a Submitted state (Section 5.2.3).],
    [5], [Approve the order \ #raw("dispatcher.approve(orderId)")], [`StaffMember` (`Dispatcher`)], [Dispatcher reviews and approves through `OrderProcessor`, satisfying Assumption A6 that a `Shipment` cannot be created before approval.],
    [6], [Transition order state \ #raw("order.approve()")], [`Order`], [The context class `Order` delegates the action to its active state object (Section 5.2.3), which validates the transition from Submitted to Approved and updates `Order`'s state context, publishing an order-approved event.],
    [7], [Create the invoice \ #raw("op.createInvoice(order)")], [`OrderProcessor`], [Acts as Factory Method (Section 5.1.1), instantiating `Invoice` from the `PricingTariff` quote, satisfying Assumption A7.],
    [8], [Notify subscribed controllers \ #raw("op.notifyObservers()")], [`DispatchManager`, `PaymentProcessor`], [Both received the order-approved / invoice-created events because they registered as observers during bootstrap (@fig-bootstrap), meaning no explicit call from `Order` to either controller is required.],
  ),
  caption: [Scenario 1 Walkthrough: Order Placement and Approval],
) <tbl-scenario-1>

#let sequence-diagram-1() = diagram(
  spacing: (1.55cm, 0.65cm),
  {
    // Lifelines (Headers)
    node((0, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[Customer], name: <customer>)
    node((1, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:OrderProcessor], name: <op>)
    node((2, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Order], name: <order>)
    node((3, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Consignment], name: <consignment>)
    node((4, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:PricingTariff], name: <tariff>)
    node((5, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[Dispatcher], name: <dispatcher>)
    node((6, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Invoice], name: <invoice>)

    // Vertical lifelines
    edge((0, 0), (0, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((1, 0), (1, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((2, 0), (2, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((3, 0), (3, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((4, 0), (4, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((5, 0), (5, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((6, 0), (6, 8.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))

    // Messages
    edge((0, 1), (1, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [1: placeOrder(details)], label-pos: 0.5)
    edge((1, 2), (3, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [2: validate()], label-pos: 0.5)
    edge((1, 3), (4, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [3: calcQuote(order)], label-pos: 0.5)
    
    // Self-call loop for submitOrder() on OrderProcessor
    edge((1, 4), (1.25, 4.15), (1, 4.3), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [4: submitOrder()], label-pos: 0.5)
    
    edge((5, 5.2), (1, 5.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [5: approve(orderId)], label-pos: 0.5)
    edge((1, 6.2), (2, 6.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [6: approve()], label-pos: 0.5)
    edge((1, 7.2), (6, 7.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [7: <<create>> Invoice], label-pos: 0.5)
    edge((1, 8.2), (0.5, 8.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [8: notifyObservers()], label-pos: 0.5)
  }
)

#figure(
  align(center, scale(80%, reflow: true, sequence-diagram-1())),
  caption: [UML Sequence Diagram for Scenario 1: Order Placement and Approval],
) <fig-seq-scenario-1>

*Verification:* Every responsibility invoked in @tbl-scenario-1 is already on the CRC card of the class performing it, and every collaborator was established in Section 3. These include the links between `Customer` and `Order`, `Order` and `Consignment`, `Order` and `Invoice`, and `OrderProcessor` and `PricingTariff`. The exception in Step 2 confirms the boundary-case validation described in Section 1.3.2. We did not need to invent any new classes or relationships to complete this scenario.

== Scenario 2: Vehicle and Driver Dispatch

*Trigger.* `DispatchManager` receives the order-approved event from Scenario 1 and must assign a vehicle and a driver.

#figure(
  table(
    columns: (0.5fr, 3.0fr, 1.8fr, 3.2fr),
    align: (center + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Step], th[Message / Action], th[Responsible Class], th[Collaborators and Notes],

    [1], [Query available resources \ #raw("branch.getAvailable()")], [`Branch`], [Information Expert (Section 4.1.4) for the vehicles and drivers registered at the origin branch.],
    [2], [Check individual availability \ #raw("vehicle.isAvail(), driver.isAvail()")], [`Vehicle`, `Driver`], [Each is the expert on its own current assignment status (Section 3.6), so unavailable resources are excluded from the candidate set.],
    [3], [Select and bind resources \ #raw("dm.schedule(shipment)")], [`DispatchManager`], [Coordinates the assignment decision as a Facade over `Vehicle`, `Driver`, and `Branch` (Section 5.3.1), meaning no domain entity needs to know the scheduling rule used by another.],
    [4], [Create the shipment(s) \ #raw("dm.createShipments(order)")], [`DispatchManager`], [Is the Factory Method (Section 5.1.1) that instantiates one or more `Shipment` objects per consignment grouping, consistent with Assumption A6 (never before order approval).],
    [5], [Initialize shipment state \ #raw("new Shipment()") (constructor)], [`Shipment`], [The constructor initializes the object and sets its initial active state to `ShipmentAssignedState` (Section 5.2.3), preventing any invalid out-of-order milestone transitions from the outset.],
    [6], [Notify the tracking controller \ #raw("dm.notifyObservers()")], [`ShipmentTracker`], [Received the assignment-created event because it registered as an observer of `DispatchManager` during bootstrap (@fig-bootstrap), and begins monitoring the new `Shipment` without `DispatchManager` calling it directly.],
  ),
  caption: [Scenario 2 Walkthrough: Vehicle and Driver Dispatch],
) <tbl-scenario-2>

*Verification:* This scenario confirms the benefits of low coupling described in Section 4.1.3. `DispatchManager` never needs to know how `Invoice` amounts were calculated, and `Shipment` is completely unaware of how scheduling decisions are made. If no vehicle or driver is available in Step 2, the order simply remains in `OrderApprovedState` while the unassigned shipment is flagged for manual review. This keeps our collaboration boundaries clean and avoids any tight callback loops with `OrderProcessor`.

== Scenario 3: Real-Time Shipment Tracking

*Trigger.* Vehicle-mounted GPS hardware streams a location update for an in-transit `Shipment` (Assumption A9).

#figure(
  table(
    columns: (0.5fr, 3.0fr, 1.8fr, 3.2fr),
    align: (center + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Step], th[Message / Action], th[Responsible Class], th[Collaborators and Notes],

    [1], [Receive normalised telemetry \ #raw("adapter.normalize(stream)")], [`ShipmentTracker`], [Consumes location data through a telemetry adapter (Section 5.3.2), isolating the class from any one GPS vendor's protocol.],
    [2], [Identify the active shipment \ #raw("tracker.getShipment(id)")], [`ShipmentTracker`], [Already holds a reference to the `Shipment` from Scenario 2, Step 6, meaning no lookup through `DispatchManager` or `Order` is needed.],
    [3], [Advance shipment milestone \ #raw("shipment.transit()")], [`Shipment`], [The context class `Shipment` delegates the action to its active state object (Section 5.2.3), which validates the transition and updates `Shipment`'s state context to In Transit (@tbl-state-lifecycle).],
    [4], [Handle invalid transition attempt \ #raw("shipment.deliver()")], [`Shipment`], [If a driver attempts to confirm 'Delivered' while the active state is 'Assigned' (skipping 'In Transit'), the internal state object throws an `InvalidDataException` (Section 5.2.3). `ShipmentTracker` catches it, logs the anomaly, and preserves the current state.],
    [5], [Aggregate current location \ #raw("tracker.updateLocation(coords)")], [`ShipmentTracker`], [Information Expert for real-time position (Section 4.1.4), which means a `Customer` or `StaffMember` querying status reads this state rather than querying `Vehicle` directly.],
  ),
  caption: [Scenario 3 Walkthrough: Real-Time Shipment Tracking],
) <tbl-scenario-3>

*Verification:* This scenario shows how our design handles high-frequency telemetry from outside hardware. It confirms that the Adapter pattern (Section 5.3.2) keeps GPS volatility confined to `ShipmentTracker`. Telemetry updates never touch `Shipment`, `Vehicle`, or `Driver` directly, which directly supports our performance and scalability goals in Section 4. The State pattern manages state validation in Step 4 inside `Shipment`. When `ShipmentTracker` catches an `InvalidDataException`, it logs the issue while keeping our state safe and consistent. We did not need any new classes or relationships to complete this scenario.

== Scenario 4: Payment Verification and Receipt Issuance

*Trigger.* A `Customer` submits a digital payment against an outstanding `Invoice`, or a branch `StaffMember` records a cash payment on the `Customer`'s behalf (Assumption A12).

#figure(
  table(
    columns: (0.5fr, 3.0fr, 1.8fr, 3.2fr),
    align: (center + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Step], th[Message / Action], th[Responsible Class], th[Collaborators and Notes],

    [1], [Submit payment amount \ #raw("customer.submitPayment(invoice, amt)")], [`Customer` or `StaffMember`], [`PaymentProcessor` already knows this `Invoice` exists, having observed its creation in Scenario 1, Step 7.],
    [2], [Validate against outstanding balance \ #raw("invoice.validatePay(amount)")], [`Invoice`], [Rejects any amount exceeding the outstanding balance, per the boundary case in Section 1.3.2, before `PaymentProcessor` proceeds.],
    [3], [Route through settlement strategy \ #raw("pp.settle(payment, paymentStrategy)")], [`PaymentProcessor`], [Selects interchangeable `IPaymentStrategy` implementation (e.g., `GatewayPaymentStrategy`, `CashPaymentStrategy`) (Section 5.2.1) without context coupling.],
    [4], [Create and settle payment \ #raw("pp.createPayment(invoice)")], [`PaymentProcessor`], [Is the Factory Method (Section 5.1.1) that instantiates `Payment` only after gateway verification succeeds.],
    [5], [Transition invoice state \ #raw("invoice.recordPayment(payment)")], [`Invoice`, `Payment`], [Delegates transition rules internally (Section 5.2.3). `Invoice` delegates to its active `InvoiceState` to transition Unpaid State \u{2192} Paid State, and `Payment` transitions Pending State \u{2192} Settled State.],
    [6], [Issue the receipt \ #raw("pp.createReceipt(payment)")], [`PaymentProcessor`], [Instantiates the immutable `Receipt` only once `Payment` reaches Settled, satisfying Assumption A8 and preventing a receipt for an unpaid or failed transaction.],
  ),
  caption: [Scenario 4 Walkthrough: Payment Verification and Receipt Issuance],
) <tbl-scenario-4>

#let sequence-diagram-4() = diagram(
  spacing: (1.55cm, 0.65cm),
  {
    // Lifelines (Headers)
    node((0, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[Customer / Staff], name: <customer>)
    node((1, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:PaymentProcessor], name: <pp>)
    node((2, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Invoice], name: <invoice>)
    node((3, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Payment], name: <payment>)
    node((4, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:IPaymentStrategy], name: <strategy>)
    node((5, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:IPaymentGateway], name: <gateway>)
    node((6, 0), rect(fill: rgb("#f0f4f8"), stroke: 1.2pt + rgb("#1a3a5c"), radius: 3pt, inset: 5pt)[:Receipt], name: <receipt>)

    // Vertical lifelines
    edge((0, 0), (0, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((1, 0), (1, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((2, 0), (2, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((3, 0), (3, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((4, 0), (4, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((5, 0), (5, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))
    edge((6, 0), (6, 7.5), stroke: 0.5pt + rgb("#1a3a5c"), dash: "dashed", marks: (none, none))

    // Messages
    edge((0, 1), (1, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [1: submitPayment(invoice, amt)], label-pos: 0.5)
    edge((1, 2), (2, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [2: validatePay(amount)], label-pos: 0.5)
    edge((1, 3), (4, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [3: settle(payment, strategy)], label-pos: 0.5)
    edge((4, 4), (5, 4), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [4: verify()], label-pos: 0.5)
    edge((1, 5.2), (3, 5.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [5: <<create>> Payment], label-pos: 0.5)
    edge((1, 6.2), (2, 6.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [6: recordPayment(payment)], label-pos: 0.5)
    edge((1, 7.2), (6, 7.2), "->", stroke: 0.8pt + rgb("#1a3a5c"), label: [7: <<create>> Receipt], label-pos: 0.5)
  }
)

#figure(
  align(center, scale(80%, reflow: true, sequence-diagram-4())),
  caption: [UML Sequence Diagram for Scenario 4: Payment Verification and Receipt Issuance],
) <fig-seq-scenario-4>

*Verification:* The ordering of Steps 4 through 6 is exactly what our Factory Method and State patterns guarantee (Sections 5.1.1 and 5.2.3). This prevents creating a `Payment` before the gateway confirms the transaction, or issuing a `Receipt` before settlement. This walkthrough also verifies Assumption A12: because `PaymentProcessor` is the only class that interacts with the payment gateway, we can switch payment providers without touching any other class in this workflow.

== Coverage Summary

#figure(
  table(
    columns: (2.6fr, 2.6fr, 3fr, 2.4fr),
    align: (left + top, left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Scenario], th[Controller Exercised], th[Patterns Exercised], th[Exception / Boundary Verified],

    [1. Order Placement and Approval],
    [`OrderProcessor`],
    [Factory Method, Observer, State],
    [`InvalidDataException` on consignment data],

    [2. Vehicle and Driver Dispatch],
    [`DispatchManager`],
    [Factory Method, Facade, Observer],
    [No available vehicle or driver],

    [3. Real-Time Shipment Tracking],
    [`ShipmentTracker`],
    [Adapter, State],
    [Out-of-order milestone transition (`InvalidDataException`)],

    [4. Payment Verification and Receipt],
    [`PaymentProcessor`],
    [Factory Method, Strategy, State],
    [Payment exceeding outstanding balance],
  ),
  caption: [Design Verification Coverage Summary],
) <tbl-verification-summary>

Together, these four scenarios exercise every controller class, the fourteen core domain classes involved in daily workflows, our state and strategy interfaces, and every design pattern from Section 5. The only exception is the read-only `SystemConfiguration` instance. Administrative and helper classes like `Report` or back-office staff roles support other operations rather than the core transactional workflows. We verified their single-responsibility CRC cards against our heuristics in Section 4, which is sufficient since they do not participate in multi-class workflows.

#colbreak()
#heading(level: 1, numbering: none)[Appendix \ Software Requirements Specification (SRS)] <appendix-srs>

The complete Software Requirements Specification (SRS) developed in Assignment 1 is attached below at full scale.

#counter("appendix").update(1)
#colbreak()


#for page-num in range(1, 32) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm1.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}

