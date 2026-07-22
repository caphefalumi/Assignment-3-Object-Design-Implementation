# SmartFM - Assignment 3 Makefile
# Requires a Java 26+ JDK and the pinned SQLite/jOOQ/JAXB runtime JARs under lib/.
# Windows recipes are verified with GNU Make 4.4.1 and PowerShell.

JAVAC          = javac
JAVA           = java --enable-native-access=ALL-UNNAMED
JAR            = jar

SRC_DIR        = src/main/java
OUT_DIR        = target/classes
TOOLS_OUT      = target/tools-classes
TARGET_LIB     = target/lib
JAR_FILE       = target/smartfm.jar
MAIN           = smartfm.ui.Launcher
TOOLS_SRC      = tools/java/smartfm/ui/gui/ScreenshotDriver.java
SQLITE_JAR     = lib/sqlite-jdbc-3.46.1.0.jar
JOOQ_JAR       = lib/jooq-3.20.0.jar
R2DBC_SPI_JAR  = lib/r2dbc-spi-1.0.0.RELEASE.jar
REACTIVE_STREAMS_JAR = lib/reactive-streams-1.0.3.jar
JAXB_API_JAR   = lib/jakarta.xml.bind-api-4.0.1.jar
ACTIVATION_API_JAR = lib/jakarta.activation-api-2.1.2.jar
SLF4J_API_JAR  = lib/slf4j-api-1.7.36.jar
SLF4J_NOP_JAR  = lib/slf4j-nop-1.7.36.jar
SQLITE_NAME    = sqlite-jdbc-3.46.1.0.jar
JOOQ_NAME      = jooq-3.20.0.jar
R2DBC_SPI_NAME = r2dbc-spi-1.0.0.RELEASE.jar
REACTIVE_STREAMS_NAME = reactive-streams-1.0.3.jar
JAXB_API_NAME  = jakarta.xml.bind-api-4.0.1.jar
ACTIVATION_API_NAME = jakarta.activation-api-2.1.2.jar
SLF4J_API_NAME = slf4j-api-1.7.36.jar
SLF4J_NOP_NAME = slf4j-nop-1.7.36.jar

.PHONY: all compile jar run run-cli tools screenshots clean reset

all: compile

ifeq ($(OS),Windows_NT)

DEPS_CP = $(SQLITE_JAR);$(JOOQ_JAR);$(R2DBC_SPI_JAR);$(REACTIVE_STREAMS_JAR);$(JAXB_API_JAR);$(ACTIVATION_API_JAR);$(SLF4J_API_JAR);$(SLF4J_NOP_JAR)

compile:
	@if not exist "$(SQLITE_JAR)" (echo Missing pinned dependency: $(SQLITE_JAR) & exit /b 1)
	@if not exist "$(JOOQ_JAR)" (echo Missing pinned dependency: $(JOOQ_JAR) & exit /b 1)
	@if not exist "$(R2DBC_SPI_JAR)" (echo Missing pinned dependency: $(R2DBC_SPI_JAR) & exit /b 1)
	@if not exist "$(REACTIVE_STREAMS_JAR)" (echo Missing pinned dependency: $(REACTIVE_STREAMS_JAR) & exit /b 1)
	@if not exist "$(JAXB_API_JAR)" (echo Missing pinned dependency: $(JAXB_API_JAR) & exit /b 1)
	@if not exist "$(ACTIVATION_API_JAR)" (echo Missing pinned dependency: $(ACTIVATION_API_JAR) & exit /b 1)
	@if not exist "$(SLF4J_API_JAR)" (echo Missing pinned dependency: $(SLF4J_API_JAR) & exit /b 1)
	@if not exist "$(SLF4J_NOP_JAR)" (echo Missing pinned dependency: $(SLF4J_NOP_JAR) & exit /b 1)
	@if not exist "$(OUT_DIR)" mkdir "$(OUT_DIR)"
	@powershell -NoProfile -Command "$$sources = Get-ChildItem -Recurse -Filter *.java '$(SRC_DIR)' | ForEach-Object { $$_.FullName }; & $(JAVAC) -cp '$(DEPS_CP)' -d '$(OUT_DIR)' -encoding UTF-8 -Xlint:all $$sources; if ($$LASTEXITCODE -ne 0) { exit $$LASTEXITCODE }; Write-Output ('Compiled ' + $$sources.Count + ' source files to $(OUT_DIR) with SQLite/jOOQ')"

jar: compile
	@powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'target/lib' | Out-Null; Copy-Item -Force '$(SQLITE_JAR)', '$(JOOQ_JAR)', '$(R2DBC_SPI_JAR)', '$(REACTIVE_STREAMS_JAR)', '$(JAXB_API_JAR)', '$(ACTIVATION_API_JAR)', '$(SLF4J_API_JAR)', '$(SLF4J_NOP_JAR)' -Destination 'target/lib'; Set-Content -Encoding Ascii -Path 'target/MANIFEST.MF' -Value @('Manifest-Version: 1.0', 'Main-Class: $(MAIN)', 'Class-Path: lib/$(SQLITE_NAME) lib/$(JOOQ_NAME) lib/$(R2DBC_SPI_NAME) lib/$(REACTIVE_STREAMS_NAME) lib/$(JAXB_API_NAME) lib/$(ACTIVATION_API_NAME) lib/$(SLF4J_API_NAME) lib/$(SLF4J_NOP_NAME)', '')"
	$(JAR) cfm "$(JAR_FILE)" "target/MANIFEST.MF" -C "$(OUT_DIR)" .
	@echo Built $(JAR_FILE) with its SQLite/jOOQ runtime libraries in target\lib

