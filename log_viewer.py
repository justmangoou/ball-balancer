import csv
import sys

import matplotlib.pyplot as plt
import matplotlib.widgets as widgets
import numpy as np

if len(sys.argv) < 2:
    print("Usage: python log_viewer.py logs/your_file.csv")
    sys.exit(1)

CSV_PATH = sys.argv[1]

# ─── Load CSV ─────────────────────────────────────────────────────────────────
timestamps, x_parc, y_parc, x_out, y_out = [], [], [], [], []

with open(CSV_PATH, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        timestamps.append(float(row["Timestamp"]))
        x_parc.append(float(row["x_parc"]))
        y_parc.append(float(row["y_parc"]))
        x_out.append(float(row["x_out"]))
        y_out.append(float(row["y_out"]))

timestamps = np.array(timestamps)
x_parc = np.array(x_parc)
y_parc = np.array(y_parc)
x_out = np.array(x_out)
y_out = np.array(y_out)

total = len(timestamps)
t_rel = timestamps - timestamps[0]  # relative seconds from start
print(f"Loaded {total} samples | duration: {t_rel[-1]:.1f}s | {CSV_PATH}")

# ─── Plot Setup ───────────────────────────────────────────────────────────────
plt.style.use("dark_background")
fig, ax_parc = plt.subplots(figsize=(14, 5))
fig.subplots_adjust(left=0.07, right=0.93, top=0.88, bottom=0.13)
fig.suptitle(f"Log Viewer — {CSV_PATH}", fontsize=11, fontweight="bold")

ax_out = ax_parc.twinx()

(line_x_parc,) = ax_parc.plot([], [], color="#2196F3", linewidth=0.8, label="x_parc")
(line_y_parc,) = ax_parc.plot([], [], color="#F44336", linewidth=0.8, label="y_parc")
(line_x_out,) = ax_out.plot(
    [], [], color="#00BCD4", linewidth=0.8, linestyle="--", label="x_out"
)
(line_y_out,) = ax_out.plot(
    [], [], color="#FF9800", linewidth=0.8, linestyle="--", label="y_out"
)

ax_parc.set_ylim(-100, 100)
ax_out.set_ylim(-0.3, 0.3)
ax_parc.set_ylabel("parc (setpoint)", color="#2196F3")
ax_out.set_ylabel("out (PID output)", color="#00BCD4")
ax_parc.set_xlabel("Time (s)")
ax_parc.grid(True, alpha=0.15)

lines = [line_x_parc, line_y_parc, line_x_out, line_y_out]
labels = ["x_parc", "y_parc", "x_out", "y_out"]
ax_parc.legend(lines, labels, fontsize=8, loc="upper left")

# ─── Sliders ──────────────────────────────────────────────────────────────────
WINDOW_DEFAULT = min(500, total)

ax_scroll = fig.add_axes([0.07, 0.07, 0.86, 0.025])
ax_window = fig.add_axes([0.07, 0.03, 0.86, 0.025])

slider_scroll = widgets.Slider(
    ax_scroll,
    "Scroll",
    0,
    max(1, total - WINDOW_DEFAULT),
    valinit=max(0, total - WINDOW_DEFAULT),
    valstep=1,
    color="#2196F3",
)
slider_window = widgets.Slider(
    ax_window, "Window", 50, total, valinit=WINDOW_DEFAULT, valstep=10, color="#444"
)


# ─── Render ───────────────────────────────────────────────────────────────────
def render(val=None):
    w = int(slider_window.val)
    start = int(slider_scroll.val)
    end = min(start + w, total)

    t_slice = t_rel[start:end]
    line_x_parc.set_data(t_slice, x_parc[start:end])
    line_y_parc.set_data(t_slice, y_parc[start:end])
    line_x_out.set_data(t_slice, x_out[start:end])
    line_y_out.set_data(t_slice, y_out[start:end])

    if len(t_slice):
        ax_parc.set_xlim(t_slice[0], t_slice[-1])

    # Update scroll range when window size changes
    slider_scroll.valmax = max(1, total - w)
    slider_scroll.ax.set_xlim(0, slider_scroll.valmax)

    fig.canvas.draw_idle()


slider_scroll.on_changed(render)
slider_window.on_changed(render)

render()
plt.show()
