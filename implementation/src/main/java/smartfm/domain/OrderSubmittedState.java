package smartfm.domain;

/** Initial state of an {@link Order} immediately after customer submission. */
public class OrderSubmittedState extends OrderState {

  private static final long serialVersionUID = 1L;

  @Override
  public void approve(Order order) {
    order.setState(new OrderApprovedState());
  }

  @Override
  public void reject(Order order, String reason) {
    order.setState(new OrderRejectedState(reason));
  }

  @Override
  public void cancel(Order order) {
    order.setState(new OrderCancelledState());
  }

  @Override
  public String name() {
    return "Submitted";
  }
}
