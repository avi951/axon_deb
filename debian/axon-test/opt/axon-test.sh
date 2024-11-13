#!/bin/sh

# This script contains functions to perform various tasks

config_file="/boot/extlinux/extlinux.conf"
# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
GREEN_BACK='\033[30;42m'
RED_BACK='\033[30;41m'

# Define symbols for success and failure
SUCCESS="${GREEN}✓${NC}"
FAILURE="${RED}✗${NC}"

# Initialize results variable
results="Name\t\tStatus\n"
results="${results}----------------------------------------\n"
start_time_file="/home/vicharak/rtc_time.txt"

# Function to ask user for next action
ask_next_action(){
	while true; do
		echo "${CYAN}\n\n${GREEN}Do you want to rerun this test?${NC} (${RED}yes/no${NC}): "
		read choice
		case $choice in
			[Yy][Ee][Ss] | [Yy]) return 0 ;;
			[Nn][Oo] | [Nn]) return 1 ;;
		esac
	done
}

# Function to handle each test
results_file="results.log"


handle_test() {
    local test_command=$1
    local test_name=$2
    local test_numebr=$3

    while true; do
        # Execute the test command
        $test_command
        status=$?

        # Check if the test passed or failed based on the status code
        if [ $status -eq 0 ]; then
            echo -e "${GREEN_BACK}Test Passed${NC}"
            results="${results} ${test_number} $(printf "%-25s %s"  "${test_name}" "${SUCCESS}")\n"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ${test_name}: ${SUCCESS} Passed" >> "$results_file"
            break
        else
            echo -e "${RED_BACK}Test Failed${NC}"
            results="${results} ${test_number} $(printf "%-25s %s" "${test_name}" "${FAILURE}")\n"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ${test_number} ${test_name}: ${FAILURE} Failed" >> "$results_file"
            break  # Exit the loop, no reruns for now
        fi
    done

    # Optionally, you could return the results or print them at the end
    # echo -e "$results"
}



# Function to update extlinux.conf
update_extlinux() {
	local ovdtbo=$1 dtbo=$2 device=$3 function=$4
	if [ -f "$ovdtbo" ]; then
		sudo mv -v $ovdtbo "/boot$dtbo"
		if [ "fdtoverlays" = $(grep -o "fdtoverlays" "$config_file") ]; then
			if ! [ "$device" = $(grep -o "$device" "$config_file") ]; then
				# Append the overlay to the fdtoverlays line using a different delimiter (|)
				sudo sed -i "/fdtoverlays/ s|$| $dtbo|" "$config_file"
				echo "fdtoverlays not exist"
				# echo "$function" >>./remainTest.sh
				return 0
			fi
		else
			# Add "fdtoverlays" after "fdt" line
			sudo sed -i "/fdt/ a\ \tfdtoverlays $dtbo" "$config_file"
			echo "append line "
			return 0
		fi
	else
		# if grep -q "$function" "./remainTest.sh"; then
		# 	sed -i "s/$function//" ./remainTest.sh
		# fi
	    #	if dmesg | grep -i $device; then
	    #		echo "The $device check Pass"
	    #	fi
		return 1
	fi
}

set_theme(){
	echo "================================"
	echo "${YELLOW}\tSet Vicharak Theme${NC}"
	gsettings set org.mate.background picture-filename '/usr/share/images/desktop-base/vicharak-wallpaper.jpg'
	gsettings set org.mate.interface gtk-theme 'Yaru-purple-dark'
	gsettings set org.mate.interface icon-theme 'Yaru-purple-dark'
}

# Function to test HDMI-0
HDMI_0() {
	echo "================================"
	echo "${YELLOW}\tHDMI-0${NC}"
	#echo "${YELLOW}HDMI-0 ~${NC}"
	
	# Check HDMI-0
	hdmi_status_1="$(cat /sys/class/drm/card0-HDMI-A-1/status)"
	if [ "$hdmi_status_1" = "connected" ]; then
	    echo "HDMI-0 is ${GREEN}Connected :)${NC}"
	    return 0
	else
	    echo "HDMI-0 is ${RED}not Connected :(${NC}"
	    return 1
	fi
}

# Function to test HDMI-1
HDMI_1() {
	echo "================================"
	echo "${YELLOW}\tHDMI-1${NC}"
	# Chek HDMI-1
	hdmi_status_2="$(cat /sys/class/drm/card0-HDMI-A-2/status)"
	if [ "$hdmi_status_2" = "connected" ]; then
		echo "HDMI-1 is ${GREEN}Connected :)${NC}"
		return 0
	else
		echo "HDMI-1 is ${RED}not Connected :(${NC}"
		return 1
	fi
}

# Function to test TYPE_C_DP0
TYPE_C_DP0() {
	echo "================================"
	echo "${YELLOW}\tTYPE-C DP0${NC}"
	sleep 5	
	tyepC_DP1_status="$(cat /sys/class/drm/card0-DP-1/status)"
	if [ "$tyepC_DP1_status" = "connected" ]; then
	    echo "TYPE-C DP0 is ${GREEN}Connected :)${NC}"
	    return 0
	else
	    echo "TYPE-C DP0 is ${RED}not Connected :(${NC}"
	    return 1
	fi
}

# Function to test TYPE_C_DP1
TYPE_C_DP1() {
	echo "${YELLOW}\tTYPE-C DP1 ~ ${NC}"
	sleep 5
	typeC_DP2_status="$(cat /sys/class/drm/card0-DP-2/status)"
	if [ "$typeC_DP2_status" = "connected" ]; then
		echo "TYPE-C DP1 ${GREEN}Connected :)${NC}"
		return 0
	else
		echo "TYPE-C DP1 ${RED}not Connected :(${NC}"
		return 1
	fi
}

