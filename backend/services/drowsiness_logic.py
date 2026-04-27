# ==============================================================
# DROWSINESS LOGIC — Core Detection Engine
# ==============================================================
#
# Contains all drowsiness detection logic for the
# live camera + WebSocket pipeline.
#
# What this file does:
#   1. EAR Calculation    — Computes Eye Aspect Ratio from landmarks
#   2. EAR Smoothing      — Moving average to reduce noise
#   3. Eye State Machine   — Tracks open/closing/closed/drowsy states
#   4. Blink Filtering    — Separates normal blinks from drowsiness
#   5. Drowsiness %       — Sliding window percentage calculation
#   6. Status Classification — Maps percentage to Awake/Warning/Drowsy
#
# Architecture:
#   EARCalculator    → Pure math, stateless, reusable
#   EyeStateTracker  → Per-frame state machine with blink filtering
#   DrowsinessLogic  → High-level orchestrator combining everything
#
# ==============================================================

import sys
import os
from collections import deque
from typing import Optional

import numpy as np

# Add parent directory to path so we can import from config/ and models/
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from config.constants import (
    EAR_THRESHOLD,
    EAR_SMOOTHING_WINDOW,
    BLINK_MAX_FRAMES,
    DROWSY_MIN_CLOSED_FRAMES,
    REOPEN_DEBOUNCE_FRAMES,
    SLIDING_WINDOW_SIZE,
    AWAKE_MAX_PERCENT,
    WARNING_MAX_PERCENT,
    LEFT_EYE_INDICES,
    RIGHT_EYE_INDICES,
)
from models.detection_result import DetectionResult


# ═══════════════════════════════════════════════════════════════
# SECTION 1: EAR CALCULATOR (Stateless Math)
# ═══════════════════════════════════════════════════════════════
# The Eye Aspect Ratio (EAR) is a scalar value that represents
# how open or closed an eye is. It was introduced in the paper:
#   "Real-Time Eye Blink Detection using Facial Landmarks"
#   by Soukupová and Čech (2016)
#
# Formula:
#   EAR = (||p2 - p6|| + ||p3 - p5||) / (2 * ||p1 - p4||)
#
# Where:
#   p1 = outer corner      p4 = inner corner (horizontal)
#   p2 = upper lid point 1  p6 = lower lid point 1 (vertical pair 1)
#   p3 = upper lid point 2  p5 = lower lid point 2 (vertical pair 2)
#
# When the eye is open:  EAR ≈ 0.25 – 0.35
# When the eye is closed: EAR ≈ 0.05 – 0.15
# ═══════════════════════════════════════════════════════════════

