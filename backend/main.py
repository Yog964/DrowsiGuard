import base64
import cv2
import numpy as np
import mediapipe as mp
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uvicorn
import json
import logging

from services.drowsiness_logic import DrowsinessLogic

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DrowsiGuard Backend")

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
                # No face detected
                response = {
                    "error": "No face detected",
                    "status": "Warning",
                    "state": "Unknown",
                    "drowsiness_percentage": 0,
                    "ear": 0
                }
                await websocket.send_json(response)
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
            
            # 5. Send result back to Flutter
            await websocket.send_json(detection_result.to_dict())
            
    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"Error in websocket loop: {e}")
        await websocket.close()

if __name__ == "__main__":
    # Run the server on all interfaces so mobile devices can connect
    uvicorn.run(app, host="0.0.0.0", port=8000)