# Function to connect to Wi-Fi
wifi() {
	SSID="Vicharak_Assembly"
	PASSWORD="passpass100"
	echo "================================"
	echo "${YELLOW}\tWi-Fi${NC}\n"
	sudo nmcli dev wifi connect "$SSID" password "$PASSWORD"
	if [ $SSID = $(nmcli dev status | awk '$1 == "wlan0" {print $4}') ]; then
		if [ "connected" = $(nmcli dev status | awk '$1 == "wlan0" {print $3}') ]; then
			ip=$(ip addr show wlan0 | grep -w 'inet' | awk '{print $2}')
			echo "$SSID ${GREEN}connected ;)${CYAN}$ip${NC}"
			return 0
		else
			echo "${RED}Can't connect to the network $SSID :(${NC}"
			return 1
		fi
	else
		return 1
	fi
}

#Function to check Bluetooth
bluetooth() {
    echo "================================"
    echo "${YELLOW}\tBluetooth\n\n${NC}"
    echo "${YELLOW}Checking Bluetooth service status...${NC}"

    service_status=$(systemctl is-active vicharak-bluetooth)
    if [ "$service_status" = "active" ]; then
        echo "${GREEN}Vicharak Bluetooth service is active.${NC}"
	sudo systemctl restart vicharak-bluetooth
	hciconfig -a
	hciconfig -a
    else
        echo "${RED}Vicharak Bluetooth service is not active.${NC}"
    fi

    # Check for "UP RUNNING / DOWN" status or specific error message
    BT_STATUS_DOWN="$(hciconfig hci0 | grep -o "DOWN")"

    # Run the hciconfig -a command and capture its output
    output=$(hciconfig -a 2>&1)

    # Check if the output contains the specific error message
    if [ "$BT_STATUS_DOWN" = "DOWN" ];	then
        echo "${RED}Bluetooth is down${NC}"
        sleep 1
        sudo systemctl restart vicharak-bluetooth.service
	sleep 3
        hciconfig -a
	return 1
    elif echo "$output" | grep -q "Can't read local name on hci0: Connection timed out (110)"; then
    	echo "Error detected: Can't read local name on hci0: Connection timed out (110)"
        echo "Bluetooth check ${RED}Failed ;)${NC}\n"
	echo "Let me Start Bluetooth again"
        sleep 2
        sudo systemctl restart vicharak-bluetooth.service
	sleep 3
        hciconfig -a
        return 1
    else
	hciconfig hci0
	#sudo bluetoothctl
	#discoverable on
	# Start the Bluetooth scan in the background
	bluetoothctl scan on &
	
	# Capture the process ID of bluetoothctl
	BLUETOOTH_PID=$!
	
	# Wait for 5 seconds
	sleep 3
	
	# Stop the Bluetooth scan
	bluetoothctl scan off
	
	# Optionally, kill the background bluetoothctl process (just in case)
	kill $BLUETOOTH_PID

	echo "Bluetooth is UP RUNNING and Vicharak Bluetooth Controller:"
        echo -e "Bluetooth check ${GREEN}Success :(${NC}"
        return 0
    fi
}

# Function to test Ethernet
eth() {
    echo "================================"
    echo -e "${YELLOW}\tEthernet\n${NC}"

    # Define the interfaces you want to check
    INTERFACE1="eth0"
    INTERFACE2="eth2"

    # Check if either eth0 or eth2 has an IP address
    if sudo ifconfig $INTERFACE1 | grep "inet " >/dev/null; then
        echo -e "Ethernet interface $INTERFACE1 is ${GREEN}connected ;)\nIP address: ${CYAN}$(sudo ifconfig $INTERFACE1 | awk '/inet /{print $2}')\n${NC}"
        return 0
    elif sudo ifconfig $INTERFACE2 | grep "inet " >/dev/null; then
        echo -e "Ethernet interface $INTERFACE2 is ${GREEN}connected ;)\nIP address: ${CYAN}$(sudo ifconfig $INTERFACE2 | awk '/inet /{print $2}')\n${NC}"
        return 0
    else
        echo -e "Neither $INTERFACE1 nor $INTERFACE2 is connected ${RED}Fail :(${NC}"
        return 1
    fi
}

# Function to test SD card
sdCard() {
  	echo "================================"
	echo "${YELLOW}\tSD-card \n${NC}"
	
    sd_blk=$(lsblk | grep mmcblk1)
	if [ ! "$sd_blk" ]; then
		echo "SD-card not connected ${RED}Fail :(${NC}"
		return 1
	fi

	sd_name=$(sudo cat /sys/bus/mmc/devices/mmc0:*/name)
	sd_size=$(sudo /sbin/fdisk -l /dev/mmcblk1 | grep Disk | head -n 1 | awk '{print $3}')
	sd_size_MB=$(awk 'BEGIN{printf "%d\n",('$sd_size'/1024/1024)}')

	if [ "$para" = "name" ]; then
		echo $sd_name
	elif [ "$para" = "size" ]; then
		echo $sd_size
	else
		echo "${BLUE}SD-name:-${GREEN}$sd_name,\n${BLUE}SD-size:-${GREEN}$sd_size GiB${NC}"
		return 0
	fi
}

