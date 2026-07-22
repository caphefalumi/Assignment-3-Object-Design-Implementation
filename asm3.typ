#import "ieee.typ": *
#import "@preview/wordometer:0.1.5": total-words, word-count
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#show: word-count

#show: ieee.with(
  title: "SWE30003 Assignment 3 \n Object Design Implementation and Reflection",
  sub_title: " Smart Fleet Management System",
  date_of_submission: "9th August 2026",
  header-left: "Assignment 3",
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

#let header-fill   = rgb("#1a3a5c")
#let alt-row-fill  = rgb("#f0f4f8")
#let border-stroke = 0.5pt + rgb("#9db3c8")

#let th(content) = table.cell(
  fill: header-fill,
  text(fill: white, weight: "bold", content),
)

#let console(content) = block(
  width: 100%,
  fill: rgb("#0d1117"),
  radius: 4pt,
  inset: 8pt,
  stroke: border-stroke,
  align(left, text(fill: rgb("#c9d1d9"), font: "Consolas", size: 6.8pt, content))
)

#set heading(numbering: "1.")
#outline(title: [Table of Contents])
#colbreak()

#heading(level: 1, numbering: none)[Executive Summary]

Assignment 2 produced a high-level, responsibility-driven object design for the Smart Fleet Management System (SmartFM): twenty core classes, six design pattern abstractions, and two decoupling interfaces, verified against four operational scenarios. This report, Assignment 3, closes the loop between that design and a real, running system. We carried out a detailed design and a working Java 17 implementation covering four business areas: Order Management, Fleet Dispatch, Shipment Tracking, and Billing and Payment. Every core class, State-pattern lifecycle, and Observer wiring from Assignment 2 survived into the implementation with only a small number of documented, justified changes.

Building the system surfaced gaps that a purely conceptual design could not: the class diagram said nothing about how a customer's raw keyboard input becomes a validated `Consignment` object, nor about where twenty in-memory objects live between two runs of the program. We closed both gaps with a textual (CLI) presentation layer and a file-based persistence layer, and we document both as first-class additions to the detailed design in Part I.

We also reflect honestly on Assignment 2. Several aspects (the CRC-based responsibility split, the State and Observer patterns) mapped onto code with almost no friction. Others (the assumption that `Report` and UI concerns could be deferred indefinitely, and the informal boundary rules in Section 1.3.2) required real interpretation and, in a few places, small corrections once we tried to type actual Java against them. Part II, III and IV discuss this in detail, and Part V and VI present the implementation itself together with compilation and execution evidence for all four business areas. Assignment 2 is attached in full as an appendix, as required by the assignment brief.

= Introduction

== Document Overview

This document reports on the detailed design, implementation, and critical reflection carried out for Assignment 3 of the SmartFM project. It is organised to follow the marking guidelines directly:

- *Part I* presents the detailed object-oriented design, including the updated class diagram and an explicit account of what changed and did not change at the class level, the responsibility/collaborator level, and the dynamic (bootstrap and scenario) level, relative to Assignment 2.
- *Part II* discusses the quality of the original Assignment 2 design: what it got right, what was missing, what was flawed, and how much interpretation was required to implement it.
- *Part III* records the lessons learnt from carrying a high-level OO design through to a working implementation.
- *Part IV* identifies and justifies the architecture style(s) of the system at a level of abstraction above individual classes.
- *Part V* describes the implementation itself: language, structure, coding standard, and how the four implemented business areas handle their mutual dependencies.
- *Part VI* presents execution scenarios and the evidence of compilation and correct operation collected while running the system.
- The *Appendix* reproduces the complete Assignment 2 submission, as required so that this report is self-contained.

== Implementation Summary

The SmartFM implementation is a Java 17 project with no runtime dependencies beyond the JDK standard library, built to the standard Maven directory layout (`src/main/java`, `pom.xml`) so it opens directly in any Maven-aware IDE (IntelliJ IDEA, Eclipse, VS Code) and also compiles with plain `javac` when Maven itself is unavailable. It is organised into six packages that mirror the layering already implied by Assignment 2's Entity-Control-Boundary categorisation and its explicit separation of domain, controller, and infrastructure concerns (Assignment 2 Section 5.3.3):

#figure(
  table(
    columns: (1.6fr, 2fr, 4.4fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Package], th[File Count], th[Responsibility],

    [`smartfm.domain`],
    [47 classes/interfaces],
    [Entity classes, State-pattern lifecycle hierarchies, and Strategy/Adapter interfaces from Assignment 2 Section 3.],

    [`smartfm.application`],
    [9 classes/interfaces],
    [The four coordinating controllers, Observer listener interfaces, id generation, and the startup `Bootstrap` sequence.],

    [`smartfm.infrastructure`],
    [1 class],
    [`DataStore`: file-based persistence, the concrete data access layer that Assignment 1 Assumption A1 deferred.],

    [`smartfm.common`],
    [4 classes],
    [Shared exceptions, field-level `Validators`, and a `Money` formatting helper.],

    [`smartfm.ui`],
    [3 classes],
    [`Launcher`: the single entry point selecting between the GUI (default) and CLI (`--cli` flag); `SmartFmConsoleApp` and `ConsoleIO`: the textual user interface for all four business areas.],

    [`smartfm.ui.gui`],
    [10 classes],
    [`SmartFmMainFrame`: the Swing graphical user interface (default), with one panel per business area, plus shared `ValidatedField`/`ResultBanner` widgets and a `GuiContext` holding the single `Bootstrap` instance for the window's lifetime.],
  ),
  caption: [Implementation Package Structure (74 Java files under `src/main/java`, approximately 4,200 lines)],
) <tbl-package-structure>

#figure(
  table(
    columns: (2.4fr, 7.6fr),
    align: (left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Path], th[Purpose],

    [`pom.xml`], [Maven project descriptor: Java 17 source/target, JUnit 5 test dependency, `maven-jar-plugin` configured to produce an executable jar with `smartfm.ui.Launcher` as the main class.],
    [`src/main/java/`], [Production source root (the six packages in @tbl-package-structure), following the Maven-standard convention.],
    [`src/main/resources/`], [Reserved for future non-code resources (icons, property files); currently empty, as the implementation needs no external resources.],
    [`src/test/java/`], [Reserved test source root, following the Maven-standard convention, for unit tests added alongside future iterations of the domain/application layer.],
    [`tools/java/`], [`ScreenshotDriver`, a one-off evidence-capture utility that drives the real GUI through the scenarios in Part VI and saves screenshots. Deliberately kept outside `src/main/java` since it is a development-time tool, not shipped application code.],
    [`scenarios/`, `transcripts/`], [Scripted CLI inputs and their captured console output, used as textual-UI execution evidence (Part VI).],
  ),
  caption: [Top-Level Project Layout (Maven-standard)],
) <tbl-project-layout>

