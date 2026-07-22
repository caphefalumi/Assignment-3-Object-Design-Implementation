#import "ieee.typ": *
#import "@preview/wordometer:0.1.5": total-words, word-count
#show: word-count

#show: ieee.with(
  title: "SWE30003 Assignment 1 \n Software Requirements Specification",
  sub_title: " Smart Fleet Management System",
  date_of_submission: "21st June 2026",
  header-left: "Assignment 1",
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

#set heading(numbering: "I.")
#outline()
#colbreak()

= Introduction

This document is the Software Requirements Specification for the Smart Fleet Management System, referred to as SmartFM throughout. Swinsoft Consulting has been engaged by ABC-Trans, a Vietnamese logistics and transportation company, to develop a centralised information system that replaces its current manual and disconnected branch-level processes.

The document specifies the context, domain requirements, quality attributes, and possible solutions for SmartFM using the Tasks and Support method. It is intended to support a formal tender process and to guide subsequent development efforts by clearly stating what the system must do and why.

= Project Overview

ABC-Trans serves major department stores and supermarkets across Vietnam. As the company expands, growing operational pressure has exposed the limitations of its current approach. Vehicle management, driver management, customer order processing, shipment tracking, and payments are either handled manually or through disconnected systems operated independently at each branch. These limitations result in slow service, frequent unavailability, and customer dissatisfaction that prevents the company from scaling further. Swinsoft Consulting has been commissioned to produce a requirements specification for SmartFM, a centralised system that addresses these limitations across all branches.

== Domain Vocabulary

- ABC-Trans: The client company. A Vietnamese logistics and transportation company serving retail and supermarket chains nationwide.
- SmartFM: The Smart Fleet Management System specified in this document.
- Branch: A single operational location of ABC-Trans. Each branch maintains its own fleet and pool of drivers.
- Vehicle: A truck or transport vehicle owned and operated by ABC-Trans at a given branch.
- Driver: An ABC-Trans employee who is licensed to operate a vehicle and is assigned to shipments.
- Customer: A business or individual that contracts ABC-Trans for shipment services. Customers may engage with ABC-Trans in-branch, through the web portal, or through the mobile application.
- Order: A formal customer request for a shipment service submitted through SmartFM.
- Shipment: The physical transport of a consignment from a specified pickup location to a specified delivery location, associated with an approved order.
- Consignment: The goods entrusted to ABC-Trans for transport as part of a shipment.
- Dispatch: The act of assigning an available vehicle and driver to fulfill an approved order.
- Dispatcher: A branch staff member responsible for reviewing incoming orders and performing dispatch.
- Invoice: A billing document issued to a customer detailing the charges for a shipment service.
- Receipt: A document confirming that a payment has been received by ABC-Trans for a given invoice.
- Branch Manager: A staff member responsible for overseeing all operations at a single branch and for reviewing performance statistics.
- Fleet: The collective set of all vehicles owned and operated by ABC-Trans across all branches.
- Real-Time Tracking: Continuous, up-to-date monitoring of a shipment's location and status during transport.
- Resource Utilisation: A measure of how effectively vehicles and drivers are being deployed relative to available capacity over a given period.

== Goals
The SmartFM system is to achieve the following goals:

- Replace all manual and branch-specific processes with a single centralised platform shared across all ABC-Trans branches.
- Enable customers to browse shipment service offerings, verify vehicle and service availability at specific branch locations, place orders, receive invoices, and make payments through a web portal and a mobile application.
- Provide customers and staff with real-time visibility into the location and status of active shipments.
- Support multiple payment methods, including cash, credit or debit card, and digital e-wallets, and automatically generate receipts for customers and internal records.
- Provide branch managers with basic statistics on shipments and resource utilisation across daily, weekly, monthly, annual, and year-to-date periods.
- Maintain accurate and current vehicle and driver records across all branches to reduce errors and improve customer satisfaction.
- Enable staff to process incoming orders efficiently, approve vehicle assignments, and organise delivery and pickup options with minimal delays.

== Assumptions

