import subprocess
import serial
import json
import time
import sys  # Add sys for exiting the script

# Automated responses
automated_inputs = iter(["1", "0", "yes"])

# Override input to automate responses
def input(prompt=""):
    response = next(automated_inputs)
    print(f"{prompt}{response}")  # Print the prompt and the automated response
    return response

# Function to set GPIO pins to a certain state
def set_gpio_pins(state):
    commands = [
        f"sudo gpioset gpiochip2 17={state}",
        f"sudo gpioset gpiochip2 14={state}",
        f"sudo gpioset gpiochip2 16={state}",
        f"sudo gpioset gpiochip2 15={state}",
        f"sudo gpioset gpiochip0 16={state}",
        f"sudo gpioset gpiochip1 24={state}",
        f"sudo gpioset gpiochip1 25={state}",
        f"sudo gpioset gpiochip1 27={state}",
        f"sudo gpioset gpiochip1 26={state}",
        f"sudo gpioset gpiochip1 11={state}"
    ]
    
    for cmd in commands:
        try:
            subprocess.run(cmd, shell=True, check=True)
            print(f"Executed: {cmd}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to set GPIO pin with command: {cmd}, error: {e}")

# Function to prompt for pin state and set GPIO pins
def prompt_and_set_gpio():
    value = input("Set all GPIO Pins HIGH or LOW? Type '1' for High, '0' for Low: ")
    state = '1' if value == '1' else '0'
    print(f"Setting all GPIO pins to {state}...")
    set_gpio_pins(state)
    print(f"All GPIO pins have been set to {state}.")
    return state

# Function to send a command over the serial port
def send_serial_command(ser, command):
    json_command = json.dumps(command)
    ser.write((json_command + '\n').encode())  # Send command with newline for ESP32 to read
    print(f"Sent: {json_command}")

def get_and_print_gpio_values(ser):
    gpio_pins = {
        "GPIO2_C1#33": "gpiochip2 17",
        "GPIO2_B6#34": "gpiochip2 14",
        "GPIO2_C0#35": "gpiochip2 16",
        "GPIO2_B7#36": "gpiochip2 15",
        "GPIO0_C0#37": "gpiochip0 16",
        "GPIO1_D0#38": "gpiochip1 24",
        "GPIO1_D1#39": "gpiochip1 25",
        "GPIO1_D3#40": "gpiochip1 27",
        "GPIO1_D2#42": "gpiochip1 26",
        "GPIO1_B3#41": "gpiochip1 11",
    }

    for label, gpio_chip in gpio_pins.items():
        value = get_gpio_value(gpio_chip)
        print(f"{label} = {value}")

    change_state = input("Do you want to set all GPIO Pins to LOW? Type 'yes' to confirm: ")
    if change_state.lower() == 'yes':
        write_command = {
            "type": "write",
            "pins": [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42],
            "status": "low"
        }
        send_serial_command(ser, write_command)
        print("Sent: Setting specified pins to LOW.")
        
        print("Retrieving GPIO values after setting to LOW...")
        get_and_print_gpio_values_01()

        # Exit the script after completion
        sys.exit("All tasks completed successfully.")

    print("GPIO Tested!!")


# Function to continuously read the response from the serial port
def read_response(ser, pins_to_read):
    while True:
        pin_states = {pin: None for pin in pins_to_read}
        
        lines = []
        while ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            if line:
                print(f"Received: {line}")
                lines.append(line)

        for line in lines:
            for pin in pins_to_read:
                if f"Pin {pin} value: 1" in line:
                    pin_states[pin] = 1
                elif f"Pin {pin} value: 0" in line:
                    pin_states[pin] = 0

            if "Pins set to high" in line:
                print("All specified pins are HIGH. Retrieving GPIO values...")
                get_and_print_gpio_values(ser)

        if pin_states[17] == 1 and pin_states[18] == 1:
            all_other_low = all(pin_states[pin] == 0 for pin in pins_to_read if pin not in [17, 18])
            if all_other_low:
                write_command = {
                    "type": "write",
                    "pins": [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42],
                    "status": "high"
                }
                send_serial_command(ser, write_command)

        if all(pin_states[pin] == 1 for pin in pins_to_read):
            print("All specified pins are HIGH.")
            prompt_and_set_gpio()
            read_command = {
                "type": "read",
                "pins": pins_to_read
            }
            send_serial_command(ser, read_command)

        time.sleep(0.5)

# Function to get GPIO values
def get_gpio_value(gpio_chip):
    try:
        result = subprocess.run(
            ["sudo", "gpioget"] + gpio_chip.split(),
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error getting GPIO value for {gpio_chip}: {e}")
        return "Error"

def get_and_print_gpio_values_01():
    gpio_pins = {
        "GPIO2_C1#33": "gpiochip2 17",
        "GPIO2_B6#34": "gpiochip2 14",
        "GPIO2_C0#35": "gpiochip2 16",
        "GPIO2_B7#36": "gpiochip2 15",
        "GPIO0_C0#37": "gpiochip0 16",
        "GPIO1_D0#38": "gpiochip1 24",
        "GPIO1_D1#39": "gpiochip1 25",
        "GPIO1_D3#40": "gpiochip1 27",
        "GPIO1_D2#42": "gpiochip1 26",
        "GPIO1_B3#41": "gpiochip1 11",
    }

    for label, gpio_chip in gpio_pins.items():
        value = get_gpio_value(gpio_chip)
        print(f"{label} = {value}")

# Main script
serial_port = '/dev/ttyUSB0'  # Replace with your USB port
baud_rate = 115200  # Match the baud rate of your ESP32
ser = serial.Serial(serial_port, baud_rate, timeout=1)

try:
    prompt_and_set_gpio()

    pins_to_read = [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42]
    read_command = {
        "type": "read",
        "pins": pins_to_read
    }
    send_serial_command(ser, read_command)

    read_response(ser, pins_to_read)

finally:
    ser.close()
    sys.exit("Serial communication ended, exiting the program.")


#import subprocess
#import serial
#import json
#import time
#
## Automated responses
#automated_inputs = iter(["1", "0", "yes"])
#
## Override input to automate responses
#def input(prompt=""):
#    response = next(automated_inputs)
#    print(f"{prompt}{response}")  # Print the prompt and the automated response
#    return response
#
## Function to set GPIO pins to a certain state
#def set_gpio_pins(state):
#    commands = [
#        f"sudo gpioset gpiochip2 17={state}",
#        f"sudo gpioset gpiochip2 14={state}",
#        f"sudo gpioset gpiochip2 16={state}",
#        f"sudo gpioset gpiochip2 15={state}",
#        f"sudo gpioset gpiochip0 16={state}",
#        f"sudo gpioset gpiochip1 24={state}",
#        f"sudo gpioset gpiochip1 25={state}",
#        f"sudo gpioset gpiochip1 27={state}",
#        f"sudo gpioset gpiochip1 26={state}",
#        f"sudo gpioset gpiochip1 11={state}"
#    ]
#    
#    for cmd in commands:
#        try:
#            subprocess.run(cmd, shell=True, check=True)
#            print(f"Executed: {cmd}")
#        except subprocess.CalledProcessError as e:
#            print(f"Failed to set GPIO pin with command: {cmd}, error: {e}")
#
## Function to prompt for pin state and set GPIO pins
#def prompt_and_set_gpio():
#    value = input("Set all GPIO Pins HIGH or LOW? Type '1' for High, '0' for Low: ")
#    state = '1' if value == '1' else '0'
#    print(f"Setting all GPIO pins to {state}...")
#    set_gpio_pins(state)
#    print(f"All GPIO pins have been set to {state}.")
#    return state
#
## Function to send a command over the serial port
#def send_serial_command(ser, command):
#    json_command = json.dumps(command)
#    ser.write((json_command + '\n').encode())  # Send command with newline for ESP32 to read
#    print(f"Sent: {json_command}")
#
#def get_and_print_gpio_values(ser):
#    # Define the GPIO pins and their corresponding labels
#    gpio_pins = {
#        "GPIO2_C1#33": "gpiochip2 17",
#        "GPIO2_B6#34": "gpiochip2 14",
#        "GPIO2_C0#35": "gpiochip2 16",
#        "GPIO2_B7#36": "gpiochip2 15",
#        "GPIO0_C0#37": "gpiochip0 16",
#        "GPIO1_D0#38": "gpiochip1 24",
#        "GPIO1_D1#39": "gpiochip1 25",
#        "GPIO1_D3#40": "gpiochip1 27",
#        "GPIO1_D2#42": "gpiochip1 26",
#        "GPIO1_B3#41": "gpiochip1 11",
#    }
#
#    # Loop through the GPIO pins and print their values
#    for label, gpio_chip in gpio_pins.items():
#        value = get_gpio_value(gpio_chip)
#        print(f"{label} = {value}")
#
#    # Prompt the user to change GPIO state to LOW
#    change_state = input("Do you want to set all GPIO Pins to LOW? Type 'yes' to confirm: ")
#    if change_state.lower() == 'yes':
#        # Send the write command to set specified pins to low
#        write_command = {
#            "type": "write",
#            "pins": [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42],  # Change this to your actual pins if needed
#            "status": "low"
#        }
#        send_serial_command(ser, write_command)
#        print("Sent: Setting specified pins to LOW.")
#        
#        # After changing GPIO state, retrieve GPIO values again
#        print("Retrieving GPIO values after setting to LOW...")
#        get_and_print_gpio_values_01()
#
#    print("GPIO Tested!!")
#
#
## Function to continuously read the response from the serial port
#def read_response(ser, pins_to_read):
#    while True:
#        pin_states = {pin: None for pin in pins_to_read}
#        
#        lines = []
#        while ser.in_waiting > 0:
#            line = ser.readline().decode('utf-8').strip()
#            if line:
#                print(f"Received: {line}")
#                lines.append(line)
#
#        for line in lines:
#            for pin in pins_to_read:
#                if f"Pin {pin} value: 1" in line:
#                    pin_states[pin] = 1
#                elif f"Pin {pin} value: 0" in line:
#                    pin_states[pin] = 0
#
#            if "Pins set to high" in line:
#                print("All specified pins are HIGH. Retrieving GPIO values...")
#                get_and_print_gpio_values(ser)
#
#        if pin_states[17] == 1 and pin_states[18] == 1:
#            all_other_low = all(pin_states[pin] == 0 for pin in pins_to_read if pin not in [17, 18])
#            if all_other_low:
#                write_command = {
#                    "type": "write",
#                    "pins": [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42],
#                    "status": "high"
#                }
#                send_serial_command(ser, write_command)
#
#        if all(pin_states[pin] == 1 for pin in pins_to_read):
#            print("All specified pins are HIGH.")
#            prompt_and_set_gpio()
#            read_command = {
#                "type": "read",
#                "pins": pins_to_read
#            }
#            send_serial_command(ser, read_command)
#
#        time.sleep(0.5)
#
## Function to get GPIO values
#def get_gpio_value(gpio_chip):
#    try:
#        result = subprocess.run(
#            ["sudo", "gpioget"] + gpio_chip.split(),
#            capture_output=True,
#            text=True,
#            check=True
#        )
#        return result.stdout.strip()
#    except subprocess.CalledProcessError as e:
#        print(f"Error getting GPIO value for {gpio_chip}: {e}")
#        return "Error"
#
#def get_and_print_gpio_values_01():
#    gpio_pins = {
#        "GPIO2_C1#33": "gpiochip2 17",
#        "GPIO2_B6#34": "gpiochip2 14",
#        "GPIO2_C0#35": "gpiochip2 16",
#        "GPIO2_B7#36": "gpiochip2 15",
#        "GPIO0_C0#37": "gpiochip0 16",
#        "GPIO1_D0#38": "gpiochip1 24",
#        "GPIO1_D1#39": "gpiochip1 25",
#        "GPIO1_D3#40": "gpiochip1 27",
#        "GPIO1_D2#42": "gpiochip1 26",
#        "GPIO1_B3#41": "gpiochip1 11",
#    }
#
#    for label, gpio_chip in gpio_pins.items():
#        value = get_gpio_value(gpio_chip)
#        print(f"{label} = {value}")
#
## Main script
#serial_port = '/dev/ttyUSB0'  # Replace with your USB port
#baud_rate = 115200  # Match the baud rate of your ESP32
#ser = serial.Serial(serial_port, baud_rate, timeout=1)
#
#try:
#    prompt_and_set_gpio()
#
#    pins_to_read = [17, 18, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42]
#    read_command = {
#        "type": "read",
#        "pins": pins_to_read
#    }
#    send_serial_command(ser, read_command)
#
#    read_response(ser, pins_to_read)
#
#except KeyboardInterrupt:
#    print("Exiting...")
#
#finally:
#    ser.close()
