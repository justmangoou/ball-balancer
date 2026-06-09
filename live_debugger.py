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
    r"x_err:\s*([\d.-]+)\s*\|\s*"
    r"y_err:\s*([\d.-]+)\s*\|\s*"
    r"x_out:\s*([\d.-]+)\s*\|\s*"
    r"y_out:\s*([\d.-]+)\s*\|\s*"
    r"a_theta:\s*([\d.-]+)\s*\|\s*"
    r"b_theta:\s*([\d.-]+)\s*\|\s*"
    r"c_theta:\s*([\d.-]+)"
)

# ─── Serial ───────────────────────────────────────────────────────────────────
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

# ─── CSV ──────────────────────────────────────────────────────────────────────
os.makedirs("logs", exist_ok=True)
csv_filename = f"logs/{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.csv"
csv_file = open(csv_filename, mode="w", newline="", encoding="utf-8")
csv_writer = csv.writer(csv_file)
csv_writer.writerow(
    ["Timestamp", "x_err", "y_err", "x_out", "y_out", "a_theta", "b_theta", "c_theta"]
)

# ─── Plot Setup ───────────────────────────────────────────────────────────────
plt.ion()
fig = plt.figure(figsize=(12, 4))
fig.suptitle("Real-Time PID Tracker", fontsize=11, fontweight="bold")

ax_err = fig.add_subplot(111)
ax_out = ax_err.twinx()

# ── Error lines (left axis) ──
(line_x_err,) = ax_err.plot([], [], color="#2196F3", linewidth=0.8, label="x_err")
(line_y_err,) = ax_err.plot([], [], color="#F44336", linewidth=0.8, label="y_err")

# ── Output lines (right axis) ──
(line_x_out,) = ax_out.plot(
    [], [], color="#00BCD4", linewidth=1.0, linestyle="--", label="x_out"
)
(line_y_out,) = ax_out.plot(
    [], [], color="#FF9800", linewidth=1.0, linestyle="--", label="y_out"
)

# ── Axis limits ──
ax_err.set_xlim(0, TRAIL_LEN)
ax_err.set_ylim(-100, 100)
ax_out.set_ylim(-0.2, 0.2)

# ── Axis labels ──
ax_err.set_ylabel("error (x/y)", color="#2196F3")
ax_out.set_ylabel("out (PID)", color="#00BCD4")
ax_err.set_xlabel("Sample #")

ax_err.tick_params(axis="y", colors="#2196F3")
ax_out.tick_params(axis="y", colors="#00BCD4")

ax_err.grid(True, alpha=0.3)

# ── Legend ──
all_lines = [line_x_err, line_y_err, line_x_out, line_y_out]
all_labels = ["x_err", "y_err", "x_out", "y_out"]
ax_err.legend(all_lines, all_labels, fontsize=8, loc="upper left")

fig.subplots_adjust(top=0.85, bottom=0.18, left=0.08, right=0.92)

# ─── Rolling Buffers ──────────────────────────────────────────────────────────
buf_x_err = deque(maxlen=TRAIL_LEN)
buf_y_err = deque(maxlen=TRAIL_LEN)
buf_x_out = deque(maxlen=TRAIL_LEN)
buf_y_out = deque(maxlen=TRAIL_LEN)

# ─── Draw Throttle State ──────────────────────────────────────────────────────
last_draw = 0.0
sample_idx = 0


def update_plots():
    n = len(buf_x_err)
    xs = list(range(sample_idx - n, sample_idx))

    line_x_err.set_data(xs, list(buf_x_err))
    line_y_err.set_data(xs, list(buf_y_err))
    line_x_out.set_data(xs, list(buf_x_out))
    line_y_out.set_data(xs, list(buf_y_out))
    ax_err.set_xlim(sample_idx - TRAIL_LEN, sample_idx)

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

        x_e, y_e, x_o, y_o, a, b, c = match.groups()
        x_err_v = float(x_e)
        y_err_v = float(y_e)
        x_out_v = float(x_o)
        y_out_v = float(y_o)
        a_theta_v = float(a)
        b_theta_v = float(b)
        c_theta_v = float(c)

        # — Log to CSV (every sample, no throttle) —
        csv_writer.writerow(
            [
                time.time(),
                x_err_v,
                y_err_v,
                x_out_v,
                y_out_v,
                a_theta_v,
                b_theta_v,
                c_theta_v,
            ]
        )
        csv_file.flush()

        # — Update rolling buffers —
        buf_x_err.append(x_err_v)
        buf_y_err.append(y_err_v)
        buf_x_out.append(x_out_v)
        buf_y_out.append(y_out_v)

        sample_idx += 1

        # — Throttled redraw —
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
