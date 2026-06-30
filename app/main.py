import os
import numpy as np
from fastapi import FastAPI, HTTPException, Depends, Header, Request
from pydantic import BaseModel
from app.classifier import classify_batch
from app.models import Prediction, SessionLocal

app = FastAPI(title="PixelWise Digit Classifier")

# --- Rate Limiter Setup (Spam-Schutz) ---
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.middleware import SlowAPIMiddleware

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)

# --- Pydantic Models (Daten-Validierung) ---
class ClassifyRequest(BaseModel):
    pixels: list[list[int]]

class ClassifyResponse(BaseModel):
    prediction: str
    confidence: float
    scores: dict[str, float]

# --- Security Dependency (Passwort-Schutz) ---
def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != os.getenv("SECRET_API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API key")

# --- Endpoints ---
@app.get("/health")
def health():
    return {"status": "ok", "model_version": "v1"}

@app.get("/results")
def results():
    db = SessionLocal()
    rows = (db.query(Prediction)
            .order_by(Prediction.created_at.desc())
            .limit(20).all())
    db.close()
    return {"results": [
        {"id": r.id,
         "prediction": r.prediction,
         "confidence": r.confidence,
         "model_version": r.model_version,
         "created_at": r.created_at.isoformat()}
        for r in rows
    ]}

@app.post("/classify", response_model=ClassifyResponse, dependencies=[Depends(verify_api_key)])
@limiter.limit("30/minute")
def classify(request: Request, req: ClassifyRequest):
    try:
        # Bild konvertieren und Batch-Dimension hinzufügen
        arr = np.array(req.pixels, dtype=np.uint8)[np.newaxis]
        
        # Inferenz ausführen
        result = classify_batch(arr)[0]
        
        # Datenbank-Session öffnen und Eintrag speichern
        db = SessionLocal()
        db.add(Prediction(
            prediction=result["prediction"],
            confidence=result["confidence"],
            model_version="v1"
        ))
        db.commit()
        db.close()
        
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal Server Error")
