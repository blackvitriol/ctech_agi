# AI Realtime Agent: Flutter Web + FastAPI + WebRTC + LangChain

Single FastAPI server that ingests text, audio, video (including screen share) from a Flutter Web frontend via WebRTC and routes results through an AI pipeline (LLM + CV). The frontend can toggle processing modes (detection, classification, segmentation, transcription) at runtime.

## Project Structure

```
AI/
├── flutter_frontend/
│   ├── lib/
│   │   ├── pages/
│   │   │   └── ai_interface.dart        # UI to connect, chat, and control processing
│   │   ├── services/
│   │   │   ├── webrtc.dart              # WebRTC peer + datachannel
│   │   │   └── websocket_service.dart   # Signaling (WS)
│   │   └── ...
│   └── ...
├── python_backend/
│   ├── main.py                          # FastAPI app (WS + HTTP)
│   ├── routes.py                        # REST + WS routers
│   ├── webrtc/
│   │   ├── webrtc_service.py            # aiortc PC + media processing hooks
│   │   ├── websocket_handler.py         # WS signaling/room mgmt
│   │   └── connection_manager.py        # WS connections/rooms
│   ├── services/
│   │   └── server_config.py             # config management
│   ├── views/                           # html dashboards
│   └── requirements.txt
└── README.md
```

## Architecture Overview

```
Flutter (Web)
  ├─ WebRTC (audio/video + optional screen)
  ├─ DataChannel (text + processing_config JSON)
  └─ WebSocket signaling  ───────────────▶  FastAPI /ws/{room}
                                            ├─ aiortc RTCPeerConnection (server-as-peer)
                                            │   ├─ AudioTrack ▶ STT ▶ LLM
                                            │   └─ VideoTrack ▶ CV (detect/classify/segment) ▶ overlay
                                            └─ Results back via DataChannel + processed video track
```

Key points:

- Server acts as a WebRTC peer (aiortc) to receive media for processing.
- Text can be sent over the DataChannel or a REST endpoint.
- Processing modes are toggled by sending a `processing_config` message over the DataChannel.

## Quick Start (Windows CMD)

Backend

```
cd python_backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
set OPENAI_API_KEY=your_key_here
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Frontend (Flutter Web)

```
cd flutter_frontend
flutter pub get
flutter run -d chrome
```

## API Surfaces

WebSocket (signaling/control)

- `WS /ws/{room_id}`: join/leave, exchange SDP/ICE, send control messages.

HTTP (optional/fallback)

- `GET /health` – liveness
- `GET /info` – server info
- `POST /text` – send text payloads if not using DataChannel
- `POST /rtc/offer` – server-as-peer SDP exchange (returns answer)

DataChannel (preferred for realtime control)

- `processing_config` messages to enable/disable features at runtime
- arbitrary chat text messages for LLM

Example `processing_config` payload

```
{
  "type": "config",
  "video": {
    "detection": true,
    "classification": true,
    "segmentation": true,
    "labels": ["person", "car"]
  },
  "audio": {
    "stt": true,
    "language": "en"
  },
  "text": {
    "llm_model": "gpt-4o-mini",
    "system_prompt": "You are a helpful vision+audio assistant."
  }
}
```

## AI Processing Pipeline

- Audio: VAD (optional) → STT (Whisper/faster-whisper) → LLM
- Video: selectable processors (any combination)
  - Object Detection (e.g., YOLOv8/ONNXRuntime)
  - Image Classification (e.g., MobileNet/ResNet)
  - Segmentation (e.g., DeepLab/YOLO-Seg)
- Text: LangChain pipeline for chat, summarization, tool use
- Results: returned over DataChannel and/or as overlays on the server-returned video track

## Configuration

- CORS open by default (tighten for prod)
- TURN/STUN recommended for non-LAN networks
- Secrets via environment (e.g., `OPENAI_API_KEY`)

## Roadmap

- [ ] Server-as-peer WebRTC flow (aiortc) with `/rtc/offer`
- [ ] DataChannel handlers (chat, `processing_config`)
- [ ] Video processors: detection, classification, segmentation (toggleable)
- [ ] Audio STT + optional translation
- [ ] LangChain LLM integration (+ model config)
- [ ] Screen share capture in Flutter (getDisplayMedia) and route to server
- [ ] Frontend UI toggles for processing modes with live status
- [ ] Metrics overlay (FPS, latency) and `/webrtc/stats`

## Troubleshooting

- Browser permissions: camera/mic/screen
- Firewall/ports: 8000 TCP for API/WS
- For GPU CV models, ensure CUDA/cuDNN or use CPU/ONNXRuntime

## License

MIT
"# ctech_agi" 
