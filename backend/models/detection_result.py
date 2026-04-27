# ==============================================================
# DETECTION RESULT — Data Model for Drowsiness Detection Output
# ==============================================================
#
# This file defines the DetectionResult class, which structures
# the output of the drowsiness detection logic into a clean,
# consistent format.
#
# The model is designed to:
#   1. Be returned by DrowsinessLogic after each frame analysis
#   2. Be serialized to JSON and sent over WebSocket to Flutter
#   3. Match the Flutter-side DetectionResultModel exactly
#
# ==============================================================

from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class DetectionResult:
    """
    Structured output from one frame of drowsiness analysis.

    Attributes:
        ear (float):
            Raw EAR value computed from eye landmarks.
            Typical range: 0.0 (fully closed) to ~0.4 (wide open).

        smoothed_ear (float):
            Moving-average smoothed EAR value.
            Used for actual decision making to reduce noise.

        eye_closed (bool):
            Whether the smoothed EAR is below the threshold.
            True = eyes are considered closed.

        state (str):
            Current eye state from the state machine.
            One of: "Open", "Closing", "Closed", "Drowsy"

        is_drowsy (bool):
            Whether THIS specific frame is a confirmed drowsy frame.
            True only when eyes have been closed for sustained duration.

        closed_eye_frames (int):
            Number of consecutive frames the eyes have been closed.
            Resets when eyes re-open after debounce period.

        total_frames (int):
            Total number of frames in the sliding analysis window.
            Used as the denominator for drowsiness percentage.

        drowsiness_percentage (float):
            Percentage of recent frames classified as drowsy.
            Formula: (drowsy_frames / window_size) * 100

        status (str):
            Human-readable driver status label for the UI.
            One of: "Awake", "Warning", "Drowsy", "No Face Detected"

        blink_count (int):
            Total number of normal blinks detected in this session.
            Blinks are eye closures shorter than BLINK_MAX_FRAMES.

        error (Optional[str]):
            Error message if something went wrong (e.g., no face).
            None when detection is working normally.
    """

    # --- Core EAR values ---
    ear: float = 0.0
    smoothed_ear: float = 0.0

    # --- Eye state ---
    eye_closed: bool = False
    state: str = "Open"
    is_drowsy: bool = False

    # --- Frame counters ---
    closed_eye_frames: int = 0
    total_frames: int = 0

    # --- Computed metrics ---
    drowsiness_percentage: float = 0.0
    status: str = "Awake"

    # --- Informational ---
    blink_count: int = 0

    # --- Error handling ---
    error: Optional[str] = None

    def to_dict(self) -> dict:
        """
        Convert the result to a dictionary for JSON serialization.

        This is sent over WebSocket to the Flutter app, so the keys
        must match what the Flutter DetectionResultModel expects.

        Returns:
            dict: All detection fields as a flat dictionary.

        Example output:
            {
                "ear": 0.21,
                "smoothed_ear": 0.2234,
                "eye_closed": true,
                "state": "Drowsy",
                "is_drowsy": true,
                "closed_eye_frames": 42,
                "total_frames": 60,
                "drowsiness_percentage": 60.0,
                "status": "Warning",
                "blink_count": 5,
                "error": null
            }
        """
        return asdict(self)

    @staticmethod
    def no_face() -> "DetectionResult":
        """
        Factory method for the 'No Face Detected' scenario.

        Called when MediaPipe cannot find any face landmarks in
        the current frame. Returns a safe default result with
        the status set to "No Face Detected".

        Returns:
            DetectionResult: A result indicating no face was found.
        """
        return DetectionResult(
            ear=0.0,
            smoothed_ear=0.0,
            eye_closed=False,
            state="No Face",
            is_drowsy=False,
            closed_eye_frames=0,
            total_frames=0,
            drowsiness_percentage=0.0,
            status="No Face Detected",
            blink_count=0,
            error="no_face_detected",
        )

    def __repr__(self) -> str:
        """Readable string representation for debugging."""
        return (
            f"DetectionResult("
            f"ear={self.ear:.4f}, "
            f"status='{self.status}', "
            f"drowsiness={self.drowsiness_percentage:.1f}%, "
            f"blinks={self.blink_count})"
        )
