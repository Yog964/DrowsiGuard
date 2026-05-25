import base64
import cv2
import numpy as np
import mediapipe as mp
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import json
import logging

from services.drowsiness_logic import DrowsinessLogic
from models.detection_result import DetectionResult

# Import API route modules
from routes.auth import router as auth_router
from routes.user import router as user_router
from routes.history import router as history_router

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DrowsiGuard Backend")

# ── CORS Middleware (allow Flutter app to make HTTP requests) ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register API Routers ──
app.include_router(auth_router)
app.include_router(user_router)
app.include_router(history_router)

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Initialize Drowsiness Detection Logic
# Note: In a production app, you might want to create one per connection
# but for a single-user demo, a global instance is often used or created in the handler.
drowsiness_engine = DrowsinessLogic()

@app.get("/")
async def root():
    return {"message": "DrowsiGuard Backend is running"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("Client connected via WebSocket")
    
    # Reset engine for new session
    drowsiness_engine.reset()
    
    try:
        while True:
            try:
                # Receive data from Flutter
                data = await websocket.receive_text()
                message = json.loads(data)
                
                if 'frame' not in message:
                    continue
                    
                # 1. Decode base64 frame
                header, encoded = message['frame'].split(",", 1) if "," in message['frame'] else (None, message['frame'])
                image_bytes = base64.b64decode(encoded)
                nparr = np.frombuffer(image_bytes, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if frame is None:
                    await websocket.send_json({"error": "Failed to decode image"})
                    continue
                    
                # 2. Process with MediaPipe
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = face_mesh.process(rgb_frame)
                
                if not results.multi_face_landmarks:
                    # No face detected — send complete response
                    no_face = DetectionResult.no_face()
                    await websocket.send_json(no_face.to_dict())
                    continue
                    
                # 3. Extract landmarks
                landmarks = []
                for landmark in results.multi_face_landmarks[0].landmark:
                    landmarks.append({
                        "x": landmark.x,
                        "y": landmark.y,
                        "z": landmark.z
                    })
                    
                # 4. Run Drowsiness Logic
                detection_result = drowsiness_engine.process_landmarks(landmarks)
                
                # Log detection result for debugging
                logger.info(
                    f"Frame — EAR: {detection_result.ear:.4f}, "
                    f"MAR: {detection_result.mar:.4f}, "
                    f"State: {detection_result.state}, "
                    f"Yawn: {detection_result.is_yawning}, "
                    f"Status: {detection_result.status}, "
                    f"Drowsy%: {detection_result.drowsiness_percentage:.1f}%"
                )
                
                # 5. Send result back to Flutter
                await websocket.send_json(detection_result.to_dict())
                
            except WebSocketDisconnect:
                # Re-raise to the outer block to break the loop correctly
                raise
            except Exception as inner_e:
                import traceback
                logger.error(f"Error processing frame: {inner_e}")
                logger.error(traceback.format_exc())
                try:
                    await websocket.send_json({"error": "Backend processing error"})
                except Exception:
                    pass
                
    except WebSocketDisconnect:
        logger.info("Client disconnected")

if __name__ == "__main__":
    # Run the server on all interfaces so mobile devices can connect
    uvicorn.run(app, host="0.0.0.0", port=8000)
