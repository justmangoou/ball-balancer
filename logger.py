import serial
import csv
import time
from datetime import datetime

# --- Configuration ---
# Windows: 'COM3', 'COM4', etc. 
# Linux/Mac: '/dev/tty.usbserial-1410' or '/dev/ttyUSB0'
SERIAL_PORT = 'COM3' 
BAUD_RATE = 115200 
OUTPUT_FILE = "data.csv"

HEADER = ["Timestamp", ""]

def run_logger():
    print(f"--- Starting Logger on {SERIAL_PORT} ---")
    
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
        
        with open(OUTPUT_FILE, "a", newline='') as f:
            writer = csv.writer(f)
            
            if f.tell() == 0:
                writer.writerow(["Timestamp", "Raw_Data"])

            print("Listening for data... (Press Ctrl+C to stop)")

            while True:
                if ser.in_waiting > 0:
                    raw_line = ser.readline().decode('utf-8', errors='replace').strip()
                    
                    if raw_line:
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
                        
                        data_points = raw_line.split(',')
                        row = [timestamp] + data_points
                        
                        writer.writerow(row)
                        f.flush()
                        print(f"[{timestamp}] Saved: {data_points}")

    except serial.SerialException as e:
        print(f"Error: Could not open serial port {SERIAL_PORT}. Is it plugged in?")
    except KeyboardInterrupt:
        print("\nLogging stopped by user.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")

if __name__ == "__main__":
    run_logger()