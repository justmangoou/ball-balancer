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
timestamps = []
x_err, y_err = [], []
x_out, y_out = [], []

with open(CSV_PATH, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        timestamps.append(float(row["Timestamp"]))
        x_err.append(float(row["x_err"]))
        y_err.append(float(row["y_err"]))
        x_out.append(float(row["x_out"]))
        y_out.append(float(row["y_out"]))

timestamps = np.array(timestamps)
x_err = np.array(x_err)
y_err = np.array(y_err)
x_out = np.array(x_out)
y_out = np.array(y_out)

total = len(timestamps)
t_rel = timestamps - timestamps[0]  # relative seconds from start

print(f"Loaded {total} samples | duration: {t_rel[-1]:.1f}s | {CSV_PATH}")

# ─── Plot Setup ───────────────────────────────────────────────────────────────
plt.style.use("dark_background")
fig, ax_err = plt.subplots(figsize=(14, 6))
fig.subplots_adjust(left=0.07, right=0.86, top=0.88, bottom=0.18)
fig.suptitle(f"Log Viewer — {CSV_PATH}", fontsize=11, fontweight="bold")

ax_out = ax_err.twinx()  # right axis 1: PID output

# ── Error lines (left axis) ──
(line_x_err,) = ax_err.plot([], [], color="#2196F3", linewidth=0.9, label="x_err")
(line_y_err,) = ax_err.plot([], [], color="#F44336", linewidth=0.9, label="y_err")

# ── Output lines (right axis 1) ──
(line_x_out,) = ax_out.plot(
    [], [], color="#00BCD4", linewidth=0.8, linestyle="--", label="x_out"
)
(line_y_out,) = ax_out.plot(
    [], [], color="#FF9800", linewidth=0.8, linestyle="--", label="y_out"
)


# ── Axis labels & limits ──
ax_err.set_ylabel("error (x/y)", color="#2196F3")
ax_out.set_ylabel("out (PID)", color="#00BCD4")
ax_err.set_xlabel("Time (s)")

ax_err.set_ylim(-100, 100)
ax_out.set_ylim(-0.2, 0.2)

ax_err.tick_params(axis="y", colors="#2196F3")
ax_out.tick_params(axis="y", colors="#00BCD4")

ax_err.grid(True, alpha=0.15)

# ── Legend (all series) ──
all_lines = [
    line_x_err,
    line_y_err,
    line_x_out,
    line_y_out,
]
all_labels = ["x_err", "y_err", "x_out", "y_out"]
ax_err.legend(all_lines, all_labels, fontsize=8, loc="upper left")

# ─── Sliders ──────────────────────────────────────────────────────────────────
WINDOW_DEFAULT = min(500, total)

ax_scroll = fig.add_axes([0.07, 0.10, 0.79, 0.025])
ax_window = fig.add_axes([0.07, 0.06, 0.79, 0.025])

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
    ax_window,
    "Window",
    50,
    total,
    valinit=WINDOW_DEFAULT,
    valstep=10,
    color="#444",
)


# ─── Render ───────────────────────────────────────────────────────────────────
def render(val=None):
    w = int(slider_window.val)
    start = int(slider_scroll.val)
    end = min(start + w, total)
    t_sl = t_rel[start:end]

    line_x_err.set_data(t_sl, x_err[start:end])
    line_y_err.set_data(t_sl, y_err[start:end])
    line_x_out.set_data(t_sl, x_out[start:end])
    line_y_out.set_data(t_sl, y_out[start:end])

    if len(t_sl):
        ax_err.set_xlim(t_sl[0], t_sl[-1])

    # Keep scroll range in sync with window size
    slider_scroll.valmax = max(1, total - w)
    slider_scroll.ax.set_xlim(0, slider_scroll.valmax)

    fig.canvas.draw_idle()


slider_scroll.on_changed(render)
slider_window.on_changed(render)
render()
plt.show()