- ABC-Trans operates multiple branches across Vietnam, each with its own fleet of vehicles and pool of licensed drivers.
- All branches have reliable internet connectivity sufficient to support a centralised web-based system.
- Customers may be business entities or individual consumers.
- All vehicles and drivers are registered to and managed by a specific branch.
- Drivers are assigned to a single branch at any given time.
- Branch staff have at a minimum basic computer proficiency sufficient to operate a web-based interface.
- Third-party payment processors (such as Stripe for international credit cards, and VNPAY or MoMo for local bank transfers and e-wallets) handle all card and digital payment transactions securely on behalf of ABC-Trans.
- Cash payments are accepted in-branch only and are recorded in the system by staff.
- Customers who use online channels have access to a web browser or a compatible smartphone.
- Vehicles are fitted with GPS or equivalent location-tracking technology capable of transmitting location data to SmartFM.
- Discounts and loyalty programs are explicitly out of scope for the initial release of SmartFM and may be incorporated in a future version.
- The Swinsoft Consulting UI/UX Design Guidelines [Swinsoft-UIUX-v3.1] specify all interface standards and do not require further elaboration in this document.
- ABC-Trans will supply a brand guidelines document specifying the official colour palette and typography for use in the system.
- The system covers only the software component. Any hardware or network infrastructure required to deploy SmartFM can be acquired separately.
- SmartFM does not cover customs processing, international freight, or integration with third-party logistics providers.

== Scope

SmartFM is a centralised software platform serving all ABC-Trans branches. It encompasses all customer-facing, operational, and administrative functions described in the Goals (Section 2.2), replacing the current manual and disconnected branch-level processes. The system delivers these functions through three access channels: a customer web portal, a customer mobile application, and a staff web portal for branch personnel and managers. Discounts, loyalty programs, international logistics operations, and third-party logistics integrations are not included in the initial release.

= Problem Domain

== Pain points

*Manual and error-prone operations*
- Vehicle management, driver management, order processing, and payment handling are largely performed by hand or through paper-based records.
- Manual data entry produces frequent errors in order records, customer information, and vehicle status.

*Disconnected branch-specific systems*
- Each branch uses its own tools and records with no shared data across the organisation.
- Company-wide visibility into fleet utilisation, driver availability, and shipment activity is not possible under the current arrangement.
- Data duplication and inconsistencies arise whenever information must be exchanged between branches.

*Absence of real-time shipment tracking*
- Customers receive no updates on their shipment status or location after placing an order.
- Staff have limited visibility into the progress of active shipments, making it difficult to respond to delays or issues promptly.

*Frequent service unavailability*
- Current branch systems experience regular downtime and are not designed for concurrent access by multiple users.
- These outages cause delays in order intake and processing, directly reducing the number of orders that can be handled in a day.


*Inefficient payment handling*
- The current system supports a limited range of payment methods, creating friction for customers who prefer digital or card-based payments.
- Receipt generation is a manual step that introduces delays and increases the risk of inaccurate billing records.


*Scalability constraints*
- The combination of manual processes and disconnected systems means operational capacity cannot grow in line with the company's expansion.
- There is no consolidated view of performance data, making it difficult for management to identify inefficiencies or plan resource allocation.

== Domain Entities

- Customer
- Vehicle
- Driver
- Order
- Shipment
- Consignment
- Invoice
- Receipt
- Payment
- Branch
- Report
- Service Offering
- Pricing Tariff

== Actors

- Customer (registered account holder who places orders and makes payments)
- Guest Customer (unregistered user who browses service offerings without an account; see Task 2)
- Driver
- Dispatcher
- Branch Manager
- Fleet Administrator (manages vehicle records, maintenance, and branch fleet assignment; see Task 10)
- HR Staff (manages driver licensing, contracts, and branch assignments; see Task 11)
- System Administrator (manages system configuration, pricing tariffs, user accounts, and RBAC permissions; see Task 15)

== Tasks

- Register customer account
- Browse and search for shipment services
- Place a shipment order
- Process and approve an order
- Assign vehicle and driver to an order
- Track shipment in real-time
- Record pickup and delivery milestones
- Process payment
- Generate receipt
- Manage vehicle information
- Manage driver information
- Generate statistics and reports
- Update customer account information
- Cancel or modify an order
- Manage system configuration

= Data Model

== Domain Model (Entity-Relationship Diagram)

The following unified Entity-Relationship (ER) diagram illustrates the domain entities and their primary logical relationships within the SmartFM system. In accordance with the project guidelines, specific attributes are omitted from this diagram and description to focus strictly on structural domain concepts and to prevent prescriptive solution implementation.

