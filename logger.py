import serial

# Replace with exact string from terminal output
serial_port = "/dev/cu.usbserial-1130"

ser = serial.Serial(serial_port, 115200, timeout=1)

print("Running logger...")

while True:
    if ser.in_waiting > 0:
        line = ser.readline().decode("utf-8", errors="ignore")
        print(line, end="")
