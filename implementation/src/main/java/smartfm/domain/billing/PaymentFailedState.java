package smartfm.domain.billing;

import smartfm.common.Validators;

/** Terminal state of a {@link Payment} when the gateway declines the transaction. */
public class PaymentFailedState extends PaymentState {

  private static final long serialVersionUID = 1L;

  private final String reason;

  public PaymentFailedState(String reason) {
    this.reason = Validators.requireNonBlank(reason, "Failure reason", 200);
  }

  public String getReason() {
    return reason;
  }

  @Override
  public String name() {
    return "Failed (" + reason + ")";
  }
}