#figure(
  image("images/db.png"),
  caption: [SmartFM Unified Domain Model (Entity-Relationship Diagram)],
)

== Entity Descriptions

The core entities that comprise the SmartFM domain model are defined below:

- *Customer*: A business entity (such as a department store or supermarket chain) or an individual consumer that contracts with ABC-Trans for logistics and transportation services. Customers can create accounts, check service availability, place orders, receive invoices, make payments, and monitor their shipments in real-time.
- *Branch*: A physical, regional office and operational terminal of ABC-Trans in Vietnam. Each branch manages its own local fleet of vehicles and driver pool, and serves as either the origin (pickup) or destination (delivery) hub for shipments.
- *Vehicle*: A motorized commercial transport truck or delivery vehicle owned and operated by ABC-Trans. Vehicles are permanently managed by a specific branch and are dispatched dynamically to fulfill active shipments based on their availability.
- *Driver*: A licensed driver employed by ABC-Trans. Each driver is registered at a home branch. Drivers are responsible for operating vehicles, completing shipments, and updating their status via their mobile application.
- *Order*: A formal customer request for shipping services, containing pickup and delivery parameters, target schedules, and consignment specifications. An order must be reviewed and approved by a dispatcher before it is dispatched as a shipment.
- *Consignment*: The specific physical package, pallet, or set of goods entrusted to ABC-Trans for transport as part of a Customer's overall Order. An order may contain one or many consignments, each potentially requiring distinct handling or storage conditions.
- *Shipment*: The physical execution and operational tracking of an approved Order. It represents the actual transit of consignments from their pickup source to their delivery destination, and is assigned exactly one driver and one vehicle.
- *Invoice*: A financial billing document generated automatically by the system upon the dispatcher's approval of an Order. It details the line-item costs, taxes, and total charges for the logistics services to be rendered.
- *Receipt*: A document issued to the customer confirming that a payment has been received for a specific invoice. It records the payment method, amount, timestamp, and the invoice it settles. Receipts are immutable once generated and are retained for audit purposes.
- *Payment*: An active transaction representing the transfer of funds from the Customer to ABC-Trans to settle an Invoice. Payments can be made online via credit/debit card, or in-branch via cash (recorded manually by branch staff).
- *Report*: A system-generated summary of operational data for a specified branch and time period. Reports cover shipment volumes, payment totals, vehicle utilisation, and driver workload. They are generated on demand or by schedule and are accessible only to authorised branch managers.
- *Service Offering*: A defined logistics service tier provided by ABC-Trans (such as Same-Day Express, Standard Freight, or Cold-Chain Refrigerated Transport) that specifies the handling capabilities, transit speed guarantees, and operational constraints.
- *Pricing Tariff*: A structured rate schedule associated with a Service Offering that defines the billing rules, base rates, distance-based surcharges, weight/volume brackets, and peak-period multipliers used to calculate shipment costs.

== Relationship Descriptions

The logical associations between entities in the SmartFM domain are specified as follows:

- *Customer ↔ Order (1-to-Many)*: A Customer can place zero or many Orders over time, whereas each Order must be associated with exactly one originating Customer.
- *Order ↔ Consignment (1-to-Many)*: A single Order must contain at least one Consignment, and can contain many Consignments, representing various goods being shipped together.
- *Order ↔ Invoice (1-to-1)*: Each approved Order generates exactly one Invoice for the customer.
- *Invoice ↔ Payment (1-to-1)*: An Invoice is settled by exactly one Payment transaction.
- *Payment ↔ Receipt (1-to-1)*: A verified Payment generates exactly one Receipt. Each Receipt is linked to exactly one Payment and confirms that the associated Invoice has been settled. No Receipt can exist without a corresponding verified Payment.
- *Order ↔ Shipment (1-to-1)*: Once approved and dispatched, an Order is fulfilled by exactly one physical Shipment.
- *Shipment ↔ Vehicle (Many-to-1)*: A Shipment is assigned exactly one Vehicle for transport. Over time, a single Vehicle is used for many separate Shipments, but it can only be assigned to one active Shipment at any given time.
- *Shipment ↔ Driver (Many-to-1)*: A Shipment is assigned exactly one Driver. A Driver performs many separate Shipments sequentially, but is isolated to one active Shipment at a time.
- *Vehicle ↔ Branch (Many-to-1)*: A Vehicle is registered to and managed by exactly one home Branch. A Branch manages a fleet consisting of multiple Vehicles.
- *Driver ↔ Branch (Many-to-1)*: A Driver is employed by and registered at exactly one home Branch. A Branch manages a pool of multiple Drivers.
- *Shipment ↔ Branch (Many-to-One, Twice)*: Each Shipment is linked to exactly one Origin Branch and exactly one Destination Branch. A single Branch acts as the origin or destination terminal for many concurrent and sequential Shipments.
- *Order ↔ Service Offering (Many-to-1)*: An Order selects exactly one Service Offering, while a Service Offering can be selected by many Orders over time.
- *Service Offering ↔ Pricing Tariff (1-to-Many)*: A Service Offering has one or many Pricing Tariffs defining its rates under different conditions (e.g., distance bands, weight brackets). Each Pricing Tariff belongs to exactly one Service Offering.
- *Service Offering ↔ Branch (Many-to-Many)*: A Branch provides multiple Service Offerings, and a Service Offering is available at multiple Branches.