class EARCalculator:
    """
    Computes the Eye Aspect Ratio (EAR) from MediaPipe face
    mesh landmarks. This class is stateless — it performs pure
    mathematical computation and can be reused across sessions.

    The EAR formula measures the vertical openness of the eye
    relative to its horizontal width. A lower EAR means the eye
    is more closed.

    Usage:
        calculator = EARCalculator()
        ear_value = calculator.calculate_ear(landmarks_list)
    """

    def __init__(self):
        """
        Initialize EAR calculator with eye landmark indices.
        These indices come from MediaPipe's 468-point face mesh.
        """
        # Landmark indices for left and right eyes
        # Order: [outer, upper1, upper2, inner, lower2, lower1]
        self.left_eye_indices = LEFT_EYE_INDICES
        self.right_eye_indices = RIGHT_EYE_INDICES

    @staticmethod
    def _landmark_to_array(landmark: dict) -> np.ndarray:
        """
        Convert a single landmark dictionary to a numpy array.

        MediaPipe returns landmarks as dicts with 'x', 'y', 'z' keys.
        We convert to numpy arrays for efficient distance calculation.

        Args:
            landmark (dict): {'x': float, 'y': float, 'z': float}

        Returns:
            np.ndarray: [x, y, z] as a 3D coordinate array
        """
        return np.array(
            [landmark["x"], landmark["y"], landmark["z"]],
            dtype=np.float64,
        )

    @staticmethod
    def _euclidean_distance(point1: np.ndarray, point2: np.ndarray) -> float:
        """
        Calculate the Euclidean distance between two 3D points.

        This is the straight-line distance formula:
            distance = sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)

        Args:
            point1 (np.ndarray): First point [x, y, z]
            point2 (np.ndarray): Second point [x, y, z]

        Returns:
            float: Distance between the two points
        """
        return float(np.linalg.norm(point1 - point2))

    def _compute_single_eye_ear(
        self, landmarks: list, eye_indices: list
    ) -> float:
        """
        Compute the EAR for a single eye using 6 landmark points.

        The 6 points define the eye shape:
            p1 (outer corner) ──── p4 (inner corner)   [horizontal]
                    p2 (upper1)    p3 (upper2)          [upper lid]
                    p6 (lower1)    p5 (lower2)          [lower lid]

        EAR = (vertical1 + vertical2) / (2 × horizontal)

        Args:
            landmarks (list): Full list of face landmarks (468 points)
            eye_indices (list): 6 indices for this eye's key points

        Returns:
            float: EAR value for this eye (0.0 if horizontal = 0)
        """
        # Extract the 6 key points for this eye
        points = [
            self._landmark_to_array(landmarks[idx])
            for idx in eye_indices
        ]

        # Calculate vertical distances (eye height)
        # Vertical pair 1: upper1 (p2) to lower1 (p6)
        vertical_dist_1 = self._euclidean_distance(points[1], points[5])

        # Vertical pair 2: upper2 (p3) to lower2 (p5)
        vertical_dist_2 = self._euclidean_distance(points[2], points[4])

        # Calculate horizontal distance (eye width)
        # Horizontal: outer corner (p1) to inner corner (p4)
        horizontal_dist = self._euclidean_distance(points[0], points[3])

        # Avoid division by zero (can happen with bad landmarks)
        if horizontal_dist < 1e-6:
            return 0.0

        # Apply the EAR formula
        ear = (vertical_dist_1 + vertical_dist_2) / (2.0 * horizontal_dist)
        return ear

    def calculate_ear(self, landmarks: list) -> float:
        """
        Calculate the average EAR across both eyes.

        We average left and right EAR because:
          - One eye might be partially occluded
          - Head tilt can affect one eye more than the other
          - Averaging gives a more robust overall measurement

        Args:
            landmarks (list): Full MediaPipe face landmarks (468 dicts)

        Returns:
            float: Average EAR of both eyes

        Example:
            >>> calculator = EARCalculator()
            >>> ear = calculator.calculate_ear(face_landmarks)
            >>> print(f"EAR: {ear:.4f}")
            EAR: 0.2847
        """
        left_ear = self._compute_single_eye_ear(
            landmarks, self.left_eye_indices
        )
        right_ear = self._compute_single_eye_ear(
            landmarks, self.right_eye_indices
        )

        # Average of both eyes for robustness
        average_ear = (left_ear + right_ear) / 2.0
        return average_ear


# ═══════════════════════════════════════════════════════════════
# SECTION 2: EYE STATE TRACKER (Stateful State Machine)
# ═══════════════════════════════════════════════════════════════
# This class implements a state machine that tracks eye closure
# over time. It distinguishes between:
#   - Normal blinks (short closures, ~100-400ms)
#   - Drowsy closures (sustained closures, >500ms)
#
# State transitions:
#   OPEN → CLOSING (EAR drops below threshold)
#   CLOSING → OPEN (reopened quickly = blink, counted & ignored)
#   CLOSING → CLOSED (stayed closed past blink duration)
#   CLOSED → DROWSY (sustained closure past drowsy threshold)
#   DROWSY → OPEN (reopened after debounce period)
# ═══════════════════════════════════════════════════════════════

