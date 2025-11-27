#!/usr/bin/env bash

# End to end (e2e) tests
# Run this via make e2e-tests

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

# Exit on undefined variables and pipe failures
set -uo pipefail

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

# Get the directory of the project root
ROOT_DIR="$(dirname "$(dirname "$(readlink -f "${0}")")")"

# Get the path to the binary
BINARY="${ROOT_DIR}/mem-sim"

# Run a test
# Parameters:
# - $1: The strategy
# - $2: The max allocatable frame number
# - $3: The case
# - $4: The mode
# Globals:
# - BINARY: The path to the binary
# - ROOT_DIR: The directory of the project root
function run_test {
	# Generate the input and output file names
	local INPUT_SIMULATION_NAME="${ROOT_DIR}/tests/input/simulation/${3}"

  local OUTPUT_BASE_NAME="${ROOT_DIR}/tests/output/${1}/max_frame_${2}/${3}_${4}"
	local OUTPUT_EXEPECTED_NAME="${OUTPUT_BASE_NAME}.expected"
	local OUTPUT_ACTUAL_NAME="${OUTPUT_BASE_NAME}.actual"
	local OUTPUT_DIFF_NAME="${OUTPUT_BASE_NAME}.diff"

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
	rm -f ${OUTPUT_BASE_NAME}.{actual,diff}

	# Run the command
	echo -e "${DEBUG} Running: ${COMMAND} > ${OUTPUT_ACTUAL_NAME}"
	${COMMAND} > "${OUTPUT_ACTUAL_NAME}"
	if [ "${?}" -ne 0 ]; then
		echo -e "${ERROR} Failed to run the command ${COMMAND}!"
		return 1
	fi

	# Compare the output
	local DIFF=$(diff --label "Expected output" --label "Actual output" --unified --ignore-space-change --ignore-blank-lines "${OUTPUT_EXEPECTED_NAME}" "${OUTPUT_ACTUAL_NAME}")

	if [ "${DIFF}" != "" ]; then
		echo "${DIFF}" > "${OUTPUT_DIFF_NAME}"
    echo -e "${ERROR} Test failed! (Strategy: ${1}, max allocatable frame number: ${2}, case: ${3}, mode: ${4}, diff: ${OUTPUT_DIFF_NAME})"
		return 1
	fi

  echo -e "${SUCCESS} Test passed! (Strategy: ${1}, max allocatable frame number: ${2}, case: ${3}, mode: ${4}, output: ${OUTPUT_ACTUAL_NAME})"

	return 0
}

# Check if invoked by Make
if [ "${MAKELEVEL:-0}" -ne 1 ]; then
  echo -e "${ERROR} This script should be run via make e2e-tests!"
  exit 1
fi

# Run end to end tests
ALL_TESTS_PASSED=true
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

# Print the result
if [ "${ALL_TESTS_PASSED}" == false ]; then
	echo -e "${ERROR} Some tests failed!"
	exit 1
else
	echo -e "${SUCCESS} All configured end to end tests passed!"
	exit 0
fi
