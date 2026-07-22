# SmartFM - Assignment 3 Makefile
# Requires a Java 17+ JDK. On Windows this Makefile is verified with
# GNU Make 4.4.1 and PowerShell; on Unix-like systems it uses POSIX tools.

JAVAC     = javac
JAVA      = java
JAR       = jar

SRC_DIR   = src/main/java
OUT_DIR   = target/classes
TOOLS_OUT = target/tools-classes
JAR_FILE  = target/smartfm.jar
MAIN      = smartfm.ui.Launcher
TOOLS_SRC = tools/java/smartfm/ui/gui/ScreenshotDriver.java

.PHONY: all compile jar run run-cli tools screenshots clean reset

all: compile

ifeq ($(OS),Windows_NT)

# Native Windows / PowerShell recipes. The response file preserves spaces in
# absolute paths (for example, the assignment workspace path) when javac runs.
compile:
	@if not exist "$(OUT_DIR)" mkdir "$(OUT_DIR)"
	@powershell -NoProfile -Command "$$sources = Get-ChildItem -Recurse -Filter *.java '$(SRC_DIR)' | ForEach-Object { $$_.FullName }; & $(JAVAC) -d '$(OUT_DIR)' -encoding UTF-8 -Xlint:all $$sources; if ($$LASTEXITCODE -ne 0) { exit $$LASTEXITCODE }; Write-Output ('Compiled ' + $$sources.Count + ' source files to $(OUT_DIR)')"

jar: compile
	@if not exist "target" mkdir "target"
	$(JAR) cfe "$(JAR_FILE)" $(MAIN) -C "$(OUT_DIR)" .
	@echo Built $(JAR_FILE)

run: compile
	$(JAVA) -cp "$(OUT_DIR)" $(MAIN)

run-cli: compile
	$(JAVA) -cp "$(OUT_DIR)" $(MAIN) --cli

tools: compile
	@if not exist "$(TOOLS_OUT)" mkdir "$(TOOLS_OUT)"
	$(JAVAC) -d "$(TOOLS_OUT)" -cp "$(OUT_DIR)" -encoding UTF-8 "$(TOOLS_SRC)"
	@echo Built screenshot driver to $(TOOLS_OUT)

screenshots: tools reset
	$(JAVA) -cp "$(OUT_DIR);$(TOOLS_OUT)" smartfm.ui.gui.ScreenshotDriver
	@echo Screenshots saved to screenshots/

clean:
	@if exist "target" rmdir /s /q "target"

reset: clean
	@if exist "data\smartfm-store.dat" del /q "data\smartfm-store.dat"
	@if exist "data\smartfm-store.dat.tmp" del /q "data\smartfm-store.dat.tmp"

else

SOURCES = $(shell find $(SRC_DIR) -name "*.java")

compile: $(SOURCES)
	@mkdir -p "$(OUT_DIR)"
	$(JAVAC) -d "$(OUT_DIR)" -encoding UTF-8 -Xlint:all $(SOURCES)
	@echo "Compiled $$(echo $(SOURCES) | wc -w) source files to $(OUT_DIR)"

jar: compile
	$(JAR) cfe "$(JAR_FILE)" $(MAIN) -C "$(OUT_DIR)" .
	@echo "Built $(JAR_FILE)"

run: compile
	$(JAVA) -cp "$(OUT_DIR)" $(MAIN)

run-cli: compile
	$(JAVA) -cp "$(OUT_DIR)" $(MAIN) --cli

tools: compile $(TOOLS_SRC)
	@mkdir -p "$(TOOLS_OUT)"
	$(JAVAC) -d "$(TOOLS_OUT)" -cp "$(OUT_DIR)" -encoding UTF-8 "$(TOOLS_SRC)"
	@echo "Built screenshot driver to $(TOOLS_OUT)"

screenshots: tools reset
	$(JAVA) -cp "$(OUT_DIR):$(TOOLS_OUT)" smartfm.ui.gui.ScreenshotDriver
	@echo "Screenshots saved to screenshots/"

clean:
	rm -rf "$(OUT_DIR)" "$(JAR_FILE)" "$(TOOLS_OUT)"

reset: clean
	rm -f data/smartfm-store.dat data/smartfm-store.dat.tmp

endif
