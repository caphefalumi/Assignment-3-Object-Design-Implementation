package smartfm.common;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@DisplayName("Validators Helper Tests")
class ValidatorsTest {

  @Test
  @DisplayName("Should validate non-blank strings and enforce max length")
  void testRequireNonBlank() {
    assertEquals("Hello", Validators.requireNonBlank("  Hello  ", "Field", 10));

    InvalidDataException nullEx = assertThrows(
        InvalidDataException.class,
        () -> Validators.requireNonBlank(null, "Name", 10));
    assertEquals("Name cannot be blank.", nullEx.getMessage());

    InvalidDataException emptyEx = assertThrows(
        InvalidDataException.class,
        () -> Validators.requireNonBlank("   ", "Name", 10));
    assertEquals("Name cannot be blank.", emptyEx.getMessage());

    InvalidDataException lengthEx = assertThrows(
        InvalidDataException.class,
        () -> Validators.requireNonBlank("Too Long Text", "Name", 5));
    assertEquals("Name exceeds the maximum length of 5 characters.", lengthEx.getMessage());
  }

  @ParameterizedTest
  @ValueSource(strings = {"user@example.com", "john.doe@sub.domain.co.uk", "a@b.c"})
  @DisplayName("Should accept valid email addresses")
  void testValidEmails(String email) {
    assertEquals(email, Validators.requireEmail(email, "Email"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"invalid-email", "missing@domain", "@nodomain.com", "spaces in@email.com"})
  @DisplayName("Should reject invalid email addresses")
  void testInvalidEmails(String email) {
    assertThrows(InvalidDataException.class, () -> Validators.requireEmail(email, "Email"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"+61412345678", "0412345678", "+1 800 555 0199", "123-456-7890"})
  @DisplayName("Should accept valid phone numbers")
  void testValidPhones(String phone) {
    assertEquals(phone.trim(), Validators.requirePhone(phone, "Phone"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"abc", "123", "+", "phone#12345678"})
  @DisplayName("Should reject invalid phone numbers")
  void testInvalidPhones(String phone) {
    assertThrows(InvalidDataException.class, () -> Validators.requirePhone(phone, "Phone"));
  }

  @Test
  @DisplayName("Should enforce positive and non-negative numbers")
  void testNumericValidators() {
    assertEquals(10.5, Validators.requirePositive(10.5, "Weight"));
    assertThrows(InvalidDataException.class, () -> Validators.requirePositive(0.0, "Weight"));
    assertThrows(InvalidDataException.class, () -> Validators.requirePositive(-5.0, "Weight"));

    assertEquals(0.0, Validators.requireNonNegative(0.0, "Discount"));
    assertEquals(5.0, Validators.requireNonNegative(5.0, "Discount"));
    assertThrows(InvalidDataException.class, () -> Validators.requireNonNegative(-1.0, "Discount"));

    assertEquals(25.0, Validators.parsePositiveNumber("25.0", "Quantity"));
    assertThrows(InvalidDataException.class, () -> Validators.parsePositiveNumber("abc", "Quantity"));
  }

  @Test
  @DisplayName("Should validate date formats and constraints")
  void testDateValidators() {
    LocalDate today = LocalDate.now();
    LocalDate tomorrow = today.plusDays(1);
    LocalDate yesterday = today.minusDays(1);

    assertEquals(today, Validators.requireValidDate(Validators.formatDate(today), "Date"));
    assertThrows(InvalidDataException.class,
        () -> Validators.requireValidDate("invalid-date", "Date"));

    assertEquals(today, Validators.requirePastOrTodayDate(
        Validators.formatDateOfBirth(today), "Date"));
    assertEquals("10/04/1995", Validators.formatDateOfBirth(LocalDate.of(1995, 4, 10)));
    assertThrows(InvalidDataException.class,
        () -> Validators.requirePastOrTodayDate("invalid-date", "Date"));
    assertThrows(InvalidDataException.class,
        () -> Validators.requirePastOrTodayDate("31/02/1995", "Date"));

    assertDoesNotThrow(() -> Validators.requireTodayOrFuture(Validators.formatDate(today), "Date"));
    assertDoesNotThrow(() -> Validators.requireTodayOrFuture(Validators.formatDate(tomorrow), "Date"));
    assertThrows(InvalidDataException.class, () -> Validators.requireTodayOrFuture(Validators.formatDate(yesterday), "Date"));

    assertDoesNotThrow(() -> Validators.requirePastOrTodayDate(
        Validators.formatDateOfBirth(today), "Date"));
    assertDoesNotThrow(() -> Validators.requirePastOrTodayDate(
        Validators.formatDateOfBirth(yesterday), "Date"));
    assertThrows(InvalidDataException.class, () -> Validators.requirePastOrTodayDate(
        Validators.formatDateOfBirth(tomorrow), "Date"));
  }
}
