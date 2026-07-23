package smartfm.ui.gui;

import java.awt.BorderLayout;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;
import smartfm.common.InvalidDataException;
import smartfm.common.Validators;
import smartfm.domain.shipment.Shipment;

/**
 * GUI panel for Business Area 3: Shipment Tracking. Reuses {@link
 * smartfm.application.ShipmentTracker} unchanged. Depends on Business
 * Area 2 (a shipment must already exist with an assigned vehicle and
 * driver before it can be tracked here).
 */
@SuppressWarnings({"serial", "this-escape"})
public class ShipmentTrackingPanel extends JPanel {

  private static final long serialVersionUID = 1L;

  private final GuiContext context;

  private final DefaultTableModel shipmentsModel =
      new DefaultTableModel(new Object[] {"Shipment Id", "Status", "Last Known Location"}, 0);
  private final JTable shipmentsTable = new JTable(shipmentsModel);

  private final ValidatedField locationField = new ValidatedField("Current location description:");
  private final ResultBanner banner = new ResultBanner();

  public ShipmentTrackingPanel(GuiContext context) {
    super(new BorderLayout(10, 10));
    this.context = context;
    setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));

    JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, buildTableSection(), buildActionSection());
    split.setResizeWeight(0.6);
    add(split, BorderLayout.CENTER);

    context.addChangeListener(this::refreshTable);
    refreshTable();
  }

  private JPanel buildTableSection() {
    JPanel section = new JPanel(new BorderLayout());
    section.setBorder(BorderFactory.createTitledBorder("Shipments (empty until Business Area 2 dispatches an order)"));
    section.add(new JScrollPane(shipmentsTable), BorderLayout.CENTER);
    return section;
  }

  private JPanel buildActionSection() {
    JPanel section = new JPanel(new BorderLayout(6, 6));
    section.setBorder(BorderFactory.createTitledBorder("Update Selected Shipment"));

    section.add(locationField, BorderLayout.NORTH);

    JButton pickupBtn = new JButton("Confirm Pickup");
    pickupBtn.addActionListener(e -> apply(context.getShipmentTracker()::confirmPickup));
    JButton transitBtn = new JButton("Confirm In Transit");
    transitBtn.addActionListener(e -> apply(context.getShipmentTracker()::confirmInTransit));
    JButton deliverBtn = new JButton("Confirm Delivery");
    deliverBtn.addActionListener(e -> apply(context.getShipmentTracker()::confirmDelivery));

    JPanel buttons = new JPanel();
    buttons.add(pickupBtn);
    buttons.add(transitBtn);
    buttons.add(deliverBtn);

    JPanel south = new JPanel(new BorderLayout());
    south.add(buttons, BorderLayout.NORTH);
    south.add(banner, BorderLayout.SOUTH);

    section.add(south, BorderLayout.SOUTH);
    return section;
  }

  private interface Transition {
    void apply(String shipmentId, String location);
  }

  private void apply(Transition transition) {
    int row = shipmentsTable.getSelectedRow();
    if (row < 0) {
      banner.error("Select a shipment from the table above first.");
      return;
    }
    String shipmentId = (String) shipmentsModel.getValueAt(row, 0);
    String location = locationField.validate(v -> Validators.requireNonBlank(v, "Location", 120));
    if (location == null) {
      banner.error("Please correct the highlighted location field.");
      return;
    }
    try {
      transition.apply(shipmentId, location);
      Shipment shipment = context.getStore().shipments().get(shipmentId);
      banner.success("shipment " + shipmentId + " is now '" + shipment.getStateName()
          + "' at " + shipment.getLastKnownLocation() + ".");
      locationField.reset();
      context.notifyChanged();
    } catch (InvalidDataException exc) {
      banner.error(exc.getMessage());
    }
  }

  private void refreshTable() {
    int previouslySelected = shipmentsTable.getSelectedRow();
    String previousId = previouslySelected >= 0 ? (String) shipmentsModel.getValueAt(previouslySelected, 0) : null;
    shipmentsModel.setRowCount(0);
    int newSelection = -1;
    int i = 0;
    for (Shipment shipment : context.getStore().shipments().values()) {
      shipmentsModel.addRow(new Object[] {
          shipment.getId(), shipment.getStateName(), shipment.getLastKnownLocation()
      });
      if (shipment.getId().equals(previousId)) {
        newSelection = i;
      }
      i++;
    }
    if (newSelection >= 0) {
      shipmentsTable.setRowSelectionInterval(newSelection, newSelection);
    }
  }

  // ---------------------------------------------------------------
  // Package-private accessors used only by ScreenshotDriver (evidence
  // capture for asm3.typ). Not part of the panel's public API.
  // ---------------------------------------------------------------

  JTable shipmentsTable() {
    return shipmentsTable;
  }

  ValidatedField locationField() {
    return locationField;
  }

  void clickConfirmPickup() {
    apply(context.getShipmentTracker()::confirmPickup);
  }

  void clickConfirmInTransit() {
    apply(context.getShipmentTracker()::confirmInTransit);
  }

  void clickConfirmDelivery() {
    apply(context.getShipmentTracker()::confirmDelivery);
  }
}
