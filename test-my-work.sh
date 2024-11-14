#!/bin/bash

# Test your work using the provided test cases

################################################################################
#                                   Settings                                   #
################################################################################

# Strategies to test (One or more of: "fifo" "lru")
STRAGIES=("fifo" "lru")

# Maximum allocatable frame numbers (One or more of: "5" "10")
MAX_FRAME_NUMBERS=("5" "10")

# Test cases to run (One or more of: "1" "2" "3")
CASES=("1" "2" "3")

# Mode to test (One or more of: "verbose")
MODES=("verbose")

################################################################################
#                                  Internals                                   #
################################################################################

# ANSI color codes
GRAY="\033[0;37m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# Logging prefixes
DEBUG="${GRAY}[DEBUG]${RESET}"
SUCCESS="${GREEN}[SUCCESS]${RESET}"
WARNING="${YELLOW}[WARNING]${RESET}"
ERROR="${RED}[ERROR]${RESET}"

# Get the directory of the script
SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"

# Get the path to the binary
BINARY="${SCRIPT_DIR}/mem-sim"

# Run a test
# Parameters:
# - $1: The strategy
# - $2: The max allocatable frame number
# - $3: The case
# - $4: The mode
# Globals:
# - BINARY: The path to the binary
# - SCRIPT_DIR: The directory of the script
function run_test {
	# Generate the input and output file names
	local INPUT_SIMULATION_NAME="${SCRIPT_DIR}/tests/input/simulation/${3}"

  local OUTPUT_BASE_NAME="${SCRIPT_DIR}/tests/output/${1}/max_frame_${2}/${3}_${4}"
	local OUTPUT_EXEPECTED_NAME="${OUTPUT_BASE_NAME}.expected"
	local OUTPUT_ACTUAL_NAME="${OUTPUT_BASE_NAME}.actual"
	local DIFF_NAME="${OUTPUT_BASE_NAME}.diff"

	local COMMAND="${BINARY} --${4} --strategy ${1} --max-frames ${2} ${INPUT_SIMULATION_NAME}"

	# Ensure the input simulation file exists
	if [ ! -f "${INPUT_SIMULATION_NAME}" ]; then
		echo -e "${ERROR} No input simulation file ${INPUT_SIMULATION_NAME} found!"
		return 1
	fi

	# Ensure the expected output file exists
	if [ ! -f "${OUTPUT_EXEPECTED_NAME}" ]; then
		echo -e "${ERROR} No expected output file ${OUTPUT_EXEPECTED_NAME} found!"
		return 1
	fi

	# Delete old output files
	rm -f "${OUTPUT_ACTUAL_NAME}" "${DIFF_NAME}"

	# Run the command
	echo -e "${DEBUG} Running: ${COMMAND} > ${OUTPUT_ACTUAL_NAME}"
	${COMMAND} > "${OUTPUT_ACTUAL_NAME}"
	if [ "${?}" -ne 0 ]; then
		echo -e "${ERROR} Failed to run the command ${COMMAND}!"
		return 1
	fi

	# Compare the output
	DIFF=$(diff --ignore-space-change --ignore-blank-lines "${OUTPUT_ACTUAL_NAME}" "${OUTPUT_EXEPECTED_NAME}")

	if [ "${DIFF}" == "" ]; then
		echo -e "${SUCCESS} Test passed! (Strategy: ${1}, max allocatable frame number: ${2}, case: ${3}, mode: ${4}, output: ${OUTPUT_ACTUAL_NAME})"
	else
		echo "${DIFF}" > "${DIFF_NAME}"
        echo -e "${ERROR} Test failed! (Strategy: ${1}, max allocatable frame number: ${2}, case: ${3}, mode: ${4}, diff: ${DIFF_NAME})"
		return 1
	fi

	return 0
}

# Build everything
if [ ! -f "${BINARY}" ]; then
	echo -e "${DEBUG} Building everything..."
  make mem-sim bin/all_tests
fi

ALL_TESTS_PASSED=true

# Run unit tests
echo -e "${DEBUG} Running unit tests..."
make test

if [ "${?}" -ne 0 ]; then
    echo -e "${ERROR} Some unit tests failed, skipping end to end tests!"
    ALL_TESTS_PASSED=false
else
    echo -e "${SUCCESS} All unit tests passed!"

    # Run end to end tests
    for STRATEGY in "${STRAGIES[@]}"; do
        for MAX_FRAME_NUMBER in "${MAX_FRAME_NUMBERS[@]}"; do
            for CASE in "${CASES[@]}"; do
                for MODE in "${MODES[@]}"; do
                    run_test "${STRATEGY}" "${MAX_FRAME_NUMBER}" "${CASE}" "${MODE}"

                    if [ "${?}" -ne 0 ]; then
                        ALL_TESTS_PASSED=false
                    fi
                done
            done
        done
    done
fi

# Print the result
if [ "${ALL_TESTS_PASSED}" == false ]; then
	echo -e "${ERROR} Some tests failed!"
	exit 1
else
	echo -e "${SUCCESS} All configured tests passed!"
	exit 0
fi