run: compile
	$(JAVA) -cp "$(OUT_DIR);$(DEPS_CP)" $(MAIN)

run-cli: compile
	$(JAVA) -cp "$(OUT_DIR);$(DEPS_CP)" $(MAIN) --cli

tools: compile
	@if not exist "$(TOOLS_OUT)" mkdir "$(TOOLS_OUT)"
	$(JAVAC) -d "$(TOOLS_OUT)" -cp "$(OUT_DIR);$(DEPS_CP)" -encoding UTF-8 "$(TOOLS_SRC)"
	@echo Built screenshot driver to $(TOOLS_OUT)

screenshots: reset tools
	$(JAVA) -cp "$(OUT_DIR);$(TOOLS_OUT);$(DEPS_CP)" smartfm.ui.gui.ScreenshotDriver
	@echo Screenshots saved to screenshots/

clean:
	@if exist "target" rmdir /s /q "target"

reset: clean
	@if exist "data\smartfm.db" del /q "data\smartfm.db"
	@if exist "data\smartfm.db-wal" del /q "data\smartfm.db-wal"
	@if exist "data\smartfm.db-shm" del /q "data\smartfm.db-shm"

else

SOURCES = $(shell find $(SRC_DIR) -name "*.java")
DEPS_CP = $(SQLITE_JAR):$(JOOQ_JAR):$(R2DBC_SPI_JAR):$(REACTIVE_STREAMS_JAR):$(JAXB_API_JAR):$(ACTIVATION_API_JAR):$(SLF4J_API_JAR):$(SLF4J_NOP_JAR)

compile: $(SOURCES)
	@test -f "$(SQLITE_JAR)" && test -f "$(JOOQ_JAR)" && test -f "$(R2DBC_SPI_JAR)" && test -f "$(REACTIVE_STREAMS_JAR)" && test -f "$(JAXB_API_JAR)" && test -f "$(ACTIVATION_API_JAR)" && test -f "$(SLF4J_API_JAR)" && test -f "$(SLF4J_NOP_JAR)" || (echo "Missing pinned SQLite/jOOQ runtime dependency under lib/" && exit 1)
	@mkdir -p "$(OUT_DIR)"
	$(JAVAC) -cp "$(DEPS_CP)" -d "$(OUT_DIR)" -encoding UTF-8 -Xlint:all $(SOURCES)
	@echo "Compiled $$(echo $(SOURCES) | wc -w) source files to $(OUT_DIR) with SQLite/jOOQ"

jar: compile
	@mkdir -p "$(TARGET_LIB)"
	@cp "$(SQLITE_JAR)" "$(TARGET_LIB)/$(SQLITE_NAME)"
	@cp "$(JOOQ_JAR)" "$(TARGET_LIB)/$(JOOQ_NAME)"
	@cp "$(R2DBC_SPI_JAR)" "$(TARGET_LIB)/$(R2DBC_SPI_NAME)"
	@cp "$(REACTIVE_STREAMS_JAR)" "$(TARGET_LIB)/$(REACTIVE_STREAMS_NAME)"
	@cp "$(JAXB_API_JAR)" "$(TARGET_LIB)/$(JAXB_API_NAME)"
	@cp "$(ACTIVATION_API_JAR)" "$(TARGET_LIB)/$(ACTIVATION_API_NAME)"
	@cp "$(SLF4J_API_JAR)" "$(TARGET_LIB)/$(SLF4J_API_NAME)"
	@cp "$(SLF4J_NOP_JAR)" "$(TARGET_LIB)/$(SLF4J_NOP_NAME)"
	@printf 'Manifest-Version: 1.0\nMain-Class: $(MAIN)\nClass-Path: lib/$(SQLITE_NAME) lib/$(JOOQ_NAME) lib/$(R2DBC_SPI_NAME) lib/$(REACTIVE_STREAMS_NAME) lib/$(JAXB_API_NAME) lib/$(ACTIVATION_API_NAME) lib/$(SLF4J_API_NAME) lib/$(SLF4J_NOP_NAME)\n\n' > target/MANIFEST.MF
	$(JAR) cfm "$(JAR_FILE)" target/MANIFEST.MF -C "$(OUT_DIR)" .
	@echo "Built $(JAR_FILE) with its SQLite/jOOQ runtime libraries in $(TARGET_LIB)"

run: compile
	$(JAVA) -cp "$(OUT_DIR):$(DEPS_CP)" $(MAIN)

run-cli: compile
	$(JAVA) -cp "$(OUT_DIR):$(DEPS_CP)" $(MAIN) --cli

tools: compile $(TOOLS_SRC)
	@mkdir -p "$(TOOLS_OUT)"
	$(JAVAC) -d "$(TOOLS_OUT)" -cp "$(OUT_DIR):$(DEPS_CP)" -encoding UTF-8 "$(TOOLS_SRC)"
	@echo "Built screenshot driver to $(TOOLS_OUT)"

screenshots: reset tools
	$(JAVA) -cp "$(OUT_DIR):$(TOOLS_OUT):$(DEPS_CP)" smartfm.ui.gui.ScreenshotDriver
	@echo "Screenshots saved to screenshots/"

clean:
	rm -rf "$(OUT_DIR)" "$(JAR_FILE)" "$(TOOLS_OUT)" "$(TARGET_LIB)" target/MANIFEST.MF

reset: clean
	rm -f data/smartfm.db data/smartfm.db-wal data/smartfm.db-shm

endif
