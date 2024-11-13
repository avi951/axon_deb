#!/bin/bash

# Set the eMMC device (for example, a partition like /dev/mmcblk0p1)
EMMC_DEVICE="/dev/mmcblk0"
TEST_SIZE="500M"  # Size of the test (500 MB)
TEST_BLOCKS="512" # Block size (512 bytes)
TEMP_FILE="/tmp/emmc_test_file"  # Temporary file for the test

# Function to perform a write and read test on the raw eMMC device
run_emmc_test() {
    echo "Starting eMMC write test with $TEST_SIZE of data on $EMMC_DEVICE..."

    # Write 500 MB of random data to the eMMC device
    dd if=/dev/urandom of="$EMMC_DEVICE" bs=$TEST_BLOCKS count=1024 oflag=direct status=progress &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Write test to $EMMC_DEVICE failed."
        return 1
    fi

    echo "Write test completed successfully. Starting read test..."

    # Read back the 500 MB of data from the eMMC device
    dd if="$EMMC_DEVICE" of="$TEMP_FILE" bs=$TEST_BLOCKS count=1024 iflag=direct status=progress &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Read test from $EMMC_DEVICE failed."
        return 1
    fi

    echo "Read test completed successfully."
    rm -f "$TEMP_FILE"
    return 0
}

# Ensure the eMMC device exists
if [[ -b "$EMMC_DEVICE" ]]; then
    run_emmc_test
    if [ $? -eq 0 ]; then
        echo "eMMC regression test PASSED."
        exit 0
    else
        echo "eMMC regression test FAILED."
        exit 1
    fi
else
    echo "Error: eMMC device $EMMC_DEVICE not found."
    exit 1
fi

