package smartfm.ui;

import java.util.Scanner;
import smartfm.common.InvalidDataException;

/**
 * Small console input helper shared by every menu in {@link
 * SmartFmConsoleApp}. Centralises the "prompt, validate, re-prompt on
 * error, allow cancel" loop so every business-area workflow presents
 * input validation consistently (Assignment 3 brief: "label/mention each
 * of the input requirements clearly and provide appropriate validation
 * on inputs").
 */
public final class ConsoleIO {

  public static final String CANCEL_TOKEN = "c";

  private final Scanner scanner;

  public ConsoleIO(Scanner scanner) {
    this.scanner = scanner;
  }

  public void println(String message) {
    System.out.println(message);
  }

  public void printHeader(String title) {
    System.out.println();
    System.out.println("==== " + title + " ====");
  }

  /** Reads a raw line, trimmed. Returns {@code null} if the user typed the cancel token. */
  public String readLineOrCancel(String prompt) {
    System.out.print(prompt + " (or 'c' to cancel): ");
    String raw = scanner.nextLine();
    if (raw == null) {
      return null;
    }
    String trimmed = raw.trim();
    if (trimmed.equalsIgnoreCase(CANCEL_TOKEN)) {
      return null;
    }
    return trimmed;
  }

  public String readLine(String prompt) {
    System.out.print(prompt + ": ");
    String raw = scanner.nextLine();
    return raw == null ? "" : raw.trim();
  }

  /**
   * Repeatedly prompts using {@code validator} until it succeeds or the
   * user cancels, printing the {@link InvalidDataException} message and
   * looping on failure so the same field can be corrected in place.
   */
  public <T> T readValidated(String prompt, java.util.function.Function<String, T> validator) {
    while (true) {
      String raw = readLineOrCancel(prompt);
      if (raw == null) {
        return null;
      }
      try {
        return validator.apply(raw);
      } catch (InvalidDataException exc) {
        System.out.println("  [Invalid input] " + exc.getMessage() + " Please try again.");
      }
    }
  }
}