# Function to test eMMC
emmc(){
   	echo "================================"
	echo "${YELLOW}\tEMMC\n${NC}"
	
    emmc_name=$(sudo cat /sys/bus/mmc/devices/mmc0:0001/name)
	emmc_life_time=$(sudo cat /sys/bus/mmc/devices/mmc0:0001/life_time)
	emmc_pre_eol_info=$(sudo cat /sys/bus/mmc/devices/mmc0:0001/pre_eol_info)
	emmc_size=$(sudo /sbin/fdisk -l /dev/mmcblk0 | grep Disk | head -n 1 | awk '{ print $3 $4;}')
	if [ "$para" = "name" ]; then
		echo $emmc_name
	elif [ "$para" = "life_time" ]; then
		echo $emmc_life_time
	elif [ "$para" = "pre_eol_info" ]; then
		echo $emmc_pre_eol_info
	elif [ "$para" = "size" ]; then
		echo $emmc_size
	elif [ "$para" = "erase" ]; then
		sudo /usr/sbin/blkdiscard /dev/mmcblk0
	else
		echo "${BLUE}EMMC-name:-${NC}${GREEN}$emmc_name${NC},\n${BLUE}EMMC-life_time:-${NC}${GREEN}$emmc_life_time${NC},\n${BLUE}EMMC-pre_eol_info:-${NC}${GREEN}$emmc_pre_eol_info${NC}\n${BLUE}EMMC-size:-${NC}${GREEN}$emmc_size${NC}"

# Set the eMMC device (adjust as necessary)
#	EMMC_DEVICE="/dev/mmcblk0"
#	TEST_FILE="/tmp/emmc_test_file"
#	
#	# Set the number of iterations for regression test
#	NUM_TESTS=5
#	BLOCK_SIZE="1G"
#	COUNT="1"
#	
#	# Function to test write speed
#	test_write_speed() {
#	    echo "Testing write speed..."
#	    dd if=/dev/zero of=$TEST_FILE bs=$BLOCK_SIZE count=$COUNT conv=fsync oflag=direct 2>&1 | grep 'copied'
#	    return $?
#    	}
#	
#	# Function to test read speed
#	test_read_speed() {
#	    echo "Testing read speed..."
#	    dd if=$TEST_FILE of=/dev/null bs=$BLOCK_SIZE count=$COUNT iflag=direct 2>&1 | grep 'copied'
#	    return $?
#    	}
#	
#	# Loop through the tests
#	i=1
#	while [ "$i" -le "$NUM_TESTS" ]
#	do
#	    echo "Running test iteration $i..."
#	        test_write_speed
#    		WRITE_STATUS=$?  # Capture the exit status of the write test
#
#    		test_read_speed
#    		READ_STATUS=$?  # Capture the exit status of the read test
#
#    		# Check if any of the tests failed
#    		if [ "$WRITE_STATUS" -ne 0 ] || [ "$READ_STATUS" -ne 0 ]; then
#    		    echo "Test iteration $i failed."
#    		    return 1  # Exit with status 1 if any test fails
#    		fi
#	    echo "-----------------------------"
#	    i=$((i + 1))
#	done
#	
#	# Cleanup
#	rm -f $TEST_FILE
	
		#iozone -e -I -a -s 100M -r 4k -r 16k -r 512k -r 1024k -r 16384k -i 0 -i 1 -i 2
		#if [ "$?" = 0 ]; then
		#	echo "Test completed."
			return 0
		#else
		#	return 1
		#fi
		
	fi
}

# Function to test NVME - After attaching NVME, Axon should be rebooted first
nvme() {
    	echo "================================"
	echo "${YELLOW}\tNVME \n${NC}"

	ssd_blk=$(lsblk | grep nvme0n1)

	if [ ! "$ssd_blk" ]; then
		echo "NVME not connected ${RED}Failed :(${NC}"
		return 1
	fi

	ssd_name=$(sudo cat /sys/class/nvme/nvme0/model)
	ssd_size=$(sudo cat /sys/class/nvme/nvme0/nvme0n1/size)
	ssd_size_MB=$(awk 'BEGIN{printf "%d GB\n",('$ssd_size'*512/1073741824)}')

	echo "${BLUE}NVME-name:-${GREEN}$ssd_name,\n${BLUE}NVME-size:-${GREEN}$ssd_size_MB${NC}"
	return 0
}


# Function to check disk speed using hdparm
check_disk_speed() {
	device_name="$1"
	speed_info=$(sudo hdparm -t --direct "$device_name")
	if [ -n "$speed_info" ]; then
		echo "${CYAN}Device $device_name speed: $speed_info${NC}"
	else
		echo "${RED}Speed information not available for $device_name${NC}"
	fi
	sleep 3
}

# Function to check USB devices
usb() {
    echo "================================"
    echo  "${YELLOW}\tUSB\n${NC}"
    echo "${RED}Warning:${NC}${BLUE}Please, Check Devices in below list${NC}" 
    sleep 2 
    lsscsi
    echo "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    devices=$(ls /dev/sd* 2>/dev/null | grep -E '/dev/sd[a-z]$')
    
    echo  "${GREEN}Devices specified:${NC}"
    for device in $devices; do
        if [ -e "$device" ]; then
            echo  "${BLUE}$device${NC}"
            device_size=$(lsblk -l | grep -w $(basename $device) | awk '{print $4}' | head -n 1)
            echo "Device: $device"
            echo "Size: $device_size"
        else
            echo  "${RED}Device $device not found.${NC}"
            return 1
        fi
    done

    # Check speed for each disk
    echo  "${CYAN}Checking disk speeds:${NC}"
    for device in $devices; do
        check_disk_speed "$device"
    done
}

sata(){
    echo "================================"
    echo  "${YELLOW}\tSATA (Hard Drive) \n${NC}"
    
    devices=$(lsscsi | grep 'ATA' | awk '{print $NF}')
    
    if [ -z "$devices" ]; then
        echo  "${RED}No SATA devices found.${NC}"
        return 1
    fi
    
    for device in $devices; do
        if [ -e "$device" ] && [ -b "$device" ]; then
            echo  "${BLUE}$device${NC}"
            device_size=$(lsblk -l | grep -w $(basename $device) | awk '{print $4}' | head -n 1)
            echo "Device: $device"
            echo "Size: $device_size"
        else
            echo  "${RED}SATA Device $device not found or is not a valid block device.${NC}"
            return 1
        fi
    done

    # Check speed for each disk
    echo  "${CYAN}Checking disk speeds:${NC}"
    for device in $devices; do
        check_disk_speed "$device"
    done
}

# Function to test Audio Jack 
audio() {
	# Check if nvlc is installed
	echo "${YELLOW}\nAudio Jack \n${NC}"

	status=$(amixer -c 0 get Headphone | grep -o '\[on\]\|\[off\]')
	echo ">>>>> $status"	
	# Check the status and print an appropriate message
	if [ "$status" = "[on]" ]; then
	    echo "Headphones are connected."
	    PLAY_DURATION=10
     	    # Play .mp3 file for 10 seconds using mpg123 with timeout
     	    echo "Playing .mp3 file for $PLAY_DURATION seconds via mpg123..."
     	    mpv --no-video --length="$PLAY_DURATION" Jai\ Ho.mp3

	    echo ">>> Please, Remove Headphone from Axon"
	    sleep 3
	elif [ "$status" = "[off]" ]; then
	    echo "Headphones is not connected"
	    return 1
	else
	    echo "Could not determine the headphone status"
	    return 1
	fi
}