class EyeStateTracker:
    """
    Tracks eye state across consecutive frames using a state machine.

    This is the heart of the blink filtering logic. It ensures that
    quick, natural blinks are NOT counted toward drowsiness, while
    sustained eye closures ARE flagged.

    One EyeStateTracker should be created per WebSocket connection
    (per driver session), since it maintains temporal state.

    Usage:
        tracker = EyeStateTracker()
        result = tracker.update(smoothed_ear=0.18)
        print(result)  # {'state': 'Closing', 'is_drowsy': False, ...}
    """

    # Possible eye states
    STATE_OPEN = "Open"
    STATE_CLOSING = "Closing"     # Just went below threshold (might be blink)
    STATE_CLOSED = "Closed"       # Past blink duration, not yet drowsy
    STATE_DROWSY = "Drowsy"       # Confirmed sustained closure

    def __init__(self):
        """Initialize counters and state to default (eyes open)."""

        # Current state of the state machine
        self._current_state: str = self.STATE_OPEN

        # Count of consecutive frames with eyes below threshold
        self._consecutive_closed: int = 0

        # Count of consecutive frames with eyes above threshold
        self._consecutive_open: int = 0

        # Total blinks detected in this session
        self._blink_count: int = 0

    def update(self, smoothed_ear: float) -> dict:
        """
        Process one frame's smoothed EAR value through the state machine.

        This is called once per frame. It updates internal counters
        and returns the current eye state information.

        Args:
            smoothed_ear (float): The noise-filtered EAR value

        Returns:
            dict: {
                'state': str,          # Current eye state label
                'is_drowsy': bool,     # Is this frame a drowsy frame?
                'closed_frames': int,  # Consecutive closed frame count
                'blink_count': int,    # Total blinks this session
            }
        """
        # Step 1: Determine if eyes are currently closed
        eyes_below_threshold = smoothed_ear < EAR_THRESHOLD

        # Track whether THIS specific frame is confirmed drowsy
        is_drowsy_frame = False

        # Step 2: State machine transition logic
        if eyes_below_threshold:
            # ── Eyes are CLOSED this frame ──
            self._consecutive_closed += 1
            self._consecutive_open = 0  # Reset open counter

            if self._consecutive_closed >= DROWSY_MIN_CLOSED_FRAMES:
                # DROWSY: Eyes closed for a dangerously long time
                # This is NOT a blink — this is genuine drowsiness
                self._current_state = self.STATE_DROWSY
                is_drowsy_frame = True

            elif self._consecutive_closed > BLINK_MAX_FRAMES:
                # CLOSED: Past normal blink duration, approaching drowsy
                # Still monitoring — might re-open or become drowsy
                self._current_state = self.STATE_CLOSED

            else:
                # CLOSING: Just started closing, could be a blink
                # Wait to see if it reopens quickly
                self._current_state = self.STATE_CLOSING

        else:
            # ── Eyes are OPEN this frame ──
            self._consecutive_open += 1

            # Apply debounce: require multiple open frames before reset
            # This prevents rapid flicker from resetting detection
            if self._consecutive_open >= REOPEN_DEBOUNCE_FRAMES:

                # Check if the previous closure was a normal blink
                if (
                    self._current_state == self.STATE_CLOSING
                    and self._consecutive_closed <= BLINK_MAX_FRAMES
                    and self._consecutive_closed >= 2  # At least 2 frames
                ):
                    # Yes, it was a blink! Count it but DON'T flag as drowsy
                    self._blink_count += 1

                # Reset closure counter after debounce
                self._consecutive_closed = 0
                self._current_state = self.STATE_OPEN

            # If still in debounce period, keep the current state
            # (don't reset yet — wait for enough open frames)

        return {
            "state": self._current_state,
            "is_drowsy": is_drowsy_frame,
            "closed_frames": self._consecutive_closed,
            "blink_count": self._blink_count,
        }

    def reset(self):
        """
        Reset the state machine to initial state.
        Call this when starting a new detection session.
        """
        self._current_state = self.STATE_OPEN
        self._consecutive_closed = 0
        self._consecutive_open = 0
        self._blink_count = 0