== Architectural Rationale and Design Justifications

To ensure that the SmartFM system behaves as a resilient, flexible, enterprise-grade logistics platform, several deliberate decoupling decisions have been integrated directly into the domain model. These design choices prevent the architectural "rigidity" and "fragility" common in legacy logistics systems by isolating commercial intent from physical operational execution.

=== Order versus Shipment Decoupling
A common anti-pattern in simple systems is to combine the customer's order and the physical transport shipment into a single entity. In SmartFM, these are strictly separated as a 1-to-1 relationship (`Order ↔ Shipment`).
- *The "Why"*: An `Order` represents a static commercial and legal contract between the Customer and ABC-Trans, capturing commercial SLAs, payment obligations, delivery dates, and cargo details. Conversely, a `Shipment` represents the dynamic operational execution of that contract on the road.
- *Business Justification*: Decoupling these entities ensures that if a truck breaks down during transport on National Route 1A, or if a driver exceeds their legal driving shift, dispatchers can reassign a new `Vehicle` or `Driver` to the active `Shipment`, or split the cargo at a regional `Branch` without modifying or duplicating the legally binding `Order` or `Invoice` originally issued to the customer. This ensures complete contract immutability while maintaining operational agility.

=== Order versus Consignment Decoupling
Rather than treating cargo as a collection of text fields on the order record, the cargo is modeled as an independent entity, `Consignment`, in a 1-to-Many relationship with `Order`.
- *The "Why"*: A single commercial order placed by a major supermarket chain (such as Co.opmart or WinMart) often consists of highly heterogeneous goods, where some require dry storage and others require specialized refrigeration.
- *Business Justification*: By separating the `Order` from individual `Consignments`, the system supports split-routing and specialized handling. The dispatcher can assign a refrigerated consignment within the order to a "Cold-Chain" service vehicle while routing the dry-van goods on a standard vehicle under the same customer order. This drastically reduces shipping delays and avoids the commercial complexity of managing multiple independent orders for a single business transaction.

=== Service Offering versus Pricing Tariff Decoupling
The system separates the available service capabilities (`Service Offering`) from the physical costing rules (`Pricing Tariff`) in a 1-to-Many relationship.
- *The "Why"*: A service capability (e.g., Same-Day Express, Cold-Chain Transport) remains operationally consistent over time, but the financial rules governing its cost are subject to constant business adjustment.
- *Business Justification*: Decoupling these entities allows ABC-Trans marketing and finance managers to dynamically adjust pricing rules, such as introducing seasonal fuel surcharges, peak-period multipliers during Lunar New Year (Tet) holiday traffic, or promotional regional discounts, without having to alter the underlying core scheduling, routing, or dispatching workflows. This isolates business policy from system operations.

== Database Paradigm Selection and Architectural Trade-offs

A critical architectural decision for SmartFM is selecting the database paradigm that manages these core entities. A single, monolithic database approach is insufficient for a nationwide system that handles both highly consistent transaction data and high-frequency real-time telemetry.

