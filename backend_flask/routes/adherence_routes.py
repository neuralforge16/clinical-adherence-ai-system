from flask import Blueprint, request, jsonify
from models.adherence_log import AdherenceLog
from extensions import db

adherence_bp = Blueprint("adherence", __name__)

# ✅ CREATE LOG (THIS FIXES YOUR BUTTON ISSUE)
@adherence_bp.route("/", methods=["POST"])
def log_dose():
    data = request.json

    new_log = AdherenceLog(
        patient_id=data["patient_id"],
        medication_id=data["medication_id"],
        status=data["status"],
    )

    db.session.add(new_log)
    db.session.commit()

    return jsonify({"message": "Dose logged successfully"}), 201


# ✅ GET ALL LOGS FOR PATIENT (THIS FIXES ANALYTICS + LOGS UI)
@adherence_bp.route("/patient/<int:patient_id>", methods=["GET"])
def get_patient_logs(patient_id):

    logs = AdherenceLog.query.filter_by(patient_id=patient_id).all()

    return jsonify([
        {
            "id": log.id,
            "patient_id": log.patient_id,
            "medication_id": log.medication_id,
            "status": log.status,
            "timestamp": log.timestamp.isoformat(),
        }
        for log in logs
    ])

# ✅ GET LOGS FOR A SPECIFIC MEDICATION
@adherence_bp.route("/medication/<int:med_id>", methods=["GET"])
def get_medication_logs(med_id):

    logs = AdherenceLog.query.filter_by(medication_id=med_id).all()

    return jsonify([
        {
            "id": log.id,
            "patient_id": log.patient_id,
            "medication_id": log.medication_id,
            "status": log.status,
            "timestamp": log.timestamp.isoformat(),
        }
        for log in logs
    ])