= Part I: Detailed Object-Oriented Design

== Approach

We treated the Assignment 2 class diagram, CRC cards, and bootstrap sequence as the starting contract for implementation, not as a document to redraw from scratch. For every one of the twenty core classes and eight pattern abstractions, we asked three questions while writing the corresponding Java class: does this responsibility still belong here, does this collaborator list still hold, and does the dynamic behaviour (state transitions, event notifications) still happen in the order Assignment 2 specified? Where the answer was yes, we implemented the class exactly as designed. Where the answer was no, we recorded the change and the reason in this section.

== Updated Class Diagram

@fig:uml-updated shows the class diagram as implemented. Every class, interface, and relationship from the Assignment 2 candidate class diagram (reproduced in full in the attached Appendix) is present unchanged; the only additions are the `DataStore` repository facade and the `SystemConfiguration`-to-controller bootstrap dependencies, which make the previously implicit "outside the scope of this high-level design" data access layer (Assignment 2 Assumption A1) an explicit part of the model.

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

#let updated-diagram() = diagram(
  spacing: (3.0cm, 1.7cm),
  {
    class-node((3, -0.75), "ITelemetrySource", stereotype: "«interface»", w: 3.0cm)
    class-node((4, -0.75), "IPaymentGateway", stereotype: "«interface»", w: 3.0cm)

    class-node((0, 0), "SystemConfiguration", stereotype: "«singleton»", w: 3.2cm)
    class-node((1, 0), "OrderProcessor", w: 2.8cm)
    class-node((2, 0), "DispatchManager", w: 2.8cm)
    class-node((3, 0), "ShipmentTracker", w: 2.8cm)
    class-node((4, 0), "PaymentProcessor", w: 2.8cm)

    class-node((1.5, 0.5), "Person", stereotype: "«abstract»", w: 2.3cm)

    class-node((0, 1), "Customer", superclass: "Person", w: 2.3cm)
    class-node((1, 1), "Order", w: 2.3cm)
    class-node((2, 1), "Shipment", w: 2.3cm)
    class-node((3, 1), "StaffMember", superclass: "Person", w: 2.3cm)
    class-node((4, 1), "Invoice", w: 2.3cm)

    class-node((0, 2), "ServiceOffering", w: 2.5cm)
    class-node((1, 2), "Consignment", w: 2.3cm)
    class-node((2, 2), "Vehicle", w: 2.3cm)
    class-node((3, 2), "Driver", superclass: "StaffMember", w: 2.3cm)
    class-node((4, 2), "Payment", w: 2.3cm)

    class-node((0, 3), "PricingTariff", w: 2.3cm)
    class-node((2, 3), "Branch", w: 2.3cm)
    class-node((4, 3), "Receipt", w: 2.3cm)

    class-node((2.2, 4.1), "DataStore", stereotype: "«repository, new»", w: 3.4cm)

    class-node((0.5, 2.5), "IPricingStrategy", stereotype: "«interface»", w: 3.0cm)
    class-node((4.5, 0.5), "IPaymentStrategy", stereotype: "«interface»", w: 3.0cm)
    class-node((1.5, 1.5), "OrderState", stereotype: "«abstract»", w: 2.3cm)
    class-node((2.5, 1.5), "ShipmentState", stereotype: "«abstract»", w: 2.3cm)
    class-node((4.5, 1.5), "InvoiceState", stereotype: "«abstract»", w: 2.3cm)
    class-node((4.5, 2.5), "PaymentState", stereotype: "«abstract»", w: 2.3cm)

    edge((0, 1), (1.5, 0.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((3, 1), (1.5, 0.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((3, 2), (3, 1), "-|>", stroke: 0.8pt + rgb("#1a3a5c"))

    edge((1, 1), (1, 2), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4, 1), (4, 2), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4, 2), (4, 3), marks: ((inherit: "diamond", fill: rgb("#1a3a5c")), none), stroke: 0.8pt + rgb("#1a3a5c"))

    edge((2, 3), (2, 2), marks: ((inherit: "diamond", fill: white), none), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((2, 3), (3, 2), marks: ((inherit: "diamond", fill: white), none), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((3, 1), (2, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"))

    edge((0, 1), (1, 1), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (0, 2), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((0, 2), (0, 3), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((2, 1), (2, 2), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((2, 1), (3, 2), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (2, 1), stroke: 0.8pt + rgb("#1a3a5c"))
    edge((1, 1), (4, 1), stroke: 0.8pt + rgb("#1a3a5c"))

    edge((1, 0), (1, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((1, 0), (4, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((2, 0), (2, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((2, 0), (2, 3), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((3, 0), (2, 1), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((3, 0), (3, -0.75), "-|>", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((4, 0), (4, 2), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((4, 0), (4, -0.75), "-|>", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")

    edge((1, 1), (1.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((2, 1), (2.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4, 1), (4.5, 1.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4, 2), (4.5, 2.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4, 0), (4.5, 0.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((4.5, 0.5), (4, -0.75), "->", stroke: 0.8pt + rgb("#1a3a5c"), dash: "dashed")
    edge((0, 2), (0.5, 2.5), "->", stroke: 0.8pt + rgb("#1a3a5c"))
    edge((0, 3), (0.5, 2.5), "-|>", stroke: 0.8pt + rgb("#1a3a5c"))

    edge((0, 0), (2.2, 4.1), "->", stroke: 0.9pt + rgb("#c0392b"), dash: "dotted")
    edge((1, 0), (2.2, 4.1), "->", stroke: 0.9pt + rgb("#c0392b"), dash: "dotted")
    edge((2, 0), (2.2, 4.1), "->", stroke: 0.9pt + rgb("#c0392b"), dash: "dotted")
    edge((3, 0), (2.2, 4.1), "->", stroke: 0.9pt + rgb("#c0392b"), dash: "dotted")
    edge((4, 0), (2.2, 4.1), "->", stroke: 0.9pt + rgb("#c0392b"), dash: "dotted")
  }
)

#figure(
  align(center, scale(65%, reflow: true, updated-diagram())),
  caption: [Updated SmartFM class model as implemented. Black solid/dashed edges reproduce Assignment 2 exactly; red dotted edges show the one addition, the `DataStore` repository consulted by all four controllers.],
) <fig:uml-updated>

== Changes and Non-Changes at the Class Level

#figure(
  table(
    columns: (2.2fr, 1.1fr, 4.5fr),
    align: (left + top, center + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Class / Group], th[Status], th[Justification],

    [`Person`, `Customer`, `StaffMember`, `Driver`, `Branch`, `Vehicle`, `ServiceOffering`, `PricingTariff`, `Order`, `Consignment`, `Shipment`, `Invoice`, `Payment`, `Receipt`],
    [Unchanged],
    [All fourteen entity classes carried over with the exact attributes, responsibilities, and collaborators from their Assignment 2 CRC cards. No attribute was added, removed, or retyped beyond assigning concrete Java types (e.g. `LocalDate`, `double`) to fields that Assignment 2 deliberately left abstract.],

    [`OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState` and concrete subclasses],
    [Unchanged],
    [Implemented exactly as the Gang-of-Four State pattern described in Assignment 2 Section 5.2.3. Every transition listed in the Assignment 2 lifecycle table (Section 5.2.3, "State Pattern Support for Lifecycle Integrity") is enforced by a concrete subclass; illegal transitions throw `InvalidDataException` from the shared base class, matching Assignment 2 Section 1.3.2.],

    [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`],
    [Unchanged responsibilities, extended interfaces],
    [Each controller keeps its Assignment 2 responsibilities and Facade role. Each was additionally made to implement a small Observer listener interface (`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener`) so that the "publish/subscribe" relationships that Assignment 2 described narratively could be expressed as real Java interfaces rather than informal callbacks.],

    [`IPaymentGateway`, `IPaymentStrategy`, `IPricingStrategy`, `ITelemetrySource`],
    [Unchanged contracts, new concrete adapters],
    [The four interfaces are implemented exactly as specified. We added concrete classes behind them (`SimulatedGatewayAdapter`, `CashPaymentStrategy`, `GatewayPaymentStrategy`, `ManualTelemetrySource`) because Assignment 2 deliberately stopped at the interface level. As required by the Assignment 3 brief, the gateway adapter simulates verification rather than contacting a real bank.],

    [`SystemConfiguration`],
    [Unchanged role, concrete singleton mechanics added],
    [Assignment 2 Section 5.1.2 described this as a "Singleton-style controlled configuration instance" without specifying the mechanism. We implemented it as a package-private constructor plus a static `bootstrap()`/`getInstance()` pair, which is the standard idiom for a controlled single instance in Java.],

    [`Report`],
    [*Deferred, not implemented*],
    [Assignment 3 explicitly allows implementing a subset of the system provided at least four business areas are fully functional. `Report` supports branch managers (Assignment 1 Task 12) but has no dependency relationship *into* the four implemented areas, so deferring it does not break the dependency chain Order right arrow Shipment right arrow Invoice right arrow Payment. It remains fully specified in Assignment 2 and is not removed from the design, only left unimplemented in this iteration.],

    [`DataStore` (`smartfm.infrastructure`)],
    [*New*],
    [Assignment 2 Assumption A1 explicitly deferred the data access layer as "outside the scope of this high-level design". Implementation forced a decision: we chose file-based persistence (explicitly permitted by the Assignment 3 brief as a simplification in place of a database) using Java's built-in object serialization, so every domain class already implementing `Serializable` could be persisted with no additional mapping code.],

    [UI classes (`smartfm.ui`, `smartfm.ui.gui`)],
    [*New*],
    [Assignment 2 Section 3.2 explicitly excluded UI/boundary classes from the high-level design ("we left out UI and boundary classes because user interfaces change frequently"). Assignment 3 requires a working user interface, so this layer is new by design, not a correction of Assignment 2. Two presentation implementations are provided over the unchanged controller layer: a textual (CLI) interface and a graphical (Swing) interface, satisfying the brief's "graphical or textual" requirement with both options.],
  ),
  caption: [Class-Level Changes and Non-Changes Relative to Assignment 2],
) <tbl-class-changes>

== Changes to Responsibilities and Collaborators

Two responsibility-level adjustments were necessary once real code had to compile and run:

*1. Explicit collaborator: every controller now collaborates with `DataStore`.* Assignment 2's CRC cards listed collaborators only among domain and controller classes, consistent with deferring persistence. Once objects had to survive between runs, each controller's constructor was given a `DataStore` reference. This is additive, not a contradiction: Assignment 2 Assumption A1 already anticipated "a data access layer... outside the scope of this high-level design", and `DataStore` is precisely that layer made concrete.

*2. `DispatchManager.onOrderApproved` is an intentional no-op.* Assignment 2 Section 6.2 (bootstrap Step 6) states that `DispatchManager` "registers itself as an observer of `OrderProcessor` before any Order can be approved", implying it reacts automatically. In practice, choosing *which* vehicle and driver to assign an order to is a decision a dispatcher makes deliberately (Assignment 1 Task 5, "the dispatcher selects one of the suitable vehicles suggested by the system"), not something that can be inferred purely from the order-approved event with no further input. We implemented `onOrderApproved` as a registered-but-inert listener and added an explicit `assignShipment(orderId, vehicleId, driverId)` operation that a dispatcher invokes through the UI. The Observer registration itself is unchanged from Assignment 2; only the automatic *reaction* was narrowed to reflect a genuine human-in-the-loop decision that the original design under-specified.

No other CRC card responsibility was added, removed, or reassigned to a different class.

== Changes to Dynamic Aspects (Bootstrap and Scenarios)

*Bootstrap.* The nine-step bootstrap sequence from Assignment 2 Section 6.2 ("Bootstrap Sequence" table) was implemented exactly as specified, with one refinement: Steps 2 to 4 (branches, fleet, personnel, catalogue) only run the first time the application starts (i.e. when `DataStore` loads an empty snapshot from disk). On every subsequent run, that master/reference data is loaded from the persisted file instead of being recreated, while Steps 5 to 8 (constructing the four controllers and wiring their Observer registrations) still run on every startup, since controller objects themselves are not persisted. This is a necessary consequence of introducing persistence and does not change the *order* of dependency-safe construction that Assignment 2 specified; it only makes bootstrap idempotent across multiple runs of the same program, which Assignment 2 (a single conceptual startup) did not need to consider.

*Scenario 1 (Order Placement and Approval).* Implemented exactly as walked through in Assignment 2 Section 7.2 ("Scenario 1: Order Placement and Approval"), including the boundary-case validation in Step 2 and the dual Observer notification in Step 8.

*Scenario 2 (Vehicle and Driver Dispatch).* Implemented with the one clarification above: Step 3 ("select and bind resources") is now an explicit dispatcher action (`assignShipment`) rather than an automatic reaction to the order-approved event, for the human-in-the-loop reason given above.

*Scenario 3 (Real-Time Shipment Tracking).* Implemented with a `ManualTelemetrySource` adapter standing in for physical GPS hardware, exactly matching the Adapter pattern role Assignment 2 assigned to telemetry (Section 5.3.2): a human operator types the current location into the console, and the adapter presents it to `ShipmentTracker` through the same `ITelemetrySource` contract a real GPS feed would use. Invalid transitions (e.g. attempting delivery before pickup) are rejected by the `ShipmentState` hierarchy exactly as specified.

*Scenario 4 (Payment Verification and Receipt Issuance).* Implemented exactly as specified, including the boundary case that rejects a payment exceeding the outstanding balance (Assignment 2 Section 1.3.2) and the strict ordering guaranteed by the Factory Method and State patterns: a `Receipt` is only ever created after a `Payment` reaches the Settled state.

= Part II: Discussion of the Assignment 2 Design Quality

== Good Aspects

The CRC-card, Responsibility-Driven Design approach paid off directly during implementation. Because every class already had a bounded, single-sentence-per-line list of responsibilities and collaborators, translating a CRC card into a Java class was close to mechanical: fields for "knows" responsibilities, methods for "does" responsibilities, constructor parameters for "N/A"-free collaborator lists. The State pattern hierarchies (`OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState`) were the single most valuable design decision to carry into code: because Assignment 2 had already enumerated every legal transition in its "State Pattern Support for Lifecycle Integrity" table (Section 5.2.3), writing the corresponding `approve()`/`pickUp()`/`transit()`/`deliver()` methods and their illegal-transition exceptions required no new design work, only transcription. The Observer wiring in the bootstrap sequence (Assignment 2 Section 6.2) was similarly precise enough that we could implement it as literal Java interfaces (`OrderApprovedListener`, etc.) registered in exactly the order Assignment 2's bootstrap table specified, and the resulting code produces the same "Observer notification" behaviour the design predicted (see the transcripts in Part VI).

== Aspects Missing from the Original Design

Three things Assignment 2 explicitly and deliberately left out turned out to require real design decisions, not just typing, once implementation started:

*User interface flow.* Assignment 2 (Section 3.3) excluded UI classes on the grounds that "user interfaces change frequently and should not be mixed with stable business logic" - a defensible decision for a class diagram, but it left zero guidance on how a raw string typed by a user becomes a validated `Consignment`, in what order fields should be requested, or how a user backs out of a multi-step form. We had to design this from scratch (Part V, Part VI) using the general validation rules from Assignment 2 Section 1.3.2 as a starting point, but the *sequencing* of prompts, the cancel-at-any-step mechanism, and the retry-on-invalid-input loop are all new design work with no counterpart in Assignment 2.

*Persistence mechanics.* Assumption A1 stated data would live in "a single, shared relational database... outside the scope of this high-level design". This is a reasonable simplification for an object design document, but it meant Assignment 2 gave us no guidance at all on serialization format, transaction boundaries, or what happens if the process is killed mid-write. We had to design the `DataStore` class, its atomic-write-via-temp-file strategy, and its load-on-startup behaviour entirely during implementation.

*Concrete adapter behaviour.* `IPaymentGateway` and `ITelemetrySource` were specified only as interfaces. Assignment 2 never had to decide what a "simulated" gateway response looks like, or how a manually-typed location string should be validated before being accepted as telemetry. These are small decisions, but they did not exist in the Assignment 2 document.

== Flawed Aspects of the Original Design

We identify one genuine ambiguity that we would call a flaw rather than a simplification. Assignment 2 Section 6.2 (Step 6) states that `DispatchManager` reacts to the order-approved event, phrased in a way that could be read as *automatic* dispatch. Assignment 1's Task 5 ("Assign Vehicle and Driver to an Order") makes clear that vehicle/driver selection is a deliberate dispatcher decision with an explicit "select vehicle" step and a documented override-with-reason variant, which is incompatible with a fully automatic reaction. Assignment 2 did not surface or resolve this tension between the task-level detail it carried over from Assignment 1 and its own Section 6 (bootstrap narrative). We resolved it during implementation by keeping the Observer *registration* automatic but making the *dispatch decision* an explicit operation, as documented in Part I.C above. No other flaw of this kind (an internal contradiction within Assignment 2 itself) was found; the remaining gaps in the previous subsection are omissions rather than errors.

== Level of Interpretation Required

Overall, Assignment 2 required a low to moderate amount of interpretation to implement. The twenty core classes, their CRC-card responsibilities, and the four verification scenarios were specific enough to implement with almost no guesswork: field types, exception types, and method names were the only decisions left to the implementer, and Assignment 2's own naming convention section (Section 1.3, "Documentation and Guidelines for Interface") constrained even those. The moderate interpretation came from exactly the three "missing aspects" above: UI flow, persistence mechanics, and concrete adapter behaviour were areas where Assignment 2 correctly identified *that* something was needed (an access channel, a data access layer, an external gateway) without specifying *how* it should behave, which is consistent with a high-level design document but still required us to make and justify new decisions rather than merely transcribe existing ones.

= Part III: Lessons Learnt

*Write the state machine before the class list.* The single biggest reason the State-pattern classes ported into code almost unchanged is that Assignment 2 had already tabulated every legal transition (Section 5.2.3, "State Pattern Support for Lifecycle Integrity") before any Java was written. Next time, we would apply the same discipline earlier and more broadly: for any class whose behaviour depends on a lifecycle (not just `Order`, `Shipment`, `Invoice`, `Payment`, but also, in hindsight, `Driver`'s duty states and `Vehicle`'s utilisation states), we would draft the full transition table during the initial design stage rather than leaving some of it as a simple enum with no enforced transition rules, as we did for `DutyState` and `VehicleStatus` in this implementation.

*Decide the persistence strategy during high-level design, even if only as a placeholder.* Deferring "how data is stored" to "outside the scope" is reasonable for scoping a design document, but it left us needing a design decision (file-based vs. relational, transaction semantics, serialization format) at the start of implementation rather than during design, when we had more time to weigh trade-offs deliberately. Next time we would include at least a one-paragraph placeholder decision (e.g. "assume an in-memory repository interface with a single `save()`/`load()` contract") in the high-level design, even without committing to a concrete database, so implementation starts from an agreed contract rather than an open question.

*Distinguish "automatic reaction" from "human decision" explicitly in Observer-pattern descriptions.* The dispatch ambiguity in Part II.C arose because natural-language descriptions of Observer relationships ("registers as an observer... reacts to...") do not distinguish between a listener that fully automates a response and a listener that merely becomes *aware* of an event so a human can act on it deliberately. Next time we would annotate every Observer relationship in the design document with one of these two categories explicitly, rather than leaving it implicit in prose.

*Prototype the UI flow alongside the class diagram, not after it.* Even a rough textual sketch of "what does the customer type, in what order, and what happens if they make a mistake" during Assignment 2 would have surfaced the retry-and-cancel requirements before implementation, rather than during it. This would have let us validate that the domain classes' constructors and validation methods (which enforce Assignment 2 Section 1.3.2's boundary rules) actually compose cleanly into a usable multi-step form, instead of discovering the composition question for the first time while writing `SmartFmConsoleApp`.

= Part IV: Architecture Style(s)

== Identified Style: Layered Architecture with an Event-Driven (Observer/Publish-Subscribe) Control Layer

SmartFM's architecture, both as designed in Assignment 2 and as implemented in Assignment 3, is a *layered architecture* in which the control layer additionally uses *event-driven (publish-subscribe)* interaction. This is consistent with, and now concretely realises, the "modular, event-driven structure" that Assignment 1's problem-domain analysis anticipated for shipment-status and payment notifications.

#let arch-node(pos, name, w: 3.6cm, h: 1.0cm, fill: rgb("#f0f4f8")) = node(
  pos,
  rect(width: w, height: h, radius: 4pt, fill: fill, stroke: 1.1pt + rgb("#1a3a5c"), inset: 4pt,
    align(center + horizon, text(size: 8pt, weight: "bold", fill: rgb("#1a3a5c"), name))
  ),
  stroke: none, fill: none
)

#let architecture-diagram() = diagram(
  spacing: (2.2cm, 1.6cm),
  {
    arch-node((0, 0), "Presentation Layer\n(smartfm.ui)", w: 5.2cm)
    arch-node((0, 1), "Application / Control Layer\n(smartfm.application)\n4 controllers + Observer bus", w: 5.2cm, h: 1.3cm)
    arch-node((0, 2), "Domain Layer\n(smartfm.domain)\n20 entities + State/Strategy", w: 5.2cm)
    arch-node((0, 3), "Infrastructure Layer\n(smartfm.infrastructure, common)\nDataStore, Validators", w: 5.2cm)

    edge((0, 0), (0, 1), "<->", stroke: 1pt + rgb("#1a3a5c"))
    edge((0, 1), (0, 2), "<->", stroke: 1pt + rgb("#1a3a5c"))
    edge((0, 2), (0, 3), "<->", stroke: 1pt + rgb("#1a3a5c"))
  }
)

#figure(
  align(center, architecture-diagram()),
  caption: [SmartFM layered architecture. Each layer depends only downward; the Application layer additionally coordinates via an internal publish-subscribe event bus (@fig-event-bus).],
) <fig-layers>

== Components, Connectors, and Constraints

At a level of abstraction above individual classes, we identify four architectural components, each larger than a single class:

#figure(
  table(
    columns: (1.8fr, 3.4fr, 3.8fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Component], th[Constituent Classes], th[Responsibility],

    [Presentation Component],
    [`SmartFmConsoleApp`, `ConsoleIO` (textual); `SmartFmMainFrame` and five panels, `GuiContext`, `ValidatedField`, `ResultBanner` (graphical)],
    [Owns all user interaction: menu navigation or tab/panel navigation, field-by-field prompting or form validation, retry-on-invalid-input handling, and cancel handling. Contains no business rules of its own. Two interchangeable implementations exist over the same controller API, demonstrating that the Presentation component is a genuine, replaceable boundary layer rather than logic entangled with the UI toolkit.],

    [Order and Billing Component],
    [`OrderProcessor`, `PaymentProcessor` and the domain classes they coordinate (`Order`, `Consignment`, `Invoice`, `Payment`, `Receipt`)],
    [Owns the commercial lifecycle: order intake, approval, invoicing, payment settlement, and receipt issuance.],

    [Fleet and Dispatch Component],
    [`DispatchManager`, `ShipmentTracker` and the domain classes they coordinate (`Vehicle`, `Driver`, `Branch`, `Shipment`)],
    [Owns physical resource allocation and real-time transit tracking, decoupled from commercial/billing concerns.],

    [Persistence Component],
    [`DataStore`],
    [Owns the durable state of every aggregate. The only component any other component is permitted to depend on for storage.],
  ),
  caption: [Architectural Components (each larger than a single class)],
) <tbl-components>

*Connectors.* Two distinct connector types are used, matching the two interaction styles visible in @fig-layers:

- *Direct method-call connectors* run strictly downward: Presentation calls into the Order/Billing and Fleet/Dispatch components' public controller methods (e.g. `submitOrder`, `assignShipment`), and both of those call into the Persistence component through `DataStore`'s map-based accessors. No component calls back up a layer.
- *Event connectors (publish-subscribe)* run across the Order/Billing and Fleet/Dispatch components at the same layer: `OrderProcessor` publishes order-approved and invoice-created events; `DispatchManager` and `PaymentProcessor` subscribe to the former, `PaymentProcessor` to the latter; `DispatchManager` publishes a shipment-assigned event that `ShipmentTracker` subscribes to. This lets the two components coordinate without either holding a direct, hardcoded reference to the concrete class of the other, only to the narrow listener interface.

#let event-diagram() = diagram(
  spacing: (2.4cm, 1.3cm),
  {
    arch-node((0, 0), "OrderProcessor", w: 3.0cm)
    arch-node((1, 1), "DispatchManager", w: 3.0cm)
    arch-node((2, 0), "PaymentProcessor", w: 3.0cm)
    arch-node((1, 2), "ShipmentTracker", w: 3.0cm)

    edge((0, 0), (1, 1), "->", stroke: 0.9pt + rgb("#1a3a5c"), dash: "dashed", label: "order-approved", label-pos: 0.5)
    edge((0, 0), (2, 0), "->", stroke: 0.9pt + rgb("#1a3a5c"), dash: "dashed", label: "invoice-created", label-pos: 0.5)
    edge((1, 1), (1, 2), "->", stroke: 0.9pt + rgb("#1a3a5c"), dash: "dashed", label: "shipment-assigned", label-pos: 0.5)
  }
)

#figure(
  align(center, event-diagram()),
  caption: [Publish-subscribe event connectors between the four controllers, wired during bootstrap.],
) <fig-event-bus>

*Constraints.* Three architectural constraints are enforced (by convention and code review, since Java does not enforce module boundaries without an explicit module system):

1. *Downward-only method calls.* `smartfm.domain` classes never import from `smartfm.application`, `smartfm.ui`, or `smartfm.infrastructure`. This preserves the low-coupling property Assignment 2 Section 4.1.3 identified as a design goal: domain classes remain ignorant of how they are displayed, coordinated, or stored.
2. *Single persistence gateway.* Only `smartfm.application` classes hold a `DataStore` reference; `smartfm.domain` classes are never given one. This keeps persistence a controller-layer concern, matching Assignment 2 Assumption A2 ("classes validate their own internal data" but do not manage their own storage).
3. *Listener interfaces, not concrete references, for cross-controller notification.* `OrderProcessor` holds `List<OrderApprovedListener>`, never `List<DispatchManager>`. This is the architectural expression of the Observer pattern discussed at the class level in Assignment 2 Section 5.2.2, promoted here to a component-level constraint that keeps the Order/Billing and Fleet/Dispatch components independently replaceable.

= Part V: Implementation

== Language, Platform, and Coding Standard

The implementation is written in *Java 17* (OpenJDK, Microsoft build 17.0.19) and packaged as a standard *Maven* project (`pom.xml`, `src/main/java` layout per @tbl-project-layout), so it can be built with `mvn package` and opened directly in any Maven-aware IDE; it also compiles with plain `javac` when Maven is unavailable, since the application itself has zero runtime dependencies beyond the JDK standard library. Development and testing were carried out on *Windows* using PowerShell as the command shell.

No particular coding standard was mandated by the assignment, so the implementation follows the *Google Java Style Guide* @google2023javastyle for formatting, naming, and file organisation (two-space indentation, `UpperCamelCase` classes, `lowerCamelCase` methods and fields, one public top-level class per file), and *Javadoc* conventions @oracle2023javadoc for documentation comments: every class carries a class-level Javadoc comment cross-referencing the specific Assignment 2 CRC card or design pattern section it implements, and every non-trivial public method is documented with its business rule or scenario step. This dual citation lets a marker trace any class directly back to its Assignment 2 justification.

#figure(
  console(raw(read("implementation/transcripts/00_compilation_evidence.txt"), lang: "text")),
  caption: [Explicit compilation evidence: a clean rebuild of all 74 source files (`javac -Xlint:all`) under the Maven-standard `src/main/java` layout, producing zero warnings and zero errors, exit code 0.],
) <fig-compile-evidence>

== Two Presentation Layers Over One Unchanged Controller Layer

The Assignment 3 brief requires "a simple user interface (graphical or textual)". Rather than choosing one, the implementation provides both, to demonstrate concretely that the controller/domain layers are genuinely independent of any specific presentation technology (Assignment 2 Section 4.1.3, low coupling):

- *Textual (CLI):* `smartfm.ui.SmartFmConsoleApp`, unchanged from the description in Part I-III of this document. Launched with `java -jar target/smartfm.jar --cli` (or `java -cp target/classes smartfm.ui.Launcher --cli`).
- *Graphical (Swing):* `smartfm.ui.gui.SmartFmMainFrame`, the default when no argument is passed. A `JTabbedPane` presents one tab per business area plus a customer-registration tab, mirroring the CLI's menu structure one-to-one (@tbl-gui-cli-mapping).

Both entry points are reached through a single `smartfm.ui.Launcher` main class, and both construct exactly one `Bootstrap` over exactly one `DataStore`, so a user could, in principle, start the system with the CLI, exit, and resume the same data in the GUI (or vice versa) without any data conversion step.

#figure(
  table(
    columns: (2.6fr, 3.7fr, 3.7fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Business Area], th[CLI (`SmartFmConsoleApp`)], th[GUI (`smartfm.ui.gui`)],

    [Customer Registration],
    [Main menu option [5], six sequential prompts with retry-on-error],
    [`CustomerRegistrationPanel`: one form, all fields visible at once, inline red highlight and message per invalid field on submit],

    [1. Order Management],
    [Sub-menu [1]-[5]: place, view pending, approve, reject, cancel],
    [`OrderManagementPanel`: order form with a live consignment table, and a pending-orders table with Approve/Reject/Cancel buttons],

    [2. Fleet Dispatch],
    [Single flow: list approved orders, list vehicles, list drivers, assign],
    [`FleetDispatchPanel`: approved-orders table (selection auto-populates available vehicle/driver combo boxes) plus a "Create Shipment" button],

    [3. Shipment Tracking],
    [Sub-menu [1]-[4]: pickup, in transit, delivery, view status],
    [`ShipmentTrackingPanel`: shipments table plus Confirm Pickup / In Transit / Delivery buttons acting on the selected row],

    [4. Billing and Payment],
    [Single flow: list outstanding invoices, then amount and method prompts],
    [`BillingPaymentPanel`: invoices table plus an amount field, a payment-method drop-down, and a "Submit Payment" button],
  ),
  caption: [One-to-one mapping between CLI menu options and GUI panels; both call the identical controller methods.],
) <tbl-gui-cli-mapping>

Every GUI panel is a thin Swing view over the same four controllers used by the CLI: for example, `OrderManagementPanel`'s "Submit Order" button calls `context.getOrderProcessor().submitOrder(...)`, the exact same method `SmartFmConsoleApp.placeOrder()` calls. Input validation reuses the identical `smartfm.common.Validators` methods; a shared `ValidatedField` widget calls the same validator, catches the same `InvalidDataException`, and displays its message inline next to the offending field instead of re-prompting on the console. This is the GUI equivalent of the CLI's "retry until valid" loop: the user corrects the highlighted field in place and presses the button again.

== The Four Implemented Business Areas

As permitted by the Assignment 3 brief, we implemented a coherent subset of SmartFM covering four full business areas from the Assignment 1 case study, rather than the whole system:

+ *Order Management* -- customer registration, order submission with consignment capture, dispatcher approval/rejection, and customer-initiated cancellation (Assignment 1 Tasks 1 and 3; Assignment 2 `OrderProcessor`).
+ *Fleet Dispatch* -- matching an approved order to an available vehicle and driver at the correct branch (Assignment 1 Task 5; Assignment 2 `DispatchManager`).
+ *Shipment Tracking* -- recording pickup, in-transit, and delivery milestones with location updates (Assignment 1 Tasks 6 and 7; Assignment 2 `ShipmentTracker`).
+ *Billing and Payment* -- invoice generation on approval, payment submission with balance validation, and receipt issuance (Assignment 1 Tasks 4 and 8; Assignment 2 `PaymentProcessor`).

== Dependency Handling Between Business Areas

The Assignment 3 brief specifically requires that the dependency between implemented areas be considered so that the chosen areas remain fully functional despite depending on each other. The four areas above form a strict linear dependency chain that mirrors Assignment 1's own task ordering and Assignment 2's Assumption A6/A7:

#figure(
  table(
    columns: (2.2fr, 2.6fr, 4.2fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Business Area], th[Depends On], th[How Full Functionality Is Preserved],

    [1. Order Management],
    [(none)],
    [Fully self-contained: a customer can register, submit, and manage an order using only seeded reference data (branches, service offerings, tariffs) created during bootstrap. No other business area needs to exist first.],

    [2. Fleet Dispatch],
    [Area 1 (an order must reach the Approved state)],
    [Enforced in code, not just by convention: `DispatchManager.assignShipment` explicitly checks `order.isApproved()` and throws `InvalidDataException` otherwise (Assumption A6). Because Area 1 is fully implemented, this dependency is always satisfiable; dispatch is never blocked by a missing capability.],

    [3. Shipment Tracking],
    [Area 2 (a `Shipment` must exist with an assigned vehicle and driver)],
    [`ShipmentTracker` only becomes aware of a shipment through the shipment-assigned Observer event published by `DispatchManager`; there is no path to create a trackable shipment except through a completed Area 2 dispatch, which is always available.],

    [4. Billing and Payment],
    [Area 1 (an `Invoice` is only known to `PaymentProcessor` once `OrderProcessor` publishes the invoice-created event)],
    [Deliberately independent of Areas 2 and 3: a customer can pay an invoice whether or not the corresponding shipment has been dispatched or delivered yet, matching real-world logistics practice where invoicing follows order approval, not delivery.],
  ),
  caption: [Dependency Chain Across the Four Implemented Business Areas],
) <tbl-dependency-chain>

Because Area 1 is fully implemented and has no dependency of its own, and each subsequent area depends only on areas that are themselves fully implemented, the chain has no missing link: a marker can exercise all four areas start to finish using only the classes present in this submission, with no simulated or stubbed-out upstream dependency.

== Design Patterns Realised in Code

All patterns identified in Assignment 2 Section 5 are present in the implementation, unchanged in role:

#figure(
  table(
    columns: (1.8fr, 3.4fr, 3.6fr),
    align: (left + top, left + top, left + top),
    inset: (x: 9pt, y: 7pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill }
                    else if calc.odd(y) { white }
                    else { alt-row-fill },

    th[Pattern], th[Assignment 2 Reference], th[Implementing Classes],

    [Factory Method], [Section 5.1.1], [`OrderProcessor.submitOrder/approveOrder`, `DispatchManager.assignShipment`, `PaymentProcessor.submitPayment`],
    [Singleton-style Configuration], [Section 5.1.2], [`SystemConfiguration`],
    [Strategy], [Section 5.2.1], [`IPaymentStrategy` (`CashPaymentStrategy`, `GatewayPaymentStrategy`), `IPricingStrategy` (`PricingTariff`)],
    [Observer], [Section 5.2.2], [`OrderApprovedListener`, `InvoiceCreatedListener`, `ShipmentAssignedListener` and their implementations],
    [State], [Section 5.2.3], [`OrderState`, `ShipmentState`, `InvoiceState`, `PaymentState` hierarchies],
    [Facade], [Section 5.3.1], [`OrderProcessor`, `DispatchManager`, `ShipmentTracker`, `PaymentProcessor`],
    [Adapter], [Section 5.3.2], [`SimulatedGatewayAdapter` implementing `IPaymentGateway`; `ManualTelemetrySource` implementing `ITelemetrySource`],
  ),
  caption: [Design Patterns From Assignment 2, Realised in the Implementation],
) <tbl-patterns-realised>

= Part VI: Execution and Operation

== Platform and Deployment

The system was developed and tested on *Windows* with *OpenJDK 17.0.19* (Microsoft build). To deploy and run the system:

*With Maven (recommended, standard for a Java project of this shape):*
+ Ensure a Java 17 (or later) JDK and Maven are installed.
+ From the `implementation` directory, run `mvn package`. This compiles `src/main/java`, runs any tests under `src/test/java`, and produces `target/smartfm.jar`.
+ Run the graphical interface (default) with `java -jar target/smartfm.jar`, or the textual interface with `java -jar target/smartfm.jar --cli`.

*Without Maven (fallback, since Maven is not required to be installed on the marker's machine):*
+ List every file under `src/main/java` and pass them to `javac -d target/classes -encoding UTF-8`.
+ Run the graphical interface with `java -cp target/classes smartfm.ui.Launcher`, or the textual interface with `java -cp target/classes smartfm.ui.Launcher --cli`.

In both cases, data persists automatically to `data/smartfm-store.dat` between runs; deleting this file resets the system to its freshly-seeded state (2 branches, 3 vehicles, 3 drivers, 3 service offerings, as created by `Bootstrap`). No installation step, external database, or network service is required, satisfying the Assignment 3 simplification that allows file-based persistence in place of a database.

== Scenario 1: Customer Registration (Business Area 1, prerequisite step)

An empty prompt-driven registration form is presented first; an invalid phone number and an invalid email address are each rejected and re-prompted in place before a valid customer record is created.

#figure(
  console(raw(read("implementation/transcripts/01_register_customers.txt"), lang: "text")),
  caption: [Registering two customers. Note the in-place validation retry for an invalid phone number ('abc') and an invalid email address ('not-an-email') before the account is successfully created.],
) <fig-scenario-1>

== Scenario 2: Order Placement, Change of Mind, Rejection, and Approval (Business Area 1)

Three orders are placed (one after a validation retry on a negative weight), the pending queue is inspected, one order is withdrawn by the customer, one is rejected by a dispatcher with a reason, and the remaining order is approved, automatically generating an invoice and notifying the other two controllers. This scenario is one single continuous run, split into four transcripts below purely for page layout.

#figure(
  console(raw(read("implementation/transcripts/02a_place_orders.txt"), lang: "text")),
  caption: [Business Area 1, part 1 of 4: placing the first order, including an in-place retry after an invalid (negative) weight is entered for the first consignment.],
) <fig-scenario-2a>

#figure(
  console(raw(read("implementation/transcripts/02a2_place_orders.txt"), lang: "text")),
  caption: [Business Area 1, part 2 of 4 (continuation): placing a second and third order.],
) <fig-scenario-2a2>

#figure(
  console(raw(read("implementation/transcripts/02b_manage_orders.txt"), lang: "text")),
  caption: [Business Area 1, part 3 of 4 (continuation): viewing the pending-orders queue, then a customer cancelling an order (change of mind).],
) <fig-scenario-2b>

#figure(
  console(raw(read("implementation/transcripts/02c_manage_orders.txt"), lang: "text")),
  caption: [Business Area 1, part 4 of 4 (continuation): a dispatcher rejecting an order with a stated reason, and a dispatcher approving the remaining order, which generates Invoice INV-0001 and triggers the Observer notifications documented in Assignment 2 Section 6.],
) <fig-scenario-2c>

== Scenario 3: Fleet Dispatch (Business Area 2)

Dispatching the approved order first fails cleanly against a non-existent vehicle id, then succeeds against a valid vehicle and driver, creating a shipment and notifying `ShipmentTracker`.

#figure(
  console(raw(read("implementation/transcripts/03_dispatch.txt"), lang: "text")),
  caption: [Business Area 2: an invalid vehicle id ('VHC-9999') is rejected without side effects, then a valid vehicle and driver are assigned, creating Shipment SHP-0001 and demonstrating the shipment-assigned Observer notification to `ShipmentTracker`.],
) <fig-scenario-3>

== Scenario 4: Shipment Tracking (Business Area 3)

An out-of-order transition (attempting delivery while the shipment is still only Assigned) is rejected by the State pattern before any valid transition is attempted; the shipment then progresses correctly through Picked Up, In Transit, and Delivered, with status queries in between. As with Scenario 2, this is one continuous run split into two transcripts for page layout.

#figure(
  console(raw(read("implementation/transcripts/04a_pickup_transit.txt"), lang: "text")),
  caption: [Business Area 3, part 1: an invalid "Delivered" transition from the Assigned state is rejected by `ShipmentState` (State pattern), then the shipment correctly progresses through Picked Up and In Transit.],
) <fig-scenario-4a>

#figure(
  console(raw(read("implementation/transcripts/04b_delivery.txt"), lang: "text")),
  caption: [Business Area 3, part 2 (continuation of the same run): `View shipment status` confirms "In Transit", the shipment is then marked Delivered, and a final status check confirms "Delivered".],
) <fig-scenario-4b>

== Scenario 5: Billing and Payment (Business Area 4)

A payment attempt exceeding the invoice's outstanding balance is rejected before any state changes; a partial cash payment is then accepted, leaving the invoice Partially Paid; a final card payment settles the invoice and issues a receipt.

#figure(
  console(raw(read("implementation/transcripts/05_billing.txt"), lang: "text")),
  caption: [Business Area 4: a payment of 30,000,000 VND against a 22,290,000 VND balance is rejected (boundary case from Assignment 2 Section 1.3.2), then a 10,000,000 VND cash payment is accepted (Invoice becomes Partially Paid, Receipt RCT-0001 issued), and a final 12,290,000 VND card payment settles the invoice (Paid, Receipt RCT-0002 issued).],
) <fig-scenario-5>

== Evidence of Persistent Storage

Each scenario above was run as a separate process invocation of the CLI (`java -cp target/classes smartfm.ui.Launcher --cli`), with all data (customers, orders, shipments, invoices, payments, receipts) surviving between invocations by being written to and re-read from `data/smartfm-store.dat`. After the five scenarios above, this file was confirmed to exist on disk at 7,215 bytes, containing the complete serialized `DataStore` snapshot: 2 branches, 3 vehicles, 3 drivers, 2 customers, 3 orders (one Approved-and-dispatched, one Cancelled, one Rejected), 1 shipment (Delivered), 1 invoice (Paid), 2 payments (Settled), and 2 receipts. This is direct evidence that the file-based persistence layer required by Assignment 2 Assumption A1 (in the "files instead of a database" form permitted by the Assignment 3 brief) functions correctly across independent runs of the compiled program, not only within a single execution. Because the GUI shares the identical `DataStore`/`Bootstrap` startup path (@fig-compile-evidence, Part V.C), the same persistence behaviour applies to it without any additional code.

== Graphical Interface Verification Status

The Swing GUI (`smartfm.ui.gui`, @tbl-gui-cli-mapping) was built against, and compiles cleanly with, the same controller and domain classes exercised by the CLI transcripts above (@fig-compile-evidence covers all 74 source files, including the ten GUI classes). It was manually smoke-tested by launching `smartfm.ui.Launcher` and confirming the window opens, all five tabs render, and `java.awt.GraphicsEnvironment.isHeadless()` reports `false` on the development machine, i.e. the interface genuinely renders rather than merely compiling. A `ScreenshotDriver` development tool (`tools/java/smartfm/ui/gui/ScreenshotDriver.java`, not shipped as part of the application) was also written to drive the GUI through the same five scenarios as Part VI's CLI transcripts and capture a screenshot of the application window after each step.

We are not including the captured screenshots in this submission. During testing, the automated capture occasionally picked up other windows on the development machine instead of (or in addition to) the SmartFM window, because bringing a Swing frame to the foreground programmatically is not perfectly reliable across all window managers. Submitting a screenshot that might contain unrelated content from a development machine would be inappropriate, so rather than curate around that risk under time pressure, we have left GUI screenshot evidence out of this submission and rely on the CLI transcripts in Scenarios 1-5 above (which exercise the identical controller logic the GUI calls) as the primary execution evidence, together with the compilation evidence covering the GUI source files. The `ScreenshotDriver` tool remains in the submission so a marker who wishes to can run it locally, on their own machine, to generate genuine GUI screenshots on demand.

#colbreak()
#heading(level: 1, numbering: none)[Appendix \ Assignment 2: Object Design (Complete Submission)] <appendix-asm2>

The complete Assignment 2 Object Design submission is attached below at full scale, as required by the Assignment 3 submission guidelines so that this report is self-contained for the purposes of discussion and reflection in Parts I to IV above. Section and table references in this report (e.g. "Assignment 2 Section 5.2.3", "the Bootstrap Sequence table") refer to the corresponding content within this appendix.

#counter("appendix").update(1)
#colbreak()

#for page-num in range(1, 66) {
  place(top + left, dx: -50pt, dy: -55pt, image("asm2.pdf", page: page-num, width: 21.59cm, height: 27.94cm))
  colbreak()
}
