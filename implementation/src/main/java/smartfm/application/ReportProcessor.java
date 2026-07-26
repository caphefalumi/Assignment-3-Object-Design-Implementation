package smartfm.application;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import smartfm.common.Money;

import smartfm.domain.billing.Invoice;
import smartfm.domain.billing.Payment;
import smartfm.domain.customer.Customer;
import smartfm.domain.fleet.Branch;
import smartfm.domain.fleet.Driver;
import smartfm.domain.fleet.Vehicle;
import smartfm.domain.fleet.VehicleStatus;
import smartfm.domain.order.Order;
import smartfm.domain.report.Report;
import smartfm.domain.report.ReportCategory;
import smartfm.domain.shipment.Shipment;
import smartfm.infrastructure.DataStore;

/**
 * Coordinating controller managing the generation of system reports.
 * Corresponds to the {@code Report} CRC card in Assignment 2 Section 3
 * (System Control and Configuration Package) and implements task T12 ("Generate Reports").
 * Acts as an Information Expert across the domain aggregates held in {@link DataStore}.
 */
public class ReportProcessor {

  private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

  private final DataStore store;
  private final IdGenerator reportIds;

  public ReportProcessor(DataStore store) {
    this.store = store;
    this.reportIds = new IdGenerator("RPT", new LinkedHashMap<>());
  }

  /** Delegates report creation based on selected category and optional branch filtering. */
  public Report generateReport(
      ReportCategory category,
      String branchId,
      LocalDate startDate,
      LocalDate endDate) {
    if (category == null) {
      category = ReportCategory.FINANCIAL;
    }
    switch (category) {
      case FLEET:
        return generateFleetReport(startDate, endDate);
      case BRANCH:
        return generateBranchReport(branchId, startDate, endDate);
      case ORDER_SUMMARY:
        return generateOrderSummaryReport(startDate, endDate);
      case FINANCIAL:
      default:
        return generateFinancialReport(startDate, endDate);
    }
  }

  public Report generateFinancialReport(LocalDate startDate, LocalDate endDate) {
    String id = reportIds.next();
    Map<String, String> metrics = new LinkedHashMap<>();

    double totalQuotedRevenue = 0.0;
    for (Order order : store.orders().values()) {
      if (isWithinRange(order.getCreatedAt().toLocalDate(), startDate, endDate)) {
        if ("Approved".equals(order.getStateName())) {
          totalQuotedRevenue += order.getQuotedAmount();
        }
      }
    }

    double totalBilled = 0.0;
    double totalOutstanding = 0.0;
    int unpaidCount = 0;
    int partiallyPaidCount = 0;
    int paidCount = 0;
    int totalInvoicesInPeriod = 0;

    for (Invoice inv : store.invoices().values()) {
      if (isWithinRange(inv.getCreatedAt().toLocalDate(), startDate, endDate)) {
        totalInvoicesInPeriod++;
        totalBilled += inv.getTotalAmount();
        totalOutstanding += inv.getOutstandingBalance();
        if ("Unpaid".equals(inv.getStateName())) {
          unpaidCount++;
        } else if ("Partially Paid".equals(inv.getStateName())) {
          partiallyPaidCount++;
        } else if ("Paid".equals(inv.getStateName())) {
          paidCount++;
        }
      }
    }

    double totalCollected = 0.0;
    Map<String, Double> byMethod = new LinkedHashMap<>();
    int settledPayments = 0;

    for (Payment p : store.payments().values()) {
      if (isWithinRange(p.getTimestamp().toLocalDate(), startDate, endDate)) {
        if (p.isSettled()) {
          totalCollected += p.getAmount();
          settledPayments++;
          String method = p.getMethod() != null ? p.getMethod().name() : "UNKNOWN";
          byMethod.put(method, byMethod.getOrDefault(method, 0.0) + p.getAmount());
        }
      }
    }

    metrics.put("Total Quoted Revenue", Money.format(totalQuotedRevenue) + " VND");
    metrics.put("Total Invoiced Amount", Money.format(totalBilled) + " VND");
    metrics.put("Total Revenue Collected", Money.format(totalCollected) + " VND");
    metrics.put("Outstanding Receivables", Money.format(totalOutstanding) + " VND");
    metrics.put("Total Invoices", String.valueOf(totalInvoicesInPeriod));
    metrics.put("Paid Invoices", String.valueOf(paidCount));
    metrics.put("Partially Paid Invoices", String.valueOf(partiallyPaidCount));
    metrics.put("Unpaid Invoices", String.valueOf(unpaidCount));
    metrics.put("Settled Payments Count", String.valueOf(settledPayments));

    StringBuilder sb = new StringBuilder();
    sb.append("=================================================================\n");
    sb.append("                 SMARTFM FINANCIAL & REVENUE REPORT              \n");
    sb.append("=================================================================\n");
    sb.append("Report ID   : ").append(id).append("\n");
    sb.append("Date Range  : ").append(formatRange(startDate, endDate)).append("\n");
    sb.append("Generated At: ").append(LocalDate.now().format(DATE_FMT)).append("\n\n");

    sb.append("1. REVENUE SUMMARY\n");
    sb.append("   - Total Approved Quoted Revenue: ").append(Money.format(totalQuotedRevenue)).append(" VND\n");
    sb.append("   - Total Billed (Invoiced) Amount: ").append(Money.format(totalBilled)).append(" VND\n");
    sb.append("   - Total Revenue Collected       : ").append(Money.format(totalCollected)).append(" VND\n");
    sb.append("   - Outstanding Balance Due       : ").append(Money.format(totalOutstanding)).append(" VND\n\n");

    sb.append("2. INVOICE STATUS BREAKDOWN\n");
    sb.append("   - Paid Invoices                 : ").append(paidCount).append("\n");
    sb.append("   - Partially Paid Invoices       : ").append(partiallyPaidCount).append("\n");
    sb.append("   - Unpaid Invoices               : ").append(unpaidCount).append("\n");
    sb.append("   - Total Invoices Issued         : ").append(totalInvoicesInPeriod).append("\n\n");

    sb.append("3. PAYMENT METHOD BREAKDOWN\n");
    if (byMethod.isEmpty()) {
      sb.append("   (No settled payments recorded in this date range)\n");
    } else {
      for (Map.Entry<String, Double> entry : byMethod.entrySet()) {
        sb.append("   - ").append(entry.getKey()).append(": ")
            .append(Money.format(entry.getValue())).append(" VND\n");
      }
    }
    sb.append("=================================================================\n");

    return new Report(
        id, "Financial & Revenue Summary Report", ReportCategory.FINANCIAL,
        startDate, endDate, metrics, sb.toString());
  }

