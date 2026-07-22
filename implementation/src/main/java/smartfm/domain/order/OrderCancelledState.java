package smartfm.domain.order;

/** Terminal state reached when a customer withdraws an order before approval. */
public class OrderCancelledState extends OrderState {

  private static final long serialVersionUID = 1L;

  @Override
  public String name() {
    return "Cancelled";
  }
}