# Function to test Speaker 
speaker() {
    	echo "================================"
    	echo "${YELLOW}\tSpeaker\t\n${NC}"
    	amixer -D pulse sset Master 40%

    	# Play the audio file for 10 seconds
    	echo "${CYAN}Play the audio file for 10 seconds\n"
    	echo "${CYAN}You can check Speaker${NC}\n"
    	
    	# Run ffplay in the background, suppress output and errors
    	ffplay -nodisp -autoexit Jai\ Ho.mp3 > /dev/null 2>&1 &
    	
    	# Get the PID of the ffplay process
    	FFPLAY_PID=$!

    	# Record the system audio (PulseAudio monitor) for 10 seconds using ffmpeg
    	echo "${CYAN}Recording system output for 15 seconds${NC}\n"
    	#ffmpeg -f pulse -i default -t 19 -ac 2 -ar 44100 -y /tmp/recorded_output.wav > /dev/null 2>&1 &
    	ffmpeg -f pulse -i default -t 19 -ac 2 -ar 44100 -y /home/vicharak/recorded_output.wav > /dev/null 2>&1 &
    	
    	sleep 20

    	kill $FFPLAY_PID

    	echo "${CYAN}Audio recording complete. Saved as recorded_output.wav${NC}\n"
    	return 0
}


#Function to check Microphone
microphone(){
	echo "================================"
	echo "${YELLOW}\tRecording Voice which was recoreded by Audio Test for 5 sec\n${NC}"

	# File to store the recording
	#output_file="/tmp/recorded_output.wav"
	output_file="/home/vicharak/recorded_output.wav"
	sleep 2
   
    #	ffplay -nodisp -autoexit Jai\ Ho.mp3 &
	#   Record 5 seconds of audio from the default microphone
    #	echo "Recording for 10 seconds..."
	
	## Check if the file was recorded
	if [ ! -s "$output_file" ]; then
	    echo "Error: No audio recorded or the microphone is not working."
	    return 1
	fi
	
	# Analyze the recorded file for silence
	silence_percentage=$(sox "$output_file" -n stat 2>&1 | grep "Maximum amplitude" | awk '{if ($3 < 0.01) print 100; else print 0;}')
	
	if [ "$silence_percentage" -eq 100 ]; then
	    echo "Error: The recording contains only silence or very low amplitude sound."
	    exit 1
	else
	    echo "Recording successful and contains non-silent audio."
	fi

	# Optionally, play back the recorded file for verification
	#ffplay -autoexit -t '231' $output_file > /dev/null 2>&1 &
	mpv $output_file --no-video
 	FRPLAY_PID=$!

	# Wait for 15 seconds
	sleep 15
	
	# Kill the ffplay process
	sudo rm -rf $output_file
	return 0
}

pcie() {
    echo -e "================================"
    echo "${YELLOW}PCIe"
    echo "${BLUE} Warning : Make sure that Ethernet PCB is properly connected  "
    echo -e -e "${BLUE} List of Peripherals attached to PCI${NC}\n"

    lspci
    echo "\nEthernet Module\n"

    # Check for Ethernet connection on each interface
    for interface in enP2p33s0 enP3p49s0; do
        if sudo ifconfig "$interface" | grep "inet" > /dev/null; then
            echo -e -e "$interface Ethernet is ${GREEN}connected ;)\nIP address: ${CYAN}$(sudo ifconfig "$interface" | awk '/inet /{print $2}')${NC}\n"
            return 0  # Exit the function if a connection is found
        else
            echo -e -e "$interface Ethernet is ${RED}not connected :( ${NC}\n"
        fi
    done

    # If no interface is connected, return failure
    return 1
}

recovery_key(){
	ADC_PATH="/sys/bus/iio/devices/iio:device0/in_voltage1_raw"

	# Set the duration for which the while loop should run (in seconds)
	DURATION=10
	
	# Get the start time
	START_TIME=$(date +%s)
	
	KEY_PRESSED=false
	echo "${BLUE}VOLUME UP KEY${NC}\n"

	while true; do
	    # Read the ADC value
	    ADC_VALUE=$(cat "$ADC_PATH")
	
	    # Check if ADC voltage is less than 512
	    if [ "$ADC_VALUE" -lt 512 ]; then
	        echo "${GREEN}Recovery Key is pressed!${NC}"
		return 0
	        KEY_PRESSED=true
	        break
	    else
	        echo "Recovery Key is not pressed!"
	    fi
	
	    # Check if the duration has passed
	    CURRENT_TIME=$(date +%s)
	    if [ $((CURRENT_TIME - START_TIME)) -ge $DURATION ]; then
	        echo "Timeout reached."
		return 1
	    fi
	
	    sleep 1  # Adjust the sleep duration as needed for your application
	done
}

OFF_INTERNET(){
    echo "Disabling Ethernet and Wi-Fi..."
    sudo ip link set enP3p49s0 down
    sudo ip link set enP2p33s0 down
    sudo ip link set eth2 down
    sudo nmcli radio wifi off
    return 0
}

ON_INTERNET(){
	echo "Enabling Ethernet and Wi-Fi..."
	sudo ip link set enP3p49s0 up 
   	sudo ip link set enP2p33s0 up 
	sudo ip link set eth2 up 
    sudo nmcli radio wifi on
	return 0
}

rtc(){
#	sudo apt install systemd-timesyncd > /dev/null 2&1
#	timedatectl set-ntp true
	#rtctime=$(sudo hwclock --show)
	#cat $(rtctime) 
	#echo " RTC TIME $rtctime" >> "results.log"	
	if [ -f "$start_time_file" ]; then
		echo "Comparing RTC time after poweroff..."
		
		start=$(cat "$start_time_file")
		echo "start time : ${start}"
		start_time=$(date --date="${start}" +"%s")
		current_time=$(date +%s)
		echo "${start_time}"	
		echo "current time : ${current_time}"	
		time_diff=$(( current_time - start_time ))
		#time_diff=${time_diff#-}
		
		max_time_diff=2700

		if [ $time_diff -eq 0 ]; then
		    echo "System time and RTC time are the same. Returning 0."
		    rm -rf $start_time_file 
		    return 0  
		elif [ $time_diff -lt $max_time_diff ] && [ $time_diff -gt 0 ]; then
		    echo "Time difference is less than 30 minutes. Returning 0."
		    rm -rf $start_time_file 
		    return 0  
		else
		    echo "Time difference is more than allowed range. Returning 1"
		    rm -rf $start_time_file 
		    return 1  
		fi
	fi
}

