# Target unit test binary.
TARGET := frame_test

# C++ compiler.
CXX_COMPILER := g++

# Source files. The frame implementation, plus the unit tests that check it.
SRC_FILES := source/comm/frame.cpp \
             test/frame_test.cpp \
             test/main.cpp \

# C++ flags.
# Todo: Add -DL01 when the frame implementation is finished.
CXX_FLAGS := -Wall -Werror -std=c++17 -Iinclude

# Test framework (git submodule).
TEST_LIB_DIR := ../../../../libs/test
TEST_LIB := $(TEST_LIB_DIR)/libqacademy_test.a
TEST_FLAGS := -I$(TEST_LIB_DIR)/include -L$(TEST_LIB_DIR) -lqacademy_test

# Build and run the unit tests as default.
default: build run

# Build the test framework library.
$(TEST_LIB):
	@$(MAKE) --no-print-directory -C $(TEST_LIB_DIR) lib

# Build the unit tests.
build: $(TEST_LIB)
	@$(CXX_COMPILER) $(SRC_FILES) -o $(TARGET) $(CXX_FLAGS) $(TEST_FLAGS)

# Run the unit tests.
run:
	@./$(TARGET)

# Build and run the unit tests.
test: build run

# Clean the application.
clean:
	@rm -f $(TARGET)

.PHONY: default build run test clean