# ═══════════════════════════════════════════════════════════════
# SECTION 3: DROWSINESS LOGIC (Main Orchestrator)
# ═══════════════════════════════════════════════════════════════
# Top-level class that combines EAR calculation, smoothing, state
# tracking, and percentage calculation into a single API.
#
# Usage:
#   logic = DrowsinessLogic()
#   result = logic.process_ear(raw_ear_value)
#   # or
#   result = logic.process_landmarks(face_landmarks)
# ═══════════════════════════════════════════════════════════════

class DrowsinessLogic:
    """
    Main drowsiness detection engine.

    This class orchestrates:
      1. EAR computation from face landmarks
      2. EAR smoothing via moving average
      3. Eye state tracking with blink filtering
      4. Drowsiness percentage over a sliding window
      5. Human-readable status classification

    Create ONE instance per driver session / WebSocket connection.

    Integration guide:
        # In your WebSocket handler:
        logic = DrowsinessLogic()

        # Option A: If you have face landmarks from MediaPipe
        result = logic.process_landmarks(landmark_list)

        # Option B: If you already computed the EAR value
        result = logic.process_ear(raw_ear_value)

        # Send result to Flutter
        await websocket.send_json(result.to_dict())
    """

    def __init__(self):
        """Initialize all sub-components for a new session."""

        # EAR calculator (stateless, computes EAR from landmarks)
        self._ear_calculator = EARCalculator()

        # EAR smoothing buffer (moving average window)
        # Stores the last N raw EAR values for noise reduction
        self._ear_buffer: deque = deque(maxlen=EAR_SMOOTHING_WINDOW)

        # Eye state tracker (stateful, handles blink filtering)
        self._state_tracker = EyeStateTracker()

        # Sliding window for drowsiness percentage calculation
        # Each entry is True (drowsy frame) or False (not drowsy)
        self._drowsy_window: deque = deque(maxlen=SLIDING_WINDOW_SIZE)

    # ── Public API ─────────────────────────────────────────────

    def process_landmarks(self, landmarks: list) -> DetectionResult:
        """
        Full pipeline: landmarks → EAR → smoothing → detection → result.

        This is the primary method to call when you have raw face
        landmarks from MediaPipe's FaceLandmarker.

        Args:
            landmarks (list): List of 468 landmark dicts from MediaPipe
                              Each dict has {'x': float, 'y': float, 'z': float}

        Returns:
            DetectionResult: Complete detection output for this frame.

        Example:
            >>> logic = DrowsinessLogic()
            >>> result = logic.process_landmarks(face_landmarks)
            >>> print(result.status)       # "Awake"
            >>> print(result.to_dict())    # JSON-ready dict
        """
        # Step 1: Compute raw EAR from landmarks
        raw_ear = self._ear_calculator.calculate_ear(landmarks)

        # Step 2: Pass to the EAR processing pipeline
        return self.process_ear(raw_ear)

    def process_ear(self, raw_ear: float) -> DetectionResult:
        """
        Process a single raw EAR value through the full detection pipeline.

        Use this if you've already computed the EAR yourself, or if
        you're testing with synthetic EAR values.

        Pipeline:
          raw_ear → smooth → state machine → sliding window → classify

        Args:
            raw_ear (float): Raw EAR value (unsmoothed)

        Returns:
            DetectionResult: Complete detection output for this frame.

        Example:
            >>> logic = DrowsinessLogic()
            >>> result = logic.process_ear(0.18)  # Low EAR = eyes closing
            >>> print(result.eye_closed)  # True
        """
        # ── Step 1: Smooth the EAR ──
        smoothed_ear = self._smooth_ear(raw_ear)

        # ── Step 2: Determine if eyes are closed ──
        eye_closed = smoothed_ear < EAR_THRESHOLD

        # ── Step 3: Run through state machine ──
        state_result = self._state_tracker.update(smoothed_ear)

        # ── Step 4: Update sliding window ──
        self._drowsy_window.append(state_result["is_drowsy"])

        # ── Step 5: Calculate drowsiness percentage ──
        drowsiness_pct = self._calculate_drowsiness_percentage()

        # ── Step 6: Classify driver status ──
        status = self._classify_status(
            drowsiness_pct, state_result["state"]
        )

        # ── Step 7: Build and return the result ──
        return DetectionResult(
            ear=round(raw_ear, 4),
            smoothed_ear=round(smoothed_ear, 4),
            eye_closed=eye_closed,
            state=state_result["state"],
            is_drowsy=state_result["is_drowsy"],
            closed_eye_frames=state_result["closed_frames"],
            total_frames=len(self._drowsy_window),
            drowsiness_percentage=round(drowsiness_pct, 1),
            status=status,
            blink_count=state_result["blink_count"],
            error=None,
        )

    def reset(self):
        """
        Reset all detection state for a new session.

        Call this when:
          - A new WebSocket connection is established
          - The user restarts the detection session
          - You want to clear all historical data
        """
        self._ear_buffer.clear()
        self._state_tracker.reset()
        self._drowsy_window.clear()

    # ── Private Helper Methods ─────────────────────────────────

    def _smooth_ear(self, raw_ear: float) -> float:
        """
        Apply moving average smoothing to the raw EAR value.

        Why smooth?
          - MediaPipe landmarks can jitter frame-to-frame
          - Camera noise causes small EAR fluctuations
          - Smoothing prevents false positives from noise spikes

        The smoothing window size is configured in constants.py
        (default: 5 frames for a good balance of responsiveness
         and stability).

        Args:
            raw_ear (float): Unsmoothed EAR value from this frame

        Returns:
            float: Moving average of recent EAR values
        """
        # Add current EAR to the buffer
        self._ear_buffer.append(raw_ear)

        # Calculate the average of all values in the buffer
        smoothed = sum(self._ear_buffer) / len(self._ear_buffer)
        return smoothed

    def _calculate_drowsiness_percentage(self) -> float:
        """
        Calculate the drowsiness percentage over the sliding window.

        Formula:
            drowsiness_% = (confirmed_drowsy_frames / total_window_frames) × 100

        Important:
          - Only frames where is_drowsy=True count as drowsy
          - Normal blink frames are NOT counted as drowsy
          - The window size is fixed (default 60 frames ≈ 2 seconds)
          - Older frames automatically fall off as new ones are added

        Returns:
            float: Drowsiness percentage (0.0 to 100.0)
        """
        # Avoid division by zero when no frames processed yet
        if len(self._drowsy_window) == 0:
            return 0.0

        # Count how many frames in the window were confirmed drowsy
        drowsy_frame_count = sum(self._drowsy_window)

        # Calculate percentage
        percentage = (drowsy_frame_count / len(self._drowsy_window)) * 100.0
        return percentage

    @staticmethod
    def _classify_status(drowsiness_pct: float, eye_state: str) -> str:
        """
        Map the drowsiness percentage to a human-readable status label.

        Classification rules (configurable via constants.py):
          - 0% to 30%   → "Awake"    (driver is alert, green indicator)
          - 31% to 60%  → "Warning"  (driver is getting drowsy, yellow)
          - 61% to 100% → "Drowsy"   (driver needs immediate alert, red)

        Special case:
          - If eye_state is "Drowsy" from the state machine, we always
            return "Drowsy" regardless of percentage. This ensures
            instant response when sustained closure is detected.

        Args:
            drowsiness_pct (float): Current drowsiness percentage
            eye_state (str): Current state from the state machine

        Returns:
            str: One of "Awake", "Warning", "Drowsy"

        Note:
            This status string is displayed directly in the Flutter UI.
            Use it to control the color of the status indicator:
              "Awake"   → Green
              "Warning" → Yellow/Orange
              "Drowsy"  → Red + trigger alarm
        """
        # If the state machine says drowsy, override everything
        if eye_state == EyeStateTracker.STATE_DROWSY:
            return "Drowsy"

        # Otherwise, classify based on percentage thresholds
        if drowsiness_pct <= AWAKE_MAX_PERCENT:
            return "Awake"
        elif drowsiness_pct <= WARNING_MAX_PERCENT:
            return "Warning"
        else:
            return "Drowsy"