#1
# DPHY - RX0
DPHY_RX0(){
    echo -e "================================"
    echo -e "${YELLOW}\nDPHY_RX0\n${NC}"
    
	ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy-rx0.dtbo.disabled"
	dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy-rx0.dtbo"
	echo "${YELLOW}\nMIPI DPHY RX0 Camera\n${NC}"
	update_extlinux $ovdtbo $dtbo "ov5647" "DPHY_RX0"

	# Wait for 5 seconds
	sleep 2
    	python3 camera_csi_11.py

    	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
       		sleep 2
       		sudo reboot
	fi
}

#2
DPHY_RX1(){
    echo -e "================================"
    echo -e "${YELLOW}\nDPHY_RX0\n${NC}"
    
	ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy-rx1.dtbo.disabled"
	dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy-rx1.dtbo"
	echo "${YELLOW}\nMIPI DPHY RX1 Camera\n${NC}"
	update_extlinux $ovdtbo $dtbo "ov5647" "DPHY_RX1"

	# Wait for 5 seconds
	sleep 2
    	python3 camera_csi_11.py

    	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
       		sleep 2
       		sudo reboot
	fi
}

#3
CSI0_RX1() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_CSI0_RX1\n${NC}"

    ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy1.dtbo.disabled"
    dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy1.dtbo"

    if grep -q "dphy1" "$config_file"; then
        echo "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py 
    	
	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
		return 1
	fi
   else
       	echo 2 | sudo vicharak-config __overlay_manage > /dev/null
       	sudo reboot
   fi

}

# CSI0 - RX2
CSI0_RX2() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_CSI1_RX4\n${NC}"

    ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy2.dtbo.disabled"
    dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy2.dtbo"

    if grep -q "dphy2" "$config_file"; then
        echo "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py 
    	
	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
		return 1
	fi
   else
       	echo 3 | sudo vicharak-config __overlay_manage > /dev/null
       	sudo reboot
   fi

}

#4
CSI1_RX4() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_CSI1_RX4\n${NC}"

    ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy4.dtbo.disabled"
    dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy4.dtbo"

    if grep -q "dphy4" "$config_file"; then
        echo "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py 
    	
	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
		return 1
	fi
   else
       	echo 4 | sudo vicharak-config __overlay_manage > /dev/null
       	sudo reboot
   fi

}

#5
CSI1_RX5() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_CSI1_RX5\n${NC}"

    ovdtbo="/boot/overlays/rk3588-axon_v0.3-camera-ov5647-dphy5.dtbo.disabled"
    dtbo="/overlays/rk3588-axon_v0.3-camera-ov5647-dphy5.dtbo"

    if grep -q "dphy5" "$config_file"; then
        echo "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py 
    	
	if [ "$?" -eq 0 ]; then
		echo "Photo captured ${GREEN}Pass ;)${NC}"
		if grep -q "$dtbo" "$config_file"; then
			sudo sed -i "s|$dtbo||g" "$config_file"
			sudo mv -v "/boot$dtbo" $ovdtbo
			remove_overlays
			echo "Path of $dtbo removed from $config_file"
			return 0
		else
			echo "Path of $dtbo not found in $config_file"
		fi
	else
		# The command has completed successfully
       		echo "Capture ${RED}failed:(${NC}"
		return 1
	fi
   else
       	echo 5 | sudo vicharak-config __overlay_manage > /dev/null
       	sudo reboot
   fi

}


#Set Overlays : DPHY - RX0 && CSI0 - RX2
MIPI_DPHY_RX0_CSI0_RX2(){
    echo "================================"
    echo -e "${YELLOW}\nMIPI_DPHY_RX0_CSI0_RX_2\n${NC}"

    # Check if both "dphy-rx0" and "dphy2" exist in the fdtoverlays line of the config file
    if grep -qE "dphy-rx0.*dphy2|dphy2.*dphy-rx0" "$config_file"; then
	return 1
    else
        echo "dphy-rx0 or dphy2 not found. Applying overlay and rebooting."
        echo 1 | sudo vicharak-config __overlay_manage > /dev/null
        echo 3 | sudo vicharak-config __overlay_manage > /dev/null
	return 0
    fi
}

# DPHY - RX0
MIPI_DPHY_RX0(){
    echo -e "================================"
    echo -e "${YELLOW}\nMIPI_DPHY_RX0\n${NC}"

    # Check if "dphy1" exists in the fdtoverlays line of the config file
    if grep -q "dphy-rx0" "$config_file"; then
        echo -e "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_dphy_22.py

        # Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
	    ###remove_overlays  
            return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy-rx0 not found. Applying overlay and rebooting."
        echo 1 | sudo vicharak-config __overlay_manage
    	#sudo poweroff
	return 1
    fi
}

# CSI0 - RX2
MIPI_CSI0_RX2() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_CSI0_RX2\n${NC}"

    if grep -q "dphy2" "$config_file"; then
        echo "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_31.py 

        # Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
            ###remove_overlays            
	return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy2 not found. Applying overlay and rebooting."
        echo 3 | sudo vicharak-config __overlay_manage > /dev/null
        #sudo poweroff
       	return 1
    fi
}

# Set Overlays : DPHY - RX1 && CSI1 - RX5
MIPI_DPHY_RX1_CSI1_RX5() {
    echo -e "================================"
    echo -e  "${YELLOW}\nMIPI_DPHY_RX1_CSI1_RX_5\n${NC}"

    # Check if both "dphy-rx1" and "dphy5" exist in the config file
    if grep -q "dphy-rx1" "$config_file" && grep -q "dphy5" "$config_file"; then
        return 1
    else
        echo -e "${RED}Failed to Run Overlays${NC}"
        echo -e "dphy-rx1 or dphy5 not found. Applying overlay and rebooting."
        echo  6 | sudo vicharak-config __overlay_manage > /dev/null
        echo  5 | sudo vicharak-config __overlay_manage > /dev/null
        #sudo poweroff
        return 0
    fi
}

