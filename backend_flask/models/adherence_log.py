from extensions import db
from datetime import datetime

class AdherenceLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    patient_id = db.Column(db.Integer, nullable=False)
    medication_id = db.Column(db.Integer, nullable=False)

    status = db.Column(db.String(20))  # taken / missed / late

    timestamp = db.Column(db.DateTime, default=datetime.utcnow)