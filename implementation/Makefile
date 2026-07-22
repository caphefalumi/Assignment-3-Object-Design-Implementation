# SmartFM - Assignment 3 Makefile
# Works on Windows (via GNU Make for Windows / GnuWin32 / MSYS2) and
# Unix-like systems. Requires only a Java 17+ JDK on the PATH.

JAVAC     = javac
JAVA      = java
JAR       = jar

SRC_DIR   = src/main/java
OUT_DIR   = target/classes
JAR_FILE  = target/smartfm.jar
MAIN      = smartfm.ui.Launcher

SOURCES   = $(shell find $(SRC_DIR) -name "*.java")

.PHONY: all compile jar run run-cli clean reset

all: compile

compile: $(SOURCES)
	@mkdir -p $(OUT_DIR)
	$(JAVAC) -d $(OUT_DIR) -encoding UTF-8 -Xlint:all $(SOURCES)
	@echo "Compiled $$(echo $(SOURCES) | wc -w) source files to $(OUT_DIR)"

jar: compile
	$(JAR) cfe $(JAR_FILE) $(MAIN) -C $(OUT_DIR) .
	@echo "Built $(JAR_FILE)"

run: compile
	$(JAVA) -cp $(OUT_DIR) $(MAIN)

run-cli: compile
	$(JAVA) -cp $(OUT_DIR) $(MAIN) --cli

clean:
	rm -rf $(OUT_DIR) $(JAR_FILE) target/tools-classes

reset: clean
	rm -f data/smartfm-store.dat data/smartfm-store.dat.tmp

# --- Development tools (not part of the shipped application) ---

TOOLS_SRC = tools/java/smartfm/ui/gui/ScreenshotDriver.java
TOOLS_OUT = target/tools-classes

tools: compile $(TOOLS_SRC)
	@mkdir -p $(TOOLS_OUT)
	$(JAVAC) -d $(TOOLS_OUT) -cp $(OUT_DIR) -encoding UTF-8 $(TOOLS_SRC)
	@echo "Built screenshot driver to $(TOOLS_OUT)"

screenshots: tools reset
	$(JAVA) -cp "$(OUT_DIR):$(TOOLS_OUT)" smartfm.ui.gui.ScreenshotDriver
	@echo "Screenshots saved to screenshots/"
