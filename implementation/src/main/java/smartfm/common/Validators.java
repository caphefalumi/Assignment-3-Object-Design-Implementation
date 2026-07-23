package smartfm.common;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.Arrays;

/**
 * Shared, stateless validation helpers used by domain classes to enforce
 * the boundary rules from Assignment 2 Section 1.3.2 (e.g. text fields
 * must respect character limits, numeric fields such as weight and
 * distance must be positive, dates must not be in the past).
 *
 * <p>This class does not decide policy on its own behalf; each domain
 * class calls into it and then raises its own {@link InvalidDataException}
 * with a field-specific message, per Assumption A2 (classes validate
 * their own data rather than relying on a single global validator).
 */
public final class Validators {

  private static final DateTimeFormatter DATE_FORMAT =
      DateTimeFormatter.ofPattern("dd/MM/uuuu").withResolverStyle(ResolverStyle.STRICT);

  private Validators() {}

  public static String requireNonBlank(String value, String fieldName, int maxLength) {
    if (value == null || value.trim().isEmpty()) {
      throw new InvalidDataException(fieldName + " cannot be blank.");
    }
    String trimmed = value.trim();
    if (trimmed.length() > maxLength) {
      throw new InvalidDataException(
          fieldName + " exceeds the maximum length of " + maxLength + " characters.");
    }
    return trimmed;
  }

  public static String requireEmail(String value, String fieldName) {
    String trimmed = requireNonBlank(value, fieldName, 120);
    if (!trimmed.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
      throw new InvalidDataException(fieldName + " '" + trimmed + "' is not a valid email address.");
    }
    return trimmed;
  }

  public static String requirePhone(String value, String fieldName) {
    String trimmed = requireNonBlank(value, fieldName, 20);
    if (!trimmed.matches("^\\+?[0-9][0-9\\-\\s]{6,14}$")) {
      throw new InvalidDataException(
          fieldName + " '" + trimmed + "' is not a valid phone number.");
    }
    return trimmed;
  }

  public static double requirePositive(double value, String fieldName) {
    if (value <= 0) {
      throw new InvalidDataException(fieldName + " must be a positive number.");
    }
    return value;
  }

  public static double requireNonNegative(double value, String fieldName) {
    if (value < 0) {
      throw new InvalidDataException(fieldName + " cannot be negative.");
    }
    return value;
  }

  public static double parsePositiveNumber(String raw, String fieldName) {
    double value;
    try {
      value = Double.parseDouble(raw.trim());
    } catch (NumberFormatException | NullPointerException exc) {
      throw new InvalidDataException(fieldName + " must be a valid number.");
    }
    return requirePositive(value, fieldName);
  }

  public static LocalDate requireTodayOrFuture(String raw, String fieldName) {
    return requireTodayOrFuture(requireValidDate(raw, fieldName), fieldName);
  }

  /** Validates a date supplied by an application or domain caller rather than a text boundary. */
  public static LocalDate requireTodayOrFuture(LocalDate value, String fieldName) {
    if (value == null) {
      throw new InvalidDataException(fieldName + " is required.");
    }
    if (value.isBefore(LocalDate.now())) {
      throw new InvalidDataException(fieldName + " cannot be in the past.");
    }
    return value;
  }

  public static LocalDate requireValidDate(String raw, String fieldName) {
    String trimmed = requireNonBlank(raw, fieldName, 10);
    try {
      return LocalDate.parse(trimmed, DATE_FORMAT);
    } catch (DateTimeParseException exc) {
      throw new InvalidDataException(fieldName + " must be a valid date in DD/MM/YYYY format.");
    }
  }

  public static LocalDate requirePastOrTodayDate(String raw, String fieldName) {
    String trimmed = requireNonBlank(raw, fieldName, 10);
    final LocalDate parsed;
    try {
      parsed = LocalDate.parse(trimmed, DATE_FORMAT);
    } catch (DateTimeParseException exc) {
      throw new InvalidDataException(fieldName + " must be a valid date in DD/MM/YYYY format.");
    }
    if (parsed.isAfter(LocalDate.now())) {
      throw new InvalidDataException(fieldName + " cannot be in the future.");
    }
    return parsed;
  }

  /** Formats a date for user-facing output in DD/MM/YYYY format. */
  public static String formatDate(LocalDate value) {
    if (value == null) {
      return "";
    }
    return DATE_FORMAT.format(value);
  }

  /** Formats a date of birth for user-facing output. */
  public static String formatDateOfBirth(LocalDate value) {
    if (value == null) {
      throw new InvalidDataException("Date of birth is required.");
    }
    return DATE_FORMAT.format(value);
  }

  public static <T extends Enum<T>> T requireEnum(String raw, Class<T> enumType, String fieldName) {
    String trimmed = requireNonBlank(raw, fieldName, 40).toUpperCase();
    try {
      return Enum.valueOf(enumType, trimmed);
    } catch (IllegalArgumentException exc) {
      throw new InvalidDataException(
          fieldName + " must be one of " + Arrays.toString(enumType.getEnumConstants())
              + " (got '" + trimmed + "').");
    }
  }
}
