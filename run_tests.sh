#!/bin/bash

# Directories to store intermediate files
TEST_DIR="./tests/"
INPUT_FILE="${TEST_DIR}test_input.txt"
MAIN_OUTPUT="${TEST_DIR}main_output.txt"
ACCEPT_OUTPUT="${TEST_DIR}accept_output.txt"

# Ensure the test directory exists
mkdir -p $TEST_DIR

# Get file extensions for main and accept
MAIN_EXT="${1##*.}"   # Extract file extension for main (e.g., cpp or py)
ACCEPT_EXT="${2##*.}" # Extract file extension for accept (e.g., cpp or py)
GEN_EXT="${3##*.}"    # Test generator extension (e.g., cpp or py)

# Function to compile and check C++ files
compile_cpp() {
    local file=$1
    local output_exec=$2

    # Compile C++ file
    g++ -o $output_exec $file
    if [ $? -ne 0 ]; then
        echo "Compilation of $file failed!"
        exit 1
    fi
}

# Compile or set executables and runners for main.cpp and accept.cpp
MAIN_EXEC=""
ACCEPT_EXEC=""
TEST_GEN_EXEC=""

# If tests involve cpp files, compile them. Otherwise, set up for Python execution.
if [ "$MAIN_EXT" == "cpp" ]; then
    compile_cpp "$1" "main_exec"
    MAIN_EXEC="./main_exec"  # C++ executable
elif [ "$MAIN_EXT" == "py" ]; then
    MAIN_EXEC="python3 $1"  # Python call
else
    echo "Unsupported extension for main file!"
    exit 1
fi

if [ "$ACCEPT_EXT" == "cpp" ]; then
    compile_cpp "$2" "accept_exec"
    ACCEPT_EXEC="./accept_exec"  # C++ executable
elif [ "$ACCEPT_EXT" == "py" ]; then
    ACCEPT_EXEC="python3 $2"  # Python call
else
    echo "Unsupported extension for accept file!"
    exit 1
fi

# Compile the test generator (either C++ or Python)
if [ "$GEN_EXT" == "cpp" ]; then
    compile_cpp "$3" "test_gen_exec"
    TEST_GEN_EXEC="./test_gen_exec"
elif [ "$GEN_EXT" == "py" ]; then
    TEST_GEN_EXEC="python3 $3"  # Python test generator
else
    echo "Unsupported extension for test generator!"
    exit 1
fi

echo "Starting test checks..."

# Initialize test case counter
test_count=0

while true; do
    # Increment test case counter
    ((test_count++))

    echo "Generating test case #$test_count..."
    
    # Generate input using the test_generator
    $TEST_GEN_EXEC > $INPUT_FILE

    if [ $? -ne 0 ]; then
        echo "Error running test_generator"
        exit 1
    fi

    # Run main with generated input
    if ! $MAIN_EXEC < $INPUT_FILE > $MAIN_OUTPUT; then
        echo "Error running main"
        exit 1
    fi

    # Run accept with generated input
    if ! $ACCEPT_EXEC < $INPUT_FILE > $ACCEPT_OUTPUT; then
        echo "Error running accept"
        exit 1
    fi

    # Compare outputs
    DIFF=$(diff $MAIN_OUTPUT $ACCEPT_OUTPUT)

    if [ "$DIFF" != "" ]; then
        echo "Outputs differ on test case #$test_count. Stopping test."
        echo "Input causing the difference:"
        cat $INPUT_FILE
        echo
        echo "Main output:"
        cat $MAIN_OUTPUT
        echo
        echo "Accept output:"
        cat $ACCEPT_OUTPUT
        exit 1
    fi

    echo "Test case #$test_count passed. Continuing to next test..."
done