  public Report generateFleetReport(LocalDate startDate, LocalDate endDate) {
    String id = reportIds.next();
    Map<String, String> metrics = new LinkedHashMap<>();

    int totalVehicles = store.vehicles().size();
    int availableVehicles = 0;
    int dispatchedVehicles = 0;
    int maintenanceVehicles = 0;
    double totalCapacityKg = 0.0;

    for (Vehicle v : store.vehicles().values()) {
      totalCapacityKg += v.getMaxWeightCapacityKg();
      if (v.getStatus() == VehicleStatus.AVAILABLE) {
        availableVehicles++;
      } else if (v.getStatus() == VehicleStatus.DISPATCHED) {
        dispatchedVehicles++;
      } else {
        maintenanceVehicles++;
      }
    }

    int totalDrivers = store.drivers().size();
    int availableDrivers = 0;
    int dispatchedDrivers = 0;

    for (Driver d : store.drivers().values()) {
      if (d.isAvailable()) {
        availableDrivers++;
      } else {
        dispatchedDrivers++;
      }
    }

    int totalShipments = 0;
    int assignedCount = 0;
    int pickedUpCount = 0;
    int inTransitCount = 0;
    int deliveredCount = 0;

    for (Shipment s : store.shipments().values()) {
      if (isWithinRange(s.getCreatedAt().toLocalDate(), startDate, endDate)) {
        totalShipments++;
        String st = s.getStateName();
        if ("Assigned".equalsIgnoreCase(st)) {
          assignedCount++;
        } else if ("Picked Up".equalsIgnoreCase(st)) {
          pickedUpCount++;
        } else if ("In Transit".equalsIgnoreCase(st)) {
          inTransitCount++;
        } else if ("Delivered".equalsIgnoreCase(st)) {
          deliveredCount++;
        }
      }
    }

    metrics.put("Total Vehicles", String.valueOf(totalVehicles));
    metrics.put("Available Vehicles", String.valueOf(availableVehicles));
    metrics.put("Dispatched Vehicles", String.valueOf(dispatchedVehicles));
    metrics.put("Total Capacity (Kg)", String.format("%.0f", totalCapacityKg));
    metrics.put("Total Drivers", String.valueOf(totalDrivers));
    metrics.put("Available Drivers", String.valueOf(availableDrivers));
    metrics.put("Total Shipments", String.valueOf(totalShipments));
    metrics.put("Active Shipments", String.valueOf(assignedCount + pickedUpCount + inTransitCount));
    metrics.put("Delivered Shipments", String.valueOf(deliveredCount));

    StringBuilder sb = new StringBuilder();
    sb.append("=================================================================\n");
    sb.append("                 SMARTFM FLEET & DISPATCH REPORT                 \n");
    sb.append("=================================================================\n");
    sb.append("Report ID   : ").append(id).append("\n");
    sb.append("Date Range  : ").append(formatRange(startDate, endDate)).append("\n");
    sb.append("Generated At: ").append(LocalDate.now().format(DATE_FMT)).append("\n\n");

    sb.append("1. FLEET ASSET STATUS\n");
    sb.append("   - Total Registered Vehicles     : ").append(totalVehicles).append("\n");
    sb.append("   - Available Vehicles            : ").append(availableVehicles).append("\n");
    sb.append("   - Dispatched Vehicles           : ").append(dispatchedVehicles).append("\n");
    sb.append("   - Maintenance/Inactive Vehicles : ").append(maintenanceVehicles).append("\n");
    sb.append("   - Total Fleet Capacity          : ").append(String.format("%.0f kg", totalCapacityKg)).append("\n\n");

    sb.append("2. DRIVER STATUS\n");
    sb.append("   - Total Registered Drivers      : ").append(totalDrivers).append("\n");
    sb.append("   - Available Drivers             : ").append(availableDrivers).append("\n");
    sb.append("   - Currently Dispatched Drivers  : ").append(dispatchedDrivers).append("\n\n");

    sb.append("3. SHIPMENT LIFECYCLE METRICS\n");
    sb.append("   - Total Shipments (In Period)   : ").append(totalShipments).append("\n");
    sb.append("   - Assigned                      : ").append(assignedCount).append("\n");
    sb.append("   - Picked Up                     : ").append(pickedUpCount).append("\n");
    sb.append("   - In Transit                    : ").append(inTransitCount).append("\n");
    sb.append("   - Delivered                     : ").append(deliveredCount).append("\n");
    sb.append("=================================================================\n");

    return new Report(
        id, "Fleet Utilization & Dispatch Report", ReportCategory.FLEET,
        startDate, endDate, metrics, sb.toString());
  }

