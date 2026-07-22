package smartfm.application;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Generates short, readable, sequential ids such as {@code ORD-0004} or
 * {@code INV-0012}. Seeded from the current size of the relevant
 * repository map so that ids stay stable and sequential even after
 * reloading a persisted {@link smartfm.infrastructure.DataStore}.
 */
public final class IdGenerator {

  private final String prefix;
  private final AtomicInteger counter;

  public IdGenerator(String prefix, Map<String, ?> existing) {
    this.prefix = prefix;
    this.counter = new AtomicInteger(existing.size());
  }

  public String next() {
    int value = counter.incrementAndGet();
    return String.format("%s-%04d", prefix, value);
  }
}