=== Transactional Domain Model: Relational (SQL) Paradigm
For the core system state (comprising `Customer`, `Branch`, `Vehicle`, `Driver`, `Order`, `Invoice`, and `Payment`), a *Relational (SQL) Database Management System (such as PostgreSQL)* has been selected. Relational databases are chosen primarily because transactional logistics data requires absolute ACID (Atomicity, Consistency, Isolation, Durability) guarantees and strict referential integrity. For instance, when processing a payment (*Task 8*), the creation of a `Payment` record and the status transition of an `Invoice` from 'Unpaid' to 'Paid' must happen atomically to prevent billing discrepancies. Furthermore, SQL's strict foreign-key constraints prevent severe operational data errors, such as double-booking a `Driver` or `Vehicle` to two active shipments simultaneously, or assigning a shipment to a non-existent vehicle ID.

While a relational database guarantees absolute consistency, it introduces an architectural trade-off: SQL databases do not scale horizontally as easily as NoSQL systems, and under extreme peak write loads (such as the massive influx of concurrent order submissions during the Pre-Tet holiday season), write locking on relational tables can cause connection bottlenecks. To mitigate this scale limitation, ABC-Trans will implement database Read Replicas. This architectural design pattern offloads read-heavy operational queries (*Task 12*) and map-rendering lookups from the primary transactional database node, ensuring that the primary database's write capacity remains dedicated to real-time order processing and dispatching.