# ═══════════════════════════════════════════════════════════════
# SECTION 4: STANDALONE TEST / DEMO
# ═══════════════════════════════════════════════════════════════
# Run this file directly to see the drowsiness logic in action
# with simulated EAR values. No camera or MediaPipe needed!
#
# Usage:
#   python drowsiness_logic.py
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 60)
    print("  DROWSINESS LOGIC — Standalone Demo")
    print("=" * 60)
    print()

    # Create the detection engine
    logic = DrowsinessLogic()

    # Simulated EAR values representing a realistic driving session:
    # - Normal open eyes (~0.28-0.32)
    # - A quick blink (drops to ~0.12 for a few frames)
    # - A drowsy closure (drops to ~0.10 for many frames)
    # - Eyes reopen
    simulated_ear_values = (
        # Phase 1: Eyes open, driving normally (10 frames)
        [0.30, 0.29, 0.31, 0.28, 0.30, 0.29, 0.31, 0.30, 0.28, 0.30]
        # Phase 2: Normal blink (5 frames — should be filtered out)
        + [0.15, 0.10, 0.08, 0.12, 0.18]
        # Phase 3: Eyes reopen after blink (5 frames)
        + [0.28, 0.30, 0.29, 0.31, 0.30]
        # Phase 4: Drowsy closure begins (20 frames — genuine drowsiness)
        + [0.18, 0.14, 0.10, 0.08, 0.06, 0.05, 0.05, 0.04, 0.05, 0.05,
           0.04, 0.05, 0.05, 0.04, 0.05, 0.04, 0.05, 0.05, 0.04, 0.05]
        # Phase 5: Eyes reopen slowly (5 frames)
        + [0.12, 0.18, 0.24, 0.28, 0.30]
        # Phase 6: Normal driving resumes (10 frames)
        + [0.29, 0.31, 0.30, 0.28, 0.30, 0.29, 0.31, 0.30, 0.29, 0.30]
    )

    print(f"Simulating {len(simulated_ear_values)} frames...\n")
    print(f"{'Frame':>5} | {'Raw EAR':>8} | {'Smooth':>8} | {'Eyes':>6} | "
          f"{'State':>10} | {'Drowsy%':>8} | {'Status':>8} | {'Blinks':>6}")
    print("-" * 85)

    for i, ear in enumerate(simulated_ear_values):
        result = logic.process_ear(ear)
        print(
            f"{i+1:>5} | "
            f"{result.ear:>8.4f} | "
            f"{result.smoothed_ear:>8.4f} | "
            f"{'SHUT' if result.eye_closed else 'OPEN':>6} | "
            f"{result.state:>10} | "
            f"{result.drowsiness_percentage:>7.1f}% | "
            f"{result.status:>8} | "
            f"{result.blink_count:>6}"
        )

    print()
    print("=" * 60)
    print("  Demo complete!")
    print("=" * 60)
    print()
    print("Key observations:")
    print("  • Frames 11-15: Normal blink — detected and FILTERED OUT")
    print("  • Frames 21-40: Drowsy closure — correctly flagged as DROWSY")
    print("  • Blink count incremented only for genuine blinks")
    print("  • Drowsiness % rises only during sustained closures")
