import json
from datetime import datetime, date, timedelta
from flask import Blueprint, request, jsonify
from models.medication import Medication
from models.adherence_log import AdherenceLog
from extensions import db

medication_bp = Blueprint("medications", __name__)


# ── GET ALL medications ────────────────────────────────────────────────────────
@medication_bp.route("/", methods=["GET"])
def get_medications():
    medications = Medication.query.all()
    return jsonify([m.to_dict() for m in medications])


# ── GET medications for ONE patient ───────────────────────────────────────────
@medication_bp.route("/patient/<int:patient_id>", methods=["GET"])
def get_patient_medications(patient_id):
    medications = Medication.query.filter_by(patient_id=patient_id).all()
    return jsonify([m.to_dict() for m in medications])


# ── TODAY'S SCHEDULE for a patient ────────────────────────────────────────────
# Returns a list of expected dose events for today based on active prescriptions.
# Each entry has: medication_id, medication_name, dosage, scheduled_time,
#                 status (pending/taken/missed), log_id (if logged)
@medication_bp.route("/today-schedule/<int:patient_id>", methods=["GET"])
def today_schedule(patient_id):
    today      = date.today()
    today_str  = today.isoformat()
    now        = datetime.now()

    # Get all active medications for this patient
    medications = Medication.query.filter_by(patient_id=patient_id).all()
    active      = [m for m in medications if m.is_active()]

    # Get all logs for this patient today
    start_of_day = datetime.combine(today, datetime.min.time())
    end_of_day   = datetime.combine(today, datetime.max.time())

    today_logs = AdherenceLog.query.filter(
        AdherenceLog.patient_id == patient_id,
        AdherenceLog.timestamp  >= start_of_day,
        AdherenceLog.timestamp  <= end_of_day,
    ).all()

    # Build a lookup: medication_id -> list of logs today
    log_lookup = {}
    for log in today_logs:
        if log.medication_id not in log_lookup:
            log_lookup[log.medication_id] = []
        log_lookup[log.medication_id].append(log)

    schedule = []

    for med in active:
        times = med.get_schedule_times()

        for time_str in times:
            try:
                hour, minute = [int(x) for x in time_str.split(":")]
            except Exception:
                hour, minute = 8, 0

            scheduled_dt = datetime(today.year, today.month, today.day,
                                    hour, minute)

            # Find matching log for this medication at this scheduled time
            # Match window: within 2 hours of scheduled time
            matched_log = None
            for log in log_lookup.get(med.id, []):
                diff = abs((log.timestamp - scheduled_dt).total_seconds())
                if diff <= 7200:  # 2 hour window
                    matched_log = log
                    break

            if matched_log:
                status = matched_log.status
                log_id = matched_log.id
            elif scheduled_dt < now:
                # Scheduled time has passed with no log — auto-missed
                status = "missed"
                log_id = None
            else:
                # Still pending
                status = "pending"
                log_id = None

            schedule.append({
                "medication_id":   med.id,
                "medication_name": med.name,
                "dosage":          med.dosage or "",
                "scheduled_time":  time_str,
                "scheduled_dt":    scheduled_dt.isoformat(),
                "status":          status,
                "log_id":          log_id,
                "is_overdue":      scheduled_dt < now and status == "pending",
            })

    # Sort by scheduled time
    schedule.sort(key=lambda x: x["scheduled_time"])

    return jsonify(schedule)


# ── ADD medication ─────────────────────────────────────────────────────────────
@medication_bp.route("/", methods=["POST"])
def add_medication():
    data = request.json

    # schedule_times comes as a list from Flutter e.g. ["08:00", "20:00"]
    schedule_times = data.get("schedule_times", [])
    if isinstance(schedule_times, list):
        schedule_times_json = json.dumps(schedule_times)
    else:
        schedule_times_json = None

    # Keep legacy time field set to first schedule time for backward compat
    legacy_time = schedule_times[0] if schedule_times else data.get("time", "")

    medication = Medication(
        patient_id     = data["patient_id"],
        name           = data["name"],
        dosage         = data.get("dosage", ""),
        frequency      = data.get("frequency", ""),
        time           = legacy_time,
        start_date     = data.get("start_date"),
        end_date       = data.get("end_date"),
        schedule_times = schedule_times_json,
    )

    db.session.add(medication)
    db.session.commit()

    return jsonify({"message": "Medication added", "id": medication.id})


# ── UPDATE medication ──────────────────────────────────────────────────────────
@medication_bp.route("/<int:id>", methods=["PUT"])
def update_medication(id):
    medication = Medication.query.get(id)

    if not medication:
        return jsonify({"error": "Not found"}), 404

    data = request.json

    schedule_times = data.get("schedule_times", [])
    if isinstance(schedule_times, list) and schedule_times:
        medication.schedule_times = json.dumps(schedule_times)
        medication.time           = schedule_times[0]
    elif data.get("time"):
        medication.time           = data["time"]
        medication.schedule_times = json.dumps([data["time"]])

    medication.name       = data.get("name",      medication.name)
    medication.dosage     = data.get("dosage",    medication.dosage)
    medication.frequency  = data.get("frequency", medication.frequency)
    medication.start_date = data.get("start_date", medication.start_date)
    medication.end_date   = data.get("end_date",   medication.end_date)

    db.session.commit()

    return jsonify({"message": "Medication updated"})


# ── DELETE medication ──────────────────────────────────────────────────────────
@medication_bp.route("/<int:id>", methods=["DELETE"])
def delete_medication(id):
    medication = Medication.query.get(id)

    if not medication:
        return jsonify({"error": "Not found"}), 404

    db.session.delete(medication)
    db.session.commit()

    return jsonify({"message": "Medication deleted"})