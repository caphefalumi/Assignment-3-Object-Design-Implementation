package smartfm.domain;

import smartfm.common.Validators;

/** Terminal state reached when a dispatcher rejects a submitted order. */
public class OrderRejectedState extends OrderState {

  private static final long serialVersionUID = 1L;

  private final String reason;

  public OrderRejectedState(String reason) {
    this.reason = Validators.requireNonBlank(reason, "Rejection reason", 200);
  }

  public String getReason() {
    return reason;
  }

  @Override
  public String name() {
    return "Rejected (" + reason + ")";
  }
}