=== Fleet Telemetry Model: Time-Series NoSQL Extension
Conversely, for high-frequency tracking of vehicle locations (*Task 6: Track shipment in real-time*), a *Time-Series / NoSQL partition (specifically, PostgreSQL's TimescaleDB extension or a Redis geospatial cache)* is utilized. This hybrid database strategy is justified because active tracking involves hundreds of GPS devices streaming coordinates every 5 to 10 seconds. Storing this high-volume, append-only data stream directly in standard relational tables would cause rapid index degradation, severe database bloat, and transactional lock contention, directly degrading core payment and ordering operations.

By utilizing a time-series partition, the system gains massive horizontal write throughput and optimized geospatial range queries. The architectural trade-off of this NoSQL-style partition is the sacrifice of complex multi-table transactional guarantees and immediate consistency. This is resolved by entirely decoupling the telemetry logs from core operations; the telemetry data is isolated in its own partition and linked to the core transactional model only via a single, immutable `Shipment_ID` foreign key. No telemetry stream writes are permitted to touch or modify the core `Shipment` status table directly. The current location is cached in memory (Redis) for real-time customer map rendering, while the historical route path is written in batches to the partitioned log for post-delivery audits, assuring both high performance and database stability.

#v(1em)

= Functional Requirements and Task Descriptions
#let task-desc(title, purpose, trigger, frequency, critical, workarea, subtasks, variants: ([], [])) = {
  set par(first-line-indent: 0pt)

  table(
    columns: (1fr, 1.25fr),
    stroke: 0.5pt + black,
    inset: 6pt,
    align: left + top,

    table.cell(colspan: 2, fill: rgb("#b7c9e2"), align: center)[*Task:* #title],

    [*Purpose:*], purpose,
    [*Trigger/Precondition:*], trigger,
    [*Frequency:*], frequency,
    [*Critical:*], critical,
    [*Work Area:*], workarea,

    table.cell(fill: rgb("#e1ecf4"))[*Subtasks:*],
    table.cell(fill: rgb("#e1ecf4"))[*Example Solution:*],

    ..subtasks
      .map(st => (
        st.at(0),
        st.at(1),
      ))
      .flatten(),

    table.cell(fill: rgb("#e1ecf4"))[*Variants:*],
    table.cell(fill: rgb("#e1ecf4"))[],

    variants.at(0),
    variants.at(1),
  )

  v(1em)
}

== Task 1: Register Customer Account

#task-desc(
  [Register Customer Account],
  [Allow a new customer to create an account through the web portal, mobile application, or branch service counter.],
  [A customer accesses SmartFM for the first time.],
  [High. Occurs whenever new customers engage with ABC-Trans.],
  [Customer cannot access account, duplicate account exists, or account details are incorrect.],
  [Customer web portal, mobile application, or branch service counter.],
  (
    (
      [1. Enter registration details],
      [The system provides a registration form for contact and billing details.],
    ),
    (
      [
        2. Validate contact and billing information
        Problem: Duplicate account detected.],
      [The system checks existing records. If duplicate, it prompts for login or password recovery.],
    ),
    (
      [3. Create account record],
      [The system creates the customer record and assigns a unique ID.],
    ),
    (
      [4. Send confirmation],
      [The system emails or SMS verifies the customer's account.],
    ),
  ),
  variants: (
    [1a. Branch staff creates account on customer's behalf],
    [Staff members enter details into the branch portal during an in-person visit.],
  ),
)

== Task 2: Browse and Search for Shipment Services

#task-desc(
  [Browse and Search for Shipment Services],
  [Allow customers to view available service offerings and check availability at a selected branch and date.],
  [A logged-in or guest customer accesses the service catalogue.],
  [High. Occurs during the initial discovery phase for most customers.],
  [Service catalog is unavailable or latency exceeds acceptable limits.],
  [Customer web portal or mobile application.],
  (
    (
      [1. Select pickup branch and date],
      [The user inputs their desired logistics parameters.],
    ),
    (
      [
        2. Display available service offerings
        Problem: No services available at the selected branch.],
      [The system queries the database. If none are available, it suggests alternative dates or nearby branches.],
    ),
    (
      [3. Filter by service type, capacity, or destination],
      [The user refines the list using dynamic filters.],
    ),
    (
      [4. View pricing estimate],
      [The system uses the Pricing Tariff to display an estimated cost.],
    ),
  ),
  variants: (
    [1a. Customer searches across multiple branches],
    [The system displays a consolidated view of service offerings across a region.],
  ),
)

== Task 3: Place a Shipment Order

#task-desc(
  [Place a Shipment Order],
  [Allow a customer or branch staff member to create a valid shipment order with complete pickup, delivery, and consignment details.],
  [A customer wants to request a shipment service through the web portal, mobile application, or in-branch service counter.],
  [High. Orders may be created throughout each business day across multiple branches.],
  [Peak order periods where many customers submit shipment requests at the same time.],
  [Customer web portal, mobile application, or branch service counter.],
  (
    (
      [1. Browse available shipment services],
      [The system displays available shipment service offerings, such as standard delivery, express delivery, or special handling options.],
    ),
    (
      [
        2. Enter shipment details
        Problem: Required shipment details are missing or invalid.],
      [The system provides structured fields for pickup location, delivery location, consignment size, weight, preferred date, and contact details. Invalid or missing fields are highlighted before submission.],
    ),
    (
      [
        3. Check service availability
        Problem: Requested service is not available at the selected branch or date.],
      [The system checks branch availability, route coverage, vehicle capacity, and service constraints before allowing the order to proceed.],
    ),
    (
      [4. Confirm estimated quotation and submit order],
      [The system calculates a non-binding estimated cost (a quotation) and allows the customer or staff member to confirm the order submission.],
    ),
    (
      [5. Generate order record],
      [The system creates a unique order reference, stores the order details, and marks the order as pending staff review.],
    ),
  ),
  variants: (
    [1a. Customer modifies the order before confirmation
      1b. Customer requests a service that is unavailable at the selected branch],
    [The system allows order details to be edited before final submission. If unavailable, the system suggests another branch, service date, or service type.],
  ),
)

== Task 4: Process and Approve an Order

