from fastapi import FastAPI, UploadFile, File
from sqlalchemy.orm import Session
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
import os
import uvicorn

from db import SessionLocal, engine
from model import Base, Sales
from utilites import clean_csv, generate_analytics

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/upload/")
async def upload_csv(file: UploadFile = File(...)):
    db: Session = SessionLocal()

    try:
        print("File received:", file.filename)

        df = clean_csv(file.file)
        print(df.head())

        records = df.to_dict(orient="records")

        db.bulk_insert_mappings(Sales, records)
        db.commit()

        analytics = generate_analytics(df)

        return {
            "message": "Upload + Analysis successful",
            "rows_inserted": len(records),
            "analytics": analytics
        }

    except Exception as e:
        db.rollback()
        print("Error:", str(e))
        return {"error": str(e)}

    finally:
        db.close()

@app.get("/analytics/")
def get_analytics():
    db: Session = SessionLocal()

    try:
        data = db.query(Sales).all()

        if not data:
            return {"message": "No data available"}

        df = pd.DataFrame([{
            "product_name": d.product_name,
            "amount": d.amount,
            "date": d.date,
            "buyer": d.buyer
        } for d in data])

        analytics = generate_analytics(df)

        return analytics

    except Exception as e:
        print("Error:", str(e))
        return {"error": str(e)}

    finally:
        db.close()

@app.get("/")
def home():
    return {"status": "API running"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    uvicorn.run(app, host="0.0.0.0", port=port)