  public Report generateBranchReport(String branchId, LocalDate startDate, LocalDate endDate) {
    String id = reportIds.next();
    Map<String, String> metrics = new LinkedHashMap<>();

    Branch branch = (branchId != null && !branchId.isEmpty()) ? store.branches().get(branchId) : null;
    String branchName = branch != null ? branch.getName() : "All Branches";

    int vehicleCount = 0;
    for (Vehicle v : store.vehicles().values()) {
      if (branch == null || branchId.equals(v.getBranchId())) {
        vehicleCount++;
      }
    }

    int driverCount = 0;
    for (Driver d : store.drivers().values()) {
      if (branch == null || branchId.equals(d.getHomeBranchId())) {
        driverCount++;
      }
    }

    int originOrderCount = 0;
    int destOrderCount = 0;
    double branchQuotedRevenue = 0.0;

    for (Order order : store.orders().values()) {
      if (isWithinRange(order.getCreatedAt().toLocalDate(), startDate, endDate)) {
        boolean isOrigin = branch == null || branchId.equals(order.getOriginBranchId());
        boolean isDest = branch == null || branchId.equals(order.getDestinationBranchId());
        if (isOrigin) {
          originOrderCount++;
          if ("Approved".equals(order.getStateName())) {
            branchQuotedRevenue += order.getQuotedAmount();
          }
        }
        if (isDest) {
          destOrderCount++;
        }
      }
    }

    metrics.put("Branch Scope", branchName);
    metrics.put("Assigned Vehicles", String.valueOf(vehicleCount));
    metrics.put("Assigned Drivers", String.valueOf(driverCount));
    metrics.put("Originating Orders", String.valueOf(originOrderCount));
    metrics.put("Destination Orders", String.valueOf(destOrderCount));
    metrics.put("Branch Quoted Revenue", Money.format(branchQuotedRevenue) + " VND");

    StringBuilder sb = new StringBuilder();
    sb.append("=================================================================\n");
    sb.append("               SMARTFM BRANCH OPERATIONS SUMMARY                 \n");
    sb.append("=================================================================\n");
    sb.append("Report ID   : ").append(id).append("\n");
    sb.append("Branch      : ").append(branchName).append("\n");
    sb.append("Date Range  : ").append(formatRange(startDate, endDate)).append("\n");
    sb.append("Generated At: ").append(LocalDate.now().format(DATE_FMT)).append("\n\n");

    sb.append("1. BRANCH RESOURCES\n");
    sb.append("   - Branch Name                   : ").append(branchName).append("\n");
    sb.append("   - Fleet Vehicles Allocated      : ").append(vehicleCount).append("\n");
    sb.append("   - Drivers Assigned              : ").append(driverCount).append("\n\n");

    sb.append("2. ORDER & TRAFFIC VOLUME\n");
    sb.append("   - Orders Originating at Branch  : ").append(originOrderCount).append("\n");
    sb.append("   - Orders Destined for Branch    : ").append(destOrderCount).append("\n");
    sb.append("   - Approved Quoted Revenue       : ").append(Money.format(branchQuotedRevenue)).append(" VND\n");
    sb.append("=================================================================\n");

    return new Report(
        id, "Branch Summary - " + branchName, ReportCategory.BRANCH,
        startDate, endDate, metrics, sb.toString());
  }