# DPHY - RX1
MIPI_DPHY_RX1() {
    echo -e "================================"
    echo -e "${YELLOW}\nMIPI_DPHY_RX1 Camera\n${NC}"

    # Check if "dphy1" exists in the fdtoverlays line of the config file
    if grep -q "dphy-rx1" "$config_file"; then
        echo -e "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_dphy_22.py

        # Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
            ##remove_overlays            
            return 0
        else
            echo -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy-rx1 not found. Applying overlay and rebooting."
        echo -e 6 | sudo vicharak-config __overlay_manage
        #sudo poweroff
    fi
}

# CSI1 - RX5
MIPI_CSI1_RX5() {
    echo -e "================================"
    echo -e "${YELLOW}\nMIPI_CSI1_RX5\n${NC}"

    if grep -q "dphy5" "$config_file"; then
        echo -e "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_31.py

        # Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
	    ##remove_overlays
            return 0
        else
            echo -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy5 not found. Applying overlay and rebooting."
        echo  5 | sudo vicharak-config __overlay_manage > /dev/null
    	return 1
    fi
}

# Set Overlays : DPHY - TX0 && CSI0 - RX1
MIPI_DPHY_TX0_CSI0_RX1(){
    if grep -q "tx0" "$config_file" && grep -q "dphy1" "$config_file" ; then
	return 1
    else
        echo "tx0 not found. Applying overlay and rebooting."
        echo 7 | sudo vicharak-config __overlay_manage > /dev/null
        echo 2 | sudo vicharak-config __overlay_manage > /dev/null
        sleep 2
	echo s3 | sudo tee /opt/test_axon.txt > /dev/null; 
	#sudo poweroff
	#sudo reboot
	return 0
    fi
}

# DPHY - TX0
MIPI_DPHY_TX0(){
    echo -e "================================"
    echo -e -e "${YELLOW}\nMIPI_DPHY_TX0\n${NC}"

    if grep -q "tx0" "$config_file"; then
        if [ "connected" = "$(cat /sys/class/drm/card0-DSI-1/status)" ]; then
                echo -e "DSI Display is ${GREEN}connected ;)${NC}"
                ##remove_overlays            
            	return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        #echo -e 7 | sudo vicharak-config __overlay_manage
	sleep 2
	return 1
	#sudo poweroff
    fi
}

# CSI0 - RX1
MIPI_CSI0_RX1() {
    echo -e "================================"
    echo -e -e "${YELLOW}\nMIPI_CSI0_RX1\n${NC}"

    # Path to the extlinux configuration file
    config_file="/boot/extlinux/extlinux.conf"

    # Check if "dphy1" exists in the fdtoverlays line of the config file
    if grep -q "dphy1" "$config_file"; then
        echo -e -e "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py

	# Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
            ##remove_overlays  
            return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy1 not found. Applying overlay and rebooting."
        echo 2 | sudo vicharak-config __overlay_manage > /dev/null
	return 1
        #sudo poweroff
    fi
}

# Set OVerlays: DPHY - TX1
MIPI_DPHY_TX1_CSI1_RX4(){
    if grep -q "tx1" "$config_file" && grep -q "dphy4" "$config_file" ; then
            return 1
    else
        echo "tx1 not found. Applying overlay and rebooting."
        echo 8 | sudo vicharak-config __overlay_manage
        echo 4 | sudo vicharak-config __overlay_manage
        sleep 2
	#sudo reboot
	return 0
	#sudo poweroff
    fi
}

# DPHY - TX1
MIPI_DPHY_TX1(){
    echo -e "================================"
    echo -e "${YELLOW}\nMIPI_DPHY_TX1\n${NC}"

    if grep -q "tx1" "$config_file"; then
        if [ "connected" = "$(cat /sys/class/drm/card0-DSI-1/status)" ]; then
                echo -e "DSI Display is ${GREEN}connected ;)${NC}"
            	return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "tx1 not found. Applying overlay and rebooting."
        echo 8 | sudo vicharak-config __overlay_manage
        sleep 2
	return 1
	#sudo poweroff
    fi
}

# CSI1 - RX4
MIPI_CSI1_RX4() {
    echo -e "================================"
    echo -e "${YELLOW}\n MIPI_CSI1_RX4\n${NC}"

    # Check if "dphy1" exists in the fdtoverlays line of the config file
    if grep -q "dphy4" "$config_file"; then
        echo -e "\n${BLUE}Running Camera Script${NC}"

        # Run the Python camera test script
        python3 camera_csi_11.py

        # Check if the Python script ran successfully
        if [ "$?" -eq 0 ]; then
            echo -e "Success"
	    ##remove_overlays  # Assuming remove_overlays is defined elsewhere
            return 0
        else
            echo -e -e "${RED}Failed to Capture${NC}"
            return 1
        fi
    else
        echo -e "dphy4 not found. Applying overlay and rebooting."
        echo 4 | sudo vicharak-config __overlay_manage
        #sudo poweroff
	return 1
    fi
}

# Check Mali GPU
mali_gpu(){
    # Check if Mali firmware is loaded
    gpustatus=$(dmesg | grep -i "Mali firmware git_sha")

    # Check if the firmware file exists
    firmware_file="/lib/firmware/mali_csffw.bin"

    # Check both conditions together
    if [ -n "$gpustatus" ] && [ -f "$firmware_file" ]; then
        echo "Mali firmware is loaded and firmware file exists."
        echo "$gpustatus"
    else
        if [ -z "$gpustatus" ]; then
            echo "Mali firmware not loaded."
	    return 1
        fi
        if [ ! -f "$firmware_file" ]; then
            echo "Firmware file not found: $firmware_file"
	    return 1
        fi
    fi
}