#task-desc(
  [Process and Approve an Order],
  [Allow a dispatcher to review a submitted order, validate consignment and scheduling details, and approve or reject the order. This task also calculates cost using the active pricing tariff and triggers invoice generation upon approval.],
  [A new order has been submitted and is pending review.],
  [High. Occurs for every order placed in the system.],
  [Dispatcher interface is unavailable or order details are corrupted.],
  [Dispatcher workstation or branch operations desk.],
  (
    (
      [1. Retrieve pending orders at home branch],
      [The system displays a queue of pending orders filtered by the dispatcher's branch.],
    ),
    (
      [
        2. Review consignment, pickup, and delivery parameters
        Problem: Consignment details are incomplete or out of service range.],
      [The dispatcher reviews the data. The system flags out-of-range requests for manual review.],
    ),
    (
      [3. Approve or reject the order],
      [The dispatcher clicks approve, or rejects with a reason provided to the customer.],
    ),
    (
      [4. Calculate total charges using the active pricing tariff],
      [The system evaluates distance, weight, and service type to compute the final cost based on current pricing rules.],
    ),
    (
      [5. Generate invoice document and associate it with the order],
      [The system automatically creates an immutable billing invoice record linked to the approved order and makes it available to the customer.],
    ),
  ),
  variants: (
    [2a. Dispatcher requests clarification from the customer before approving],
    [The dispatcher uses the system to send an inquiry message to the customer's account.],
  ),
)

== Task 5: Assign Vehicle and Driver to an Order

#task-desc(
  [Assign Vehicle and Driver to an Order],
  [Assign a suitable vehicle to an approved shipment order based on branch, capacity, availability, and operational status.],
  [A shipment order has been reviewed and approved for scheduling.],
  [High. Vehicle assignment occurs for each approved shipment order.],
  [No vehicle is available at the required branch or all suitable vehicles are under maintenance.],
  [Dispatcher workstation or branch operations desk.],
  (
    (
      [1. Review approved shipment requirements],
      [The system displays shipment size, weight, destination, delivery deadline, and special handling requirements.],
    ),
    (
      [
        2. Search suitable vehicles
        Problem: Vehicle capacity or type does not match the shipment.],
      [The system filters vehicles by branch, capacity, availability, maintenance status, and service suitability.],
    ),
    (
      [3. Select vehicle],
      [The dispatcher selects one of the suitable vehicles suggested by the system.],
    ),
    (
      [4. Reserve vehicle for the shipment],
      [The system marks the selected vehicle as assigned and prevents conflicting assignments for the same time period.],
    ),
  ),
  variants: (
    [2a. No suitable vehicle is available
      3a. Dispatcher overrides the recommended vehicle],
    [The system displays alternative branches or later availability. Any manual override must be recorded with a reason for audit purposes.],
  ),
)

== Task 6: Track Shipment in Real-Time

#task-desc(
  [Track Shipment in Real-Time],
  [Provide customers and staff with current shipment status and location visibility during transport.],
  [A shipment has been dispatched and is in progress.],
  [Very high. Tracking updates occur continuously or at regular intervals for active shipments.],
  [GPS data is unavailable, delayed, or inconsistent with driver status updates.],
  [Customer web portal, mobile application, dispatcher dashboard, and driver mobile application.],
  (
    (
      [1. Start shipment tracking],
      [The system activates shipment tracking when the driver confirms dispatch.],
    ),
    (
      [
        2. Receive location and status updates
        Problem: Tracking device stops sending updates.],
      [The system receives GPS or driver-submitted updates and stores them against the shipment record.],
    ),
    (
      [3. Display shipment progress],
      [The system shows customers and staff the current shipment status, estimated progress, and latest known location.],
    ),
    (
      [4. Notify relevant users of delays],
      [The system alerts customers and dispatchers when shipment status indicates delay, route deviation, or delivery issue.],
    ),
  ),
  variants: (
    [2a. GPS signal is lost
      4a. Shipment is delayed due to traffic or operational issue],
    [The system displays the last known location and asks the driver to manually update status when possible. Delay notifications are sent to customers and staff.],
  ),
)

== Task 7: Record Pickup and Delivery Milestones

#task-desc(
  [Record Pickup and Delivery Milestones],
  [Confirm successful delivery of a shipment and store proof of delivery for customer service, audit, and accounting purposes.],
  [A driver arrives at the delivery destination with the shipment.],
  [High. Delivery confirmation occurs for every completed shipment.],
  [Customer is unavailable, delivery is rejected, or proof of delivery cannot be captured.],
  [Driver mobile application and dispatcher dashboard.],
  (
    (
      [1. Confirm arrival at destination],
      [The driver updates the shipment status through the mobile application.],
    ),
    (
      [
        2. Capture proof of delivery
        Problem: Customer is unavailable or refuses delivery.],
      [The system records customer signature, confirmation code, photo evidence, or delivery notes where applicable.],
    ),
    (
      [3. Mark shipment as delivered],
      [The system updates the shipment status to delivered and records delivery time.],
    ),
    (
      [4. Notify customer and staff],
      [The system notifies the customer and relevant branch staff that the shipment has been completed.],
    ),
  ),
  variants: (
    [2a. Delivery exception occurs
      3a. Proof of delivery is submitted offline],
    [The driver records the exception reason and the system escalates it to dispatchers. Offline proof is synchronised when connectivity is restored.],
  ),
)

