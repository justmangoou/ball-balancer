import csv
import re
import time

import matplotlib.pyplot as plt
import serial

# Configurations
SERIAL_PORT = "/dev/cu.usbserial-1130"
BAUD_RATE = 115200
CSV_FILENAME = "telemetry_log.csv"

# Regex parsing pattern matching C printf structure exactly
DATA_PATTERN = re.compile(
    r"x_parc:\s*([\d.-]+)\s*\|\s*"
    r"y_parc:\s*([\d.-]+)\s*\|\s*"
    r"x_out:\s*([\d.-]+)\s*\|\s*"
    r"y_out:\s*([\d.-]+)\s*\|\s*"
    r"a_pos:\s*([\d-]+)\s*\|\s*"
    r"b_pos:\s*([\d-]+)\s*\|\s*"
    r"c_pos:\s*([\d-]+)"
)

# Setup Serial
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

# Setup CSV File and Header Row
csv_file = open(CSV_FILENAME, mode="w", newline="", encoding="utf-8")
csv_writer = csv.writer(csv_file)
csv_writer.writerow(
    [
        "Timestamp",
        "x_parc",
        "y_parc",
        "x_out",
        "y_out",
        "a_pos",
        "b_pos",
        "c_pos",
    ]
)

# Setup Interactive Matplotlib Plotting
plt.ion()
fig, ax = plt.subplots(figsize=(6, 6))
(ball_trace,) = ax.plot([], [], "ro", markersize=12, label="Ball Position")
ax.set_xlim(-100, 100)
ax.set_ylim(-100, 100)
ax.axhline(0, color="black", linewidth=0.5, linestyle="--")
ax.axvline(0, color="black", linewidth=0.5, linestyle="--")
ax.grid(True)
ax.set_title("Real-Time Ball Tracker Frame")
ax.set_xlabel("X Percentage")
ax.set_ylabel("Y Percentage")
ax.legend()

print(f"Running logger... Writing to {CSV_FILENAME}")

try:
    while True:
        if ser.in_waiting > 0:
            raw_line = ser.readline().decode("utf-8", errors="ignore").strip()
            print(raw_line)  # Echo to console terminal output shell

            match = DATA_PATTERN.search(raw_line)
            if match:
                # Extract float and integer tokens
                x_p, y_p, x_o, y_o, a, b, c = match.groups()
                x_parc = float(x_p)
                y_parc = float(y_p)

                # Write parsed records to storage disk array
                current_time = time.time()
                csv_writer.writerow(
                    [
                        current_time,
                        x_parc,
                        y_parc,
                        float(x_o),
                        float(y_o),
                        int(a),
                        int(b),
                        int(c),
                    ]
                )
                csv_file.flush()  # Force write buffer memory dump

                # Update 2D canvas coordinates dynamically
                ball_trace.set_data([x_parc], [y_parc])
                fig.canvas.draw()
                fig.canvas.flush_events()

except KeyboardInterrupt:
    print("\nStopping logger process thread Safely...")
finally:
    csv_file.close()
    ser.close()
    print("Resources closed clean.")