HDMI_RX() {
    # Run the v4l2-ctl command and capture its output
    # check_rx_output=$(v4l2-ctl --stream-mmap --stream-count=1 --stream-to=/tmp/hdmi_rx_test.raw -d0 2>&1)
 	set_rtc_time=$(sudo hwclock --systohc)
	show_set_rtc_time=$(sudo hwclock --show)
	echo "${show_set_rtc_time}" > "${start_time_file}"  
	echo ">>>>>>>>>>>>>>>>>>>"
	echo "Read RTC SET TIME : $(cat "/test/rtc_time.txt") "
	echo ">>> ${show_set_rtc_time}"
	echo ">>>>>>>>>>>>>>>>>>>"
   
    ./v4l2grab
    check_rx_output=$?

    # Check if the output contains '>' OR if the file was created and has content
    if [ "$check_rx_output" = "0" ]; then
        echo "HDMI-RX stream detected or command returned '>' indicating success."
        return 0
    else
        echo "HDMI-RX stream not detected and command did not return '>'."
        return 1
    fi
}

set_overlays(){
	#cd /media/vicharak/axon_test
	echo "Let me set timing first....."
	sudo ntpdate ntp.ubuntu.com
    sudo apt update > /dev/null
	sleep 3
	sudo apt install ./axon-overlays_1.0.0_arm64.deb
}

remove_overlays(){
    pattern_to_remove="fdtoverlays"
    overlay_dir="/boot/overlays"

    if [ ! -f "$config_file" ]; then
        echo "${BLUE}File not found!${NC}"
        return 1
    fi

    # Remove lines containing the pattern from the config file
    sudo sed -i "/$pattern_to_remove/d" "$config_file"
    echo "${BLUE}Removed lines containing '$pattern_to_remove' from $config_file${NC}\n"

    for file in "$overlay_dir"/*; do
        basefile=$(basename "$file")  # Extracts the filename from the full path

        if [ "$basefile" = "managed.list" ] || [ "$basefile" = "README.rockchip-overlays" ]; then
            echo "${BLUE}Skipping $basefile${NC}\n"
            continue
        fi

        if [ "${file##*.}" != "disabled" ]; then
            sudo mv "$file" "$file.disabled"
            echo "${BLUE}Renamed $file to $file.disabled${NC}\n"
        fi
    done

    return 0
}

GPIO_CHECK(){
    echo -n "${YELLOW}Checking GPIO Pins ${NC}"
    sudo modprobe ch341
    echo -n "Make sure you have attached Type-C USB cable from ESP32 Module to AXON "
    sleep 3
    usb_status=$(ls /dev/tty* | grep ttyUSB*)
    if [ $usb_status = "/dev/ttyUSB0" ]; then
	echo "GPIO is going to check"
        sudo python3 gpio_check.py
	    return 0
    else
	    return 1
    fi
    sleep 1
}


GPIO(){
    echo -n "${YELLOW}Checking GPIO Pins ${NC}"
    echo -n "To check GPIO, Make sure Axon is connected to Internet."
    echo -n "Make sure you have attached Type-C USB cable from ESP32 Module to AXON "
    sudo modprobe ch341
   	sudo pip install pyserial
   	sudo apt -y remove brltty > /dev/null
    
    usb_status=$(ls /dev/tty* | grep ttyUSB*)
    if [ $usb_status = "/dev/ttyUSB0" ]; then
	echo "GPIO is going to check"
        sudo python3 gpio_check.py
	    return 0
    else
	    return 1
    fi
}


# Function to tesll all
runall_group1() {
	for test in set_overlays set_theme HDMI_0 TYPE_C_DP0 wifi bluetooth eth install_package sdCard emmc nvme usb sata audio speaker microphone pcie recovery_key HDMI_RX MIPI_DPHY_RX0_CSI0_RX2 OFF_INTERNET ; do
		if handle_test $test $test ; then
			echo ""
		else
			echo "Skipping to the next test..."
			continue
		fi
		# Add any additional logic here after a successful test
	done
}

runall_group2() {
	#for test in HDMI_1 TYPE_C_DP1 mipidsi ##remove_overlays ; do
	for test in  MIPI_DPHY_RX0 MIPI_CSI0_RX2 remove_overlays MIPI_DPHY_RX1_CSI1_RX5 ; do
		if handle_test $test $test; then
			echo ""
		else
			echo "Skipping to the next test..."
			continue
		fi
		# Add any additional logic here after a successful test
	done
}


runall_group3() {
	for test in  MIPI_DPHY_RX1 MIPI_CSI1_RX5 remove_overlays MIPI_DPHY_TX0_CSI0_RX1 ;  do
		if handle_test $test $test; then
			echo ""
		else
			echo "Skipping to the next test..."
			continue
		fi
		# Add any additional logic here after a successful test
	done
}

reboot_display(){
	TEMP=`expr $(cat /opt/test_axon.txt | cut -c 2) + 1`
	echo "s$TEMP" | sudo tee /opt/test_axon.txt > /dev/null; 
	sudo reboot
}

runall_group4() {
	for test in  MIPI_DPHY_TX0 MIPI_CSI0_RX1 remove_overlays MIPI_DPHY_TX1_CSI1_RX4   ;  do
		if handle_test $test $test; then
			echo ""
		else
			echo "Skipping to the next test..."
			continue
		fi
		# Add any additional logic here after a successful test
	done
}

read_result_file(){
	sudo cat results.log
}

runall_group5() {
	for test in  MIPI_DPHY_TX1 MIPI_CSI1_RX4 rtc HDMI_1 TYPE_C_DP1 remove_overlays ON_INTERNET GPIO_CHECK;  do
		if handle_test $test $test; then
			echo ""
		else
			echo "Skipping to the next test..."
			continue
		fi
		# Add any additional logic here after a successful test
	done
}


runall_group6(){
	echo 'Remove Scipt from Axon'
}

install_package(){
	sudo apt update > /dev/null
   	sudo pip install pyserial
   	sudo apt -y remove brltty > /dev/null
    sudo apt -y install iozone3
	sudo pip install opencv-python
}


# Main script
main() {
	echo "${YELLOW}Enter a valid number to run test script:${NC}"
	echo "${CYAN}\ns. Set_Overlays \n0. Install Pre-requisites Packages  \n1. Set Vicharak Theme \n2. HDMI-0 \n3. HDMI-1 \n4. TYPE-C DP1 \n5. TYPE-C DP2 \n6. WiFi \n7. Bluetooth \n8. Ethernet \n9. MicroSD Card \n10. EMMC  \n11. NVMe \n12. USB \n13. SATA  \n14. Audio Jack \n15. Speaker Left And Right \n16. Microphone \n17. PCIe \n18. Recovery Key \n19. RTC \n20. HDMI_RX \n21. MIPI_DPHY-RX0 Camera \n22. MIPI_CSI0-RX2 Camera \n23. MIPI_DPHY-RX1 Camera \n24. MIPI_CSI1-RX5 Camera\n25. MIPI_DPHY-TX0 Display\n26. MIPI_CSI0-RX1 Camera\n27. MIPI_DPHY-TX1 Display\n28. MIPI_CSI1-RX4 Camera \n29. GPIO \n32. OFF INTERNET \n33. ON INTERNET \ngpu. Mali GPU \no1. MIPI_DPHY-RX0 && MIPI_CSI0-RX2 \no2. MIPI_DPHY-RX1 && MIPI_CSI1-RX5 \no3. MIPI_DPHY-TX0 && MIPI_CSI0-RX1 \no4. MIPI_DPHY-TX1 && MIPI_CSI1-RX4 \ns0) Group-1 ( 1 - 18 ) \ns1) Group-2 ( 19 & 20 ) \ns2) Group-3 ( 21 & 22 ) \ns3) Group-4 ( 23 & 24 ) \ns4) Group-5 ( 25 & 26 ) ${NC}"
#	echo "${GREEN}Enter the number of the test you want to run: ${NC}"
#	read option

	# Check if an argument is provided
	if [ -z "$1" ]; then
	    echo "${GREEN}Enter the number of the test you want to run or use an option (e.g., a, b, c, r, etc.): ${NC}"
	    read option
	else
	    option="$1"
	fi

	case "$option" in
		s) handle_test set_overlays "Set Overlays" "s0";;
		0) install_package "Install Packages" "0";;
		1) handle_test set_theme "Set Vicharak Theme" "1" ;;
		2) handle_test HDMI_0 "HDMI_0" "2" ;;
		3) handle_test HDMI_1 "HDMI_1" "3";;
		4) handle_test TYPE_C_DP0 "TYPE_C_DP0" "4" ;;
		5) handle_test TYPE_C_DP1 "TYPE_C_DP1" "5";;
		6) handle_test wifi "WiFi" "6";;
		7) handle_test bluetooth "Bluetooth" "7";;
		8) handle_test eth "Ethernet" "8";;
		9) handle_test sdCard "SD-Card" "9";;
		10) handle_test emmc "EMMC" "10";;
		11) handle_test nvme "NVME" "11";;
		12) handle_test usb "USB" "12";;
		13) handle_test sata "SATA" "13" ;; 
		14) handle_test audio "Audio" "14" ;;
		15) handle_test speaker "Speaker" "15" ;;
		16) handle_test microphone "Microphone" "16";;
		17) handle_test pcie "PCIe" "17";;
		18) handle_test recovery_key "Recovery Key" "17" ;;
		19) handle_test rtc "RTC" "18" ;;
		20) handle_test HDMI_RX "HDMI_RX" "19" ;;
		21) handle_test MIPI_DPHY_RX0 "MIPI_DPHY-RX0" "20" ;;
		22) handle_test MIPI_CSI0_RX2 "MIPI_CSI0-RX2" "21" ;;
		23) handle_test MIPI_DPHY_RX1 "MIPI_DPHY-RX1" "22" ;; 	
		24) handle_test MIPI_CSI1_RX5 "MIPI_CSI1-RX5" "23" ;;
		25) handle_test MIPI_DPHY_TX0 "MIPI_DPHY_TX0" "24" ;;  	
		26) handle_test MIPI_CSI0_RX1 "MIPI_CSI0-RX1" "25" ;;	
		27) handle_test MIPI_DPHY_TX1 "MIPI_DPHY-TX1" "26" ;;  
		28) handle_test MIPI_CSI1_RX4 "MIPI_CSI1-RX4" "27" ;;
       		29) handle_test GPIO "GPIO" "29" ;;
        	30) handle_test DPHY_RX0 "MIPI_DPHY_RX0" "30" ;; 
       		31) handle_test CSI0_RX4 "MIPI_CSI1_RX4" "31" ;; 
        	32) handle_test OFF_INTERNET ;;
		33) handle_test ON_INTERNET ;;
	   	o1) handle_test MIPI_DPHY_RX0_CSI0_RX2 "MIPI_DPHY-RX0_CSI0-RX2" "o1" ;;
		o2) handle_test MIPI_DPHY_RX1_CSI1_RX5 "MIPI_DPHY-RX1_CSI1-RX5" "o2" ;;
		o3) handle_test MIPI_DPHY_TX0_CSI0_RX1 "MIPI_DPHY-TX0_CSI0-RX1" "o3" ;;
 		o4) handle_test MIPI_DPHY_TX1_CSI1_RX4 "MIPI_DPHY-TX1_CSI1-RX4" "o4" ;;
		gpu) handle_test mali_gpu "mali_gpu" "g" ;;
		s0) runall_group1 "GROUP-1 :  0 - 18 " ;;
		s1) runall_group2 "GROUP-2 : 19 & 20 " ;;
		s2) runall_group3 "GROUP-3 : 21 & 22 " ;;
		s3) reboot_display ;;
		s4) runall_group4 "GROUP-4 : 23 & 24 " ;;
		s5) reboot_display ;;
		s6) runall_group5 "GROUP-5 : 25 & 26 " ;;
		s7) runall_group6 ;;
		r) handle_test remove_overlays "Remove fdtoverlays" "r" ;;
		*) echo "${RED}Invalid option. Please select a valid test.${NC}" ;;
	esac

	# Print results summary
	echo "\n${YELLOW}Test Summary:${NC}"
	echo "$results"
}

# Call the main function
main "$@"
