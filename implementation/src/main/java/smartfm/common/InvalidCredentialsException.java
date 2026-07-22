package smartfm.common;

/**
 * Thrown when a login attempt fails. Deliberately generic: the caller is
 * never told whether the username or the password was the incorrect
 * field, to avoid leaking account existence (Assignment 2 Section 1.3.1).
 */
public class InvalidCredentialsException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  public InvalidCredentialsException(String message) {
    super(message);
  }
}
