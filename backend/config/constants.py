# ==============================================================
# CONSTANTS — Central Configuration for Drowsiness Detection
# ==============================================================
#
# All tunable parameters used by the drowsiness detection logic.
#
# IMPORTANT: The Flutter camera service captures frames at ~5 FPS
# (200ms interval). All frame-based constants are tuned for 5 FPS.
#
# ==============================================================


# ─────────────────────────────────────────────────────────────
# EAR (Eye Aspect Ratio) Thresholds
# ─────────────────────────────────────────────────────────────

# EAR value below which the eyes are considered "closed".
# Typical open-eye EAR is 0.25–0.35; closed is 0.05–0.15.
# 0.21 is a tuned middle ground to avoid false positives
# from squinting or relaxed eyes.
EAR_THRESHOLD: float = 0.17

# Number of recent raw EAR values to average (moving average).
# This smooths out frame-to-frame jitter caused by landmark
# detection noise or slight head movements.
#   Higher = smoother but slower to react
#   Lower  = faster reaction but more noise
EAR_SMOOTHING_WINDOW: int = 3


# ─────────────────────────────────────────────────────────────
# Blink vs Drowsiness Classification
# ─────────────────────────────────────────────────────────────

# Maximum number of consecutive closed-eye frames that still
# counts as a "normal blink" (ignored for drowsiness).
# A normal blink lasts ~100–400ms → ~1–2 frames at 5 FPS.
# We use 2 frames as the cutoff.
BLINK_MAX_FRAMES: int = 2

# Minimum number of consecutive closed-eye frames required
# before the system classifies it as a "drowsy event".
# 4 frames ≈ 0.8 seconds at 5 FPS — a realistic threshold
# for genuine drowsiness vs intentional eye closure.
DROWSY_MIN_CLOSED_FRAMES: int = 4

# After eyes re-open, the system waits this many consecutive
# open frames before resetting the closure counter.
# This prevents rapid open/close flickering from resetting
# a genuine drowsy detection prematurely.
REOPEN_DEBOUNCE_FRAMES: int = 2


# ─────────────────────────────────────────────────────────────
# Drowsiness Percentage Calculation
# ─────────────────────────────────────────────────────────────

# Size of the sliding window (in frames) used to calculate
# the drowsiness percentage over recent history.
# 15 frames ≈ 3 seconds of history at 5 FPS.
# Only frames classified as "confirmed drowsy" count toward
# the percentage — blink frames are excluded.
SLIDING_WINDOW_SIZE: int = 15


# ─────────────────────────────────────────────────────────────
# Status Classification Thresholds (percentage-based)
# ─────────────────────────────────────────────────────────────
# These thresholds map the drowsiness percentage to a
# human-readable status label for the Flutter UI.

# 0.0% to this value → "Awake" (green indicator)
AWAKE_MAX_PERCENT: float = 35.0

# Above AWAKE_MAX_PERCENT to this value → "Warning" (yellow)
WARNING_MAX_PERCENT: float = 60.0

# Above WARNING_MAX_PERCENT → "Drowsy" (red alert)
# No constant needed; anything above WARNING_MAX_PERCENT is Drowsy.


# ─────────────────────────────────────────────────────────────
# MAR (Mouth Aspect Ratio) — Yawn Detection
# ─────────────────────────────────────────────────────────────
# Yawning is a strong indicator of fatigue. MAR measures how
# "open" the mouth is, similar to how EAR measures eye openness.
#
# Formula (same structure as EAR):
#   MAR = (vertical1 + vertical2 + vertical3) / (2 * horizontal)
#
# Typical values:
#   Mouth closed / talking:  MAR ≈ 0.3 – 0.6
#   Yawning (wide open):     MAR ≈ 0.7 – 1.2

# MAR value above which the mouth is considered "open for yawn".
# Raised to 0.95 — speech (even loud) rarely exceeds MAR 0.9.
# A genuine wide-open yawn reliably reaches 0.95–1.2.
MAR_THRESHOLD: float = 0.98

# Minimum consecutive frames the mouth must stay above MAR_THRESHOLD
# to be classified as a genuine yawn.
# Reduced to 4 frames ≈ 0.8 seconds at 5 FPS for faster response.
YAWN_MIN_FRAMES: int = 4

# Number of recent raw MAR values to average (moving average).
# Keeps the yawn detection stable against landmark jitter.
MAR_SMOOTHING_WINDOW: int = 2


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

# Mouth landmark indices for MAR (Mouth Aspect Ratio) computation.
# Selected from MediaPipe's 468-point face mesh.
#
# Layout (8 points):
#   [left_corner, right_corner,         ← horizontal pair
#    upper_lip_top, lower_lip_bottom,   ← vertical pair 1 (centre)
#    upper_outer_1, lower_outer_1,      ← vertical pair 2 (left side)
#    upper_outer_2, lower_outer_2]      ← vertical pair 3 (right side)
#
# These 8 points give a robust measurement of mouth openness
# that holds up even with slight head tilts.
MOUTH_INDICES: list = [61, 291, 0, 17, 78, 308, 13, 14]
