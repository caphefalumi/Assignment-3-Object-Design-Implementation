package smartfm.domain.order;

/** State of an {@link Order} once a dispatcher has approved it for dispatch. */
public class OrderApprovedState extends OrderState {

  private static final long serialVersionUID = 1L;

  @Override
  public String name() {
    return "Approved";
  }
}