  public Report generateOrderSummaryReport(LocalDate startDate, LocalDate endDate) {
    String id = reportIds.next();
    Map<String, String> metrics = new LinkedHashMap<>();

    int totalOrders = 0;
    int submittedCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;
    int cancelledCount = 0;

    double totalWeight = 0.0;
    double totalVolume = 0.0;

    for (Order o : store.orders().values()) {
      if (isWithinRange(o.getCreatedAt().toLocalDate(), startDate, endDate)) {
        totalOrders++;
        String state = o.getStateName();
        if ("Submitted".equalsIgnoreCase(state)) {
          submittedCount++;
        } else if ("Approved".equalsIgnoreCase(state)) {
          approvedCount++;
        } else if ("Rejected".equalsIgnoreCase(state)) {
          rejectedCount++;
        } else if ("Cancelled".equalsIgnoreCase(state)) {
          cancelledCount++;
        }
        totalWeight += o.getTotalWeightKg();
        totalVolume += o.getTotalVolumeM3();
      }
    }

    int totalCustomers = store.customers().size();
    int activeCustomers = 0;
    for (Customer c : store.customers().values()) {
      if (!c.getOrderIds().isEmpty()) {
        activeCustomers++;
      }
    }

    metrics.put("Total Customers", String.valueOf(totalCustomers));
    metrics.put("Active Customers", String.valueOf(activeCustomers));
    metrics.put("Total Orders", String.valueOf(totalOrders));
    metrics.put("Submitted Orders", String.valueOf(submittedCount));
    metrics.put("Approved Orders", String.valueOf(approvedCount));
    metrics.put("Rejected Orders", String.valueOf(rejectedCount));
    metrics.put("Cancelled Orders", String.valueOf(cancelledCount));
    metrics.put("Total Freight Weight (Kg)", String.format("%.2f", totalWeight));
    metrics.put("Total Freight Volume (M3)", String.format("%.2f", totalVolume));

    StringBuilder sb = new StringBuilder();
    sb.append("=================================================================\n");
    sb.append("               SMARTFM ORDER & COMMERCIAL SUMMARY                \n");
    sb.append("=================================================================\n");
    sb.append("Report ID   : ").append(id).append("\n");
    sb.append("Date Range  : ").append(formatRange(startDate, endDate)).append("\n");
    sb.append("Generated At: ").append(LocalDate.now().format(DATE_FMT)).append("\n\n");

    sb.append("1. CUSTOMER METRICS\n");
    sb.append("   - Total Registered Customers    : ").append(totalCustomers).append("\n");
    sb.append("   - Active Customers (with orders): ").append(activeCustomers).append("\n\n");

    sb.append("2. ORDER PIPELINE\n");
    sb.append("   - Total Orders (In Period)      : ").append(totalOrders).append("\n");
    sb.append("   - Pending Approval (Submitted)  : ").append(submittedCount).append("\n");
    sb.append("   - Approved Orders               : ").append(approvedCount).append("\n");
    sb.append("   - Rejected Orders               : ").append(rejectedCount).append("\n");
    sb.append("   - Cancelled Orders              : ").append(cancelledCount).append("\n\n");

    sb.append("3. FREIGHT METRICS\n");
    sb.append("   - Aggregate Weight Handled      : ").append(String.format("%.2f kg", totalWeight)).append("\n");
    sb.append("   - Aggregate Volume Handled      : ").append(String.format("%.2f m³", totalVolume)).append("\n");
    sb.append("=================================================================\n");

    return new Report(
        id, "Order & Commercial Summary Report", ReportCategory.ORDER_SUMMARY,
        startDate, endDate, metrics, sb.toString());
  }

  private boolean isWithinRange(LocalDate date, LocalDate start, LocalDate end) {
    if (date == null) {
      return true;
    }
    if (start != null && date.isBefore(start)) {
      return false;
    }
    if (end != null && date.isAfter(end)) {
      return false;
    }
    return true;
  }

  private String formatRange(LocalDate start, LocalDate end) {
    if (start == null && end == null) {
      return "All time";
    }
    String s = start != null ? start.format(DATE_FMT) : "Beginning";
    String e = end != null ? end.format(DATE_FMT) : "Present";
    return s + " - " + e;
  }
}
