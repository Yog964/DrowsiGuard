# ==============================================================
# CONSTANTS — Central Configuration for Drowsiness Detection
# ==============================================================
#
# All tunable parameters used by the drowsiness detection logic.
#
# All timing values assume the camera runs at ~30 FPS.
# Adjust the frame-based constants if your FPS is different.
#
# ==============================================================


# ─────────────────────────────────────────────────────────────
# EAR (Eye Aspect Ratio) Thresholds
# ─────────────────────────────────────────────────────────────

# EAR value below which the eyes are considered "closed".
# Typical open-eye EAR is 0.25–0.35; closed is 0.05–0.15.
# 0.21 is a tuned middle ground to avoid false positives
# from squinting or relaxed eyes.
EAR_THRESHOLD: float = 0.21

# Number of recent raw EAR values to average (moving average).
# This smooths out frame-to-frame jitter caused by landmark
# detection noise or slight head movements.
#   Higher = smoother but slower to react
#   Lower  = faster reaction but more noise
EAR_SMOOTHING_WINDOW: int = 5


# ─────────────────────────────────────────────────────────────
# Blink vs Drowsiness Classification
# ─────────────────────────────────────────────────────────────

# Maximum number of consecutive closed-eye frames that still
# counts as a "normal blink" (ignored for drowsiness).
# A normal blink lasts ~100–400ms → ~3–12 frames at 30 FPS.
# We use 8 frames as the cutoff.
BLINK_MAX_FRAMES: int = 8

# Minimum number of consecutive closed-eye frames required
# before the system classifies it as a "drowsy event".
# 15 frames ≈ 0.5 seconds at 30 FPS — a realistic threshold
# for genuine drowsiness vs intentional eye closure.
DROWSY_MIN_CLOSED_FRAMES: int = 15

# After eyes re-open, the system waits this many consecutive
# open frames before resetting the closure counter.
# This prevents rapid open/close flickering from resetting
# a genuine drowsy detection prematurely.
REOPEN_DEBOUNCE_FRAMES: int = 3


# ─────────────────────────────────────────────────────────────
# Drowsiness Percentage Calculation
# ─────────────────────────────────────────────────────────────

# Size of the sliding window (in frames) used to calculate
# the drowsiness percentage over recent history.
# 60 frames ≈ 2 seconds of history at 30 FPS.
# Only frames classified as "confirmed drowsy" count toward
# the percentage — blink frames are excluded.
SLIDING_WINDOW_SIZE: int = 60


# ─────────────────────────────────────────────────────────────
# Status Classification Thresholds (percentage-based)
# ─────────────────────────────────────────────────────────────
# These thresholds map the drowsiness percentage to a
# human-readable status label for the Flutter UI.

# 0.0% to this value → "Awake" (green indicator)
AWAKE_MAX_PERCENT: float = 30.0

# Above AWAKE_MAX_PERCENT to this value → "Warning" (yellow)
WARNING_MAX_PERCENT: float = 60.0

# Above WARNING_MAX_PERCENT → "Drowsy" (red alert)
# No constant needed; anything above WARNING_MAX_PERCENT is Drowsy.


# ─────────────────────────────────────────────────────────────
# Server Configuration
# ─────────────────────────────────────────────────────────────

# Host and port for the FastAPI backend server.
# "0.0.0.0" allows connections from the Flutter app on the
# same network (not just localhost).
HOST: str = "0.0.0.0"
PORT: int = 8000


# ─────────────────────────────────────────────────────────────
# MediaPipe Face Mesh Landmark Indices
# ─────────────────────────────────────────────────────────────
# These are the specific landmark indices from MediaPipe's
# 468-point face mesh used to compute EAR for each eye.
# Order: [outer, upper1, upper2, inner, lower2, lower1]

LEFT_EYE_INDICES: list = [362, 385, 387, 263, 373, 380]
RIGHT_EYE_INDICES: list = [33, 160, 158, 133, 153, 144]
