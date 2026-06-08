import csv
import os
import re
import time
from collections import deque
from datetime import datetime

import matplotlib.pyplot as plt
import serial

# ─── Configurations ───────────────────────────────────────────────────────────
SERIAL_PORT = "/dev/cu.usbserial-110"
BAUD_RATE = 115200
PLOT_INTERVAL = 0.1  # Minimum seconds between redraws (10 FPS cap)
TRAIL_LEN = 2000  # How many historical points to keep on each plot

# ─── Regex ────────────────────────────────────────────────────────────────────
DATA_PATTERN = re.compile(
    r"x_parc:\s*([\d.-]+)\s*\|\s*"
    r"y_parc:\s*([\d.-]+)\s*\|\s*"
    r"x_out:\s*([\d.-]+)\s*\|\s*"
    r"y_out:\s*([\d.-]+)\s*\|\s*"
    r"a_pos:\s*([\d.-]+)\s*\|\s*"
    r"b_pos:\s*([\d.-]+)\s*\|\s*"
    r"c_pos:\s*([\d.-]+)"
)

# ─── Serial ───────────────────────────────────────────────────────────────────
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

# ─── CSV ──────────────────────────────────────────────────────────────────────
os.makedirs("logs", exist_ok=True)
csv_filename = f"logs/{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.csv"
csv_file = open(csv_filename, mode="w", newline="", encoding="utf-8")
csv_writer = csv.writer(csv_file)
csv_writer.writerow(
    ["Timestamp", "x_parc", "y_parc", "x_out", "y_out", "a_pos", "b_pos", "c_pos"]
)

# ─── Plot Setup ───────────────────────────────────────────────────────────────
plt.ion()
fig = plt.figure(figsize=(10, 3))
fig.suptitle("Real-Time PID Tracker", fontsize=11, fontweight="bold")

ax_parc = fig.add_subplot(111)
ax_out = ax_parc.twinx()  # shares X, independent Y scale

(line_x_parc,) = ax_parc.plot([], [], color="#2196F3", linewidth=0.8, label="x_parc")
(line_y_parc,) = ax_parc.plot([], [], color="#F44336", linewidth=0.8, label="y_parc")

(line_x_out,) = ax_out.plot(
    [], [], color="#00BCD4", linewidth=1.0, linestyle="--", label="x_out"
)
(line_y_out,) = ax_out.plot(
    [], [], color="#FF9800", linewidth=1.0, linestyle="--", label="y_out"
)

ax_parc.set_xlim(0, TRAIL_LEN)
ax_parc.set_ylim(-100, 100)
ax_out.set_ylim(-0.3, 0.3)

ax_parc.set_ylabel("parc (setpoint)", color="steelblue")
ax_out.set_ylabel("out (PID output)", color="#00BCD4")
ax_parc.set_xlabel("Sample #")
ax_parc.grid(True, alpha=0.3)

# Merge legends from both axes
lines = [line_x_parc, line_y_parc, line_x_out, line_y_out]
labels = ["x_parc", "y_parc", "x_out", "y_out"]
ax_parc.legend(lines, labels, fontsize=8, loc="upper left")

fig.subplots_adjust(top=0.85, bottom=0.18, left=0.08, right=0.92)

# ─── Rolling Buffers (avoids unbounded memory growth) ─────────────────────────
buf_x_parc = deque(maxlen=TRAIL_LEN)
buf_x_out = deque(maxlen=TRAIL_LEN)
buf_y_parc = deque(maxlen=TRAIL_LEN)
buf_y_out = deque(maxlen=TRAIL_LEN)

# ─── Draw Throttle State ──────────────────────────────────────────────────────
last_draw = 0.0
sample_idx = 0


def update_plots():
    n = len(buf_x_parc)
    xs = list(range(sample_idx - n, sample_idx))  # absolute sample indices

    line_x_parc.set_data(xs, list(buf_x_parc))
    line_y_parc.set_data(xs, list(buf_y_parc))
    line_x_out.set_data(xs, list(buf_x_out))
    line_y_out.set_data(xs, list(buf_y_out))

    ax_parc.set_xlim(sample_idx - TRAIL_LEN, sample_idx)  # window follows head

    fig.canvas.draw_idle()
    fig.canvas.flush_events()


# ─── Main Loop ────────────────────────────────────────────────────────────────
print(f"Logging to {csv_filename} | Ctrl-C to stop")

try:
    while True:
        if not ser.in_waiting:
            continue

        raw_line = ser.readline().decode("utf-8", errors="ignore").strip()
        if not raw_line:
            continue
        print(raw_line)  # echo to terminal

        match = DATA_PATTERN.search(raw_line)
        if not match:
            print(f"  [no match] {raw_line}")
            continue

        x_p, y_p, x_o, y_o, a, b, c = match.groups()
        x_parc, y_parc = float(x_p), float(y_p)
        x_out, y_out = float(x_o), float(y_o)

        # — Log everything to CSV (no throttle — every sample recorded) —
        csv_writer.writerow(
            [time.time(), x_parc, y_parc, x_out, y_out, float(a), float(b), float(c)]
        )
        csv_file.flush()

        # — Update rolling buffers —
        buf_x_parc.append(x_parc)
        buf_x_out.append(x_out)
        buf_y_parc.append(y_parc)
        buf_y_out.append(y_out)
        sample_idx += 1

        # — Throttled redraw: only paint when enough time has elapsed —
        now = time.perf_counter()
        if now - last_draw >= PLOT_INTERVAL:
            update_plots()
            last_draw = now

except KeyboardInterrupt:
    print("\nStopping...")
finally:
    csv_file.close()
    ser.close()
    plt.ioff()
    plt.show()  # Keep window open after exit
    print("Done.")
