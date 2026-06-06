import serial

serial_port = "/dev/cu.usbserial-110"
ser = serial.Serial(serial_port, 115200, timeout=1)

print("Running logger...")

while True:
    if ser.in_waiting > 0:
        line = ser.readline().decode("utf-8", errors="ignore")
        print(line, end="")
