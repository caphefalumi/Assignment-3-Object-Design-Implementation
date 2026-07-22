package smartfm.domain;

import java.io.Serializable;

/**
 * Data-holder class storing global operational variables, security
 * limits, and default constants (Assignment 2 Section 3, System Control
 * and Configuration Package). Loaded once during bootstrap and treated
 * as read-only afterwards (Singleton-style controlled configuration
 * instance, Assignment 2 Section 5.1.2) - a single, package-private
 * constructor plus a static factory keeps exactly one instance alive
 * for the lifetime of the running application.
 */
public final class SystemConfiguration implements Serializable {

  private static final long serialVersionUID = 1L;

  private static SystemConfiguration instance;

  private final int maxFailedLoginAttempts;
  private final double defaultPeakMultiplier;
  private final int sessionTimeoutMinutes;

  private SystemConfiguration(int maxFailedLoginAttempts, double defaultPeakMultiplier,
      int sessionTimeoutMinutes) {
    this.maxFailedLoginAttempts = maxFailedLoginAttempts;
    this.defaultPeakMultiplier = defaultPeakMultiplier;
    this.sessionTimeoutMinutes = sessionTimeoutMinutes;
  }

  /** Bootstrap Step 1 (Assignment 2 Section 6.2): loaded before any other class. */
  public static synchronized SystemConfiguration bootstrap() {
    if (instance == null) {
      instance = new SystemConfiguration(5, 1.2, 30);
    }
    return instance;
  }

  public static synchronized SystemConfiguration getInstance() {
    if (instance == null) {
      throw new IllegalStateException("SystemConfiguration has not been bootstrapped yet.");
    }
    return instance;
  }

  public int getMaxFailedLoginAttempts() {
    return maxFailedLoginAttempts;
  }

  public double getDefaultPeakMultiplier() {
    return defaultPeakMultiplier;
  }

  public int getSessionTimeoutMinutes() {
    return sessionTimeoutMinutes;
  }
}
