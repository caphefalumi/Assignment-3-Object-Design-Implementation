package smartfm.ui.gui;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import smartfm.application.Bootstrap;
import smartfm.application.DispatchManager;
import smartfm.application.OrderProcessor;
import smartfm.application.PaymentProcessor;
import smartfm.application.ShipmentTracker;
import smartfm.infrastructure.DataStore;

/**
 * Shared application state for the Swing GUI: one {@link DataStore} and
 * one {@link Bootstrap} instance for the lifetime of the window,
 * exactly mirroring how {@code SmartFmConsoleApp} holds a single
 * instance of each. This class does not contain any business logic
 * itself; it is a thin holder that lets every panel reach the same
 * four controllers (Assignment 2 Section 5.3.1, Facade pattern) without
 * duplicating the bootstrap sequence per panel.
 *
 * <p>Because several panels display data that another panel may have
 * just changed (e.g. placing an order changes what {@code
 * FleetDispatchPanel} shows as "approved orders awaiting dispatch"),
 * this class also runs a minimal in-process Observer/publish-subscribe
 * mechanism: panels register a {@link Runnable} refresh callback here,
 * and any panel that mutates shared state calls {@link #notifyChanged()}
 * afterwards. This keeps panels decoupled from one another, the same
 * low-coupling goal the four business-area controllers already apply
 * to each other (Assignment 2 Section 4.1.3).
 */
public final class GuiContext {

  private final Path dataFile;
  private final DataStore store;
  private final Bootstrap bootstrap;
  private final List<Runnable> changeListeners = new ArrayList<>();

  public GuiContext(Path dataFile) {
    this.dataFile = dataFile;
    this.store = DataStore.loadFrom(dataFile);
    this.bootstrap = new Bootstrap(store);
    this.bootstrap.run();
    this.store.saveTo(dataFile);
  }

  public DataStore getStore() {
    return store;
  }

  public OrderProcessor getOrderProcessor() {
    return bootstrap.getOrderProcessor();
  }

  public DispatchManager getDispatchManager() {
    return bootstrap.getDispatchManager();
  }

  public ShipmentTracker getShipmentTracker() {
    return bootstrap.getShipmentTracker();
  }

  public PaymentProcessor getPaymentProcessor() {
    return bootstrap.getPaymentProcessor();
  }

  public void addChangeListener(Runnable listener) {
    changeListeners.add(listener);
  }

  /** Called by any panel after a successful mutation, so other panels can refresh their views and persist changes to SQLite. */
  public void notifyChanged() {
    save();
    for (Runnable listener : changeListeners) {
      listener.run();
    }
  }

  public void save() {
    store.saveTo(dataFile);
  }

  public Path getDataFile() {
    return dataFile;
  }
}
