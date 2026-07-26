# SmartFM - Assignment 3 Makefile
# Requires a Java 26+ JDK and the pinned SQLite JDBC / SLF4J runtime JARs under lib/.
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
SLF4J_API_JAR  = lib/slf4j-api-1.7.36.jar
SLF4J_NOP_JAR  = lib/slf4j-nop-1.7.36.jar
SQLITE_NAME    = sqlite-jdbc-3.46.1.0.jar
SLF4J_API_NAME = slf4j-api-1.7.36.jar
SLF4J_NOP_NAME = slf4j-nop-1.7.36.jar

.PHONY: all compile jar exe run tools screenshots clean reset

all: compile

ifeq ($(OS),Windows_NT)

SHELL = cmd.exe

DEPS_CP = $(SQLITE_JAR);$(SLF4J_API_JAR);$(SLF4J_NOP_JAR)

compile:
	@if not exist "$(SQLITE_JAR)" (echo Missing pinned dependency: $(SQLITE_JAR) & exit /b 1)
	@if not exist "$(SLF4J_API_JAR)" (echo Missing pinned dependency: $(SLF4J_API_JAR) & exit /b 1)
	@if not exist "$(SLF4J_NOP_JAR)" (echo Missing pinned dependency: $(SLF4J_NOP_JAR) & exit /b 1)
	@if not exist "$(OUT_DIR)" mkdir "$(OUT_DIR)"
	@powershell -NoProfile -Command "$$sources = Get-ChildItem -Recurse -Filter *.java '$(SRC_DIR)' | ForEach-Object { $$_.FullName }; & $(JAVAC) -cp '$(DEPS_CP)' -d '$(OUT_DIR)' -encoding UTF-8 -Xlint:all $$sources; if ($$LASTEXITCODE -ne 0) { exit $$LASTEXITCODE }; Write-Output ('Compiled ' + $$sources.Count + ' source files to $(OUT_DIR) with SQLite/JDBC')"

jar: compile
	@powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'target/lib' | Out-Null; Copy-Item -Force '$(SQLITE_JAR)', '$(SLF4J_API_JAR)', '$(SLF4J_NOP_JAR)' -Destination 'target/lib'; Set-Content -Encoding Ascii -Path 'target/MANIFEST.MF' -Value @('Manifest-Version: 1.0', 'Main-Class: $(MAIN)', 'Class-Path: lib/$(SQLITE_NAME) lib/$(SLF4J_API_NAME) lib/$(SLF4J_NOP_NAME)', '')"
	$(JAR) cfm "$(JAR_FILE)" "target/MANIFEST.MF" -C "$(OUT_DIR)" .
	@echo Built $(JAR_FILE) with its SQLite/JDBC runtime libraries in target\lib

exe: jar
	@if exist "target\dist" rmdir /s /q "target\dist"
	jpackage --type app-image --name SmartFM --input target --main-jar smartfm.jar --main-class $(MAIN) --java-options "--enable-native-access=ALL-UNNAMED" --dest target/dist
	@echo Built Windows native executable to target\dist\SmartFM\SmartFM.exe

run: compile
	$(JAVA) -cp "$(OUT_DIR);$(DEPS_CP)" $(MAIN)

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
DEPS_CP = $(SQLITE_JAR):$(SLF4J_API_JAR):$(SLF4J_NOP_JAR)

compile: $(SOURCES)
	@test -f "$(SQLITE_JAR)" && test -f "$(SLF4J_API_JAR)" && test -f "$(SLF4J_NOP_JAR)" || (echo "Missing pinned SQLite/JDBC runtime dependency under lib/" && exit 1)
	@mkdir -p "$(OUT_DIR)"
	$(JAVAC) -cp "$(DEPS_CP)" -d "$(OUT_DIR)" -encoding UTF-8 -Xlint:all $(SOURCES)
	@echo "Compiled $$(echo $(SOURCES) | wc -w) source files to $(OUT_DIR) with SQLite/JDBC"

jar: compile
	@mkdir -p "$(TARGET_LIB)"
	@cp "$(SQLITE_JAR)" "$(TARGET_LIB)/$(SQLITE_NAME)"
	@cp "$(SLF4J_API_JAR)" "$(TARGET_LIB)/$(SLF4J_API_NAME)"
	@cp "$(SLF4J_NOP_JAR)" "$(TARGET_LIB)/$(SLF4J_NOP_NAME)"
	@printf 'Manifest-Version: 1.0\nMain-Class: $(MAIN)\nClass-Path: lib/$(SQLITE_NAME) lib/$(SLF4J_API_NAME) lib/$(SLF4J_NOP_NAME)\n\n' > target/MANIFEST.MF
	$(JAR) cfm "$(JAR_FILE)" target/MANIFEST.MF -C "$(OUT_DIR)" .
	@echo "Built $(JAR_FILE) with its SQLite/JDBC runtime libraries in $(TARGET_LIB)"

exe: jar
	@rm -rf target/dist
	jpackage --type app-image --name SmartFM --input target --main-jar smartfm.jar --main-class $(MAIN) --java-options "--enable-native-access=ALL-UNNAMED" --dest target/dist
	@echo "Built native executable app-image to target/dist/SmartFM"

run: compile
	$(JAVA) -cp "$(OUT_DIR):$(DEPS_CP)" $(MAIN)

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
