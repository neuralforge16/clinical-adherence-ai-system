from flask import Blueprint, jsonify, request
from models.user import User
from models.medication import Medication
from extensions import db
from ai.gpt_service import generate_clinical_insight, generate_chat_response
from models.adherence_log import AdherenceLog
from datetime import datetime, timedelta

patient_bp = Blueprint("patients", __name__)


# GET all patients
@patient_bp.route("/", methods=["GET"])
def get_patients():
    patients = User.query.filter_by(role="patient").all()
    return jsonify([p.to_dict() for p in patients])


# GET single patient
@patient_bp.route("/<int:patient_id>", methods=["GET"])
def get_patient_by_id(patient_id):
    patient = User.query.filter_by(id=patient_id, role="patient").first_or_404()
    return jsonify(patient.to_dict())


# ADD patient
@patient_bp.route("/", methods=["POST"])
def add_patient():
    data = request.get_json()

    if not data or "full_name" not in data or "email" not in data:
        return jsonify({"error": "full_name and email are required"}), 400

    existing = User.query.filter_by(email=data["email"]).first()
    if existing:
        return jsonify({"error": "Email already exists"}), 409

    patient = User(
        full_name=data["full_name"],
        email=data["email"],
        password=data.get("password", "1234"),
        role="patient",
        phone=data.get("phone"),
        age=data.get("age"),
        sex=data.get("sex"),
        date_of_birth=data.get("date_of_birth"),
        medical_condition=data.get("medical_condition"),
        notes=data.get("notes"),
    )

    db.session.add(patient)
    db.session.commit()

    return jsonify({
        "message": "Patient added successfully",
        "patient": patient.to_dict(),
    }), 201


# UPDATE patient
@patient_bp.route("/<int:patient_id>", methods=["PUT"])
def update_patient(patient_id):
    patient = User.query.filter_by(id=patient_id, role="patient").first_or_404()
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    if "full_name" in data:
        patient.full_name = data["full_name"]
    if "email" in data:
        patient.email = data["email"]
    if "phone" in data:
        patient.phone = data["phone"]
    if "age" in data:
        patient.age = data["age"]
    if "sex" in data:
        patient.sex = data["sex"]
    if "date_of_birth" in data:
        patient.date_of_birth = data["date_of_birth"]
    if "medical_condition" in data:
        patient.medical_condition = data["medical_condition"]
    if "notes" in data:
        patient.notes = data["notes"]

    db.session.commit()

    return jsonify({
        "message": "Patient updated successfully",
        "patient": patient.to_dict(),
    })


# DELETE patient
@patient_bp.route("/<int:patient_id>", methods=["DELETE"])
def delete_patient(patient_id):
    patient = User.query.filter_by(id=patient_id, role="patient").first_or_404()

    # delete patient's medications first
    Medication.query.filter_by(patient_id=patient_id).delete()

    db.session.delete(patient)
    db.session.commit()

    return jsonify({"message": "Patient deleted successfully"})


# GET medications for a specific patient
@patient_bp.route("/<int:patient_id>/medications", methods=["GET"])
def get_patient_medications(patient_id):

    medications = Medication.query.filter_by(patient_id=patient_id).all()

    data = []

    for m in medications:
        data.append({
            "id": m.id,
            "patient_id": m.patient_id,
            "name": m.name,
            "dosage": m.dosage,
            "frequency": m.frequency,
            "time": m.time,
        })

    return jsonify(data)



@patient_bp.route("/risk-summary", methods=["GET"])
@patient_bp.route("/risk-summary", methods=["GET"])
def risk_summary():

    patients = User.query.filter_by(role="patient").all()

    stable = 0
    risk = 0
    critical = 0

    for p in patients:

        medications = Medication.query.filter_by(patient_id=p.id).all()

        if not medications:
            continue

        total_expected = 0
        total_missed = 0

        for m in medications:

            # simple assumption: 30 expected doses
            expected_doses = 30
            missed_doses = getattr(m, "missed", 0)

            total_expected += expected_doses
            total_missed += missed_doses

        if total_expected == 0:
            continue

        adherence = ((total_expected - total_missed) / total_expected) * 100

        if adherence >= 85:
            stable += 1
        elif adherence >= 60:
            risk += 1
        else:
            critical += 1

    return jsonify({
        "total": len(patients),
        "stable": stable,
        "risk": risk,
        "critical": critical
    })

@patient_bp.route("/adherence-overview", methods=["GET"])
def adherence_overview():

    patients = User.query.filter_by(role="patient").all()

    results = []

    for p in patients:

        logs = AdherenceLog.query.filter_by(patient_id=p.id).all()

        if not logs:
            adherence = 0
        else:
            taken = sum(1 for l in logs if l.status == "taken")
            adherence = (taken / len(logs)) * 100

        results.append({
            "patient_id": p.id,
            "name": p.full_name,
            "adherence": round(adherence)
        })

    return jsonify(results)


@patient_bp.route("/alerts", methods=["GET"])
def alerts():

    patients = User.query.filter_by(role="patient").all()

    alerts = []

    for p in patients:

        logs = AdherenceLog.query.filter_by(patient_id=p.id).order_by(AdherenceLog.id.desc()).limit(5).all()

        if not logs:
            continue

        missed = sum(1 for l in logs if l.status == "missed")
        late = sum(1 for l in logs if l.status == "late")

        if missed >= 3:
            alerts.append({
                "patient": p.full_name,
                "message": "Multiple missed doses detected recently"
            })

        elif late >= 3:
            alerts.append({
                "patient": p.full_name,
                "message": "Frequent late medication intake observed"
            })

    return jsonify(alerts)

@patient_bp.route("/ai-insights", methods=["GET"])
def ai_insights():

    patients = User.query.filter_by(role="patient").all()

    insights = []

    for p in patients:

        medications = Medication.query.filter_by(patient_id=p.id).all()

        if not medications:
            continue

        logs = AdherenceLog.query.filter_by(patient_id=p.id).all()

        if not logs:
            continue

        taken = sum(1 for l in logs if l.status == "taken")
        adherence = (taken / len(logs)) * 100

        insight = generate_clinical_insight(adherence)

        insights.append({
            "patient": p.full_name,
            "adherence": round(adherence),
            "insight": insight
        })

    return jsonify(insights)

@patient_bp.route("/risk-predictions", methods=["GET"])
def risk_predictions():

    patients = User.query.filter_by(role="patient").all()

    results = []

    for p in patients:

        logs = AdherenceLog.query.filter_by(patient_id=p.id).all()

        if not logs:
            continue

        taken = sum(1 for l in logs if l.status == "taken")
        adherence = (taken / len(logs)) * 100

        try:
            # reuse AI insight as reasoning
            ai_text = generate_clinical_insight(adherence)

            # 🔥 classify risk based on adherence (simple + consistent)
            if adherence >= 85:
                risk = "LOW"
            elif adherence >= 60:
                risk = "MEDIUM"
            else:
                risk = "HIGH"

            reason = ai_text.split(".")[0] + "."

        except:
            # fallback
            if adherence >= 85:
                risk = "LOW"
                reason = "Adherence stable"
            elif adherence >= 60:
                risk = "MEDIUM"
                reason = "Adherence declining"
            else:
                risk = "HIGH"
                reason = "Multiple missed doses detected"

        results.append({
            "patient": p.full_name,
            "adherence": round(adherence),
            "risk": risk,
            "reason": reason
        })

    return jsonify(results)

@patient_bp.route("/<int:patient_id>/report", methods=["GET"])
def patient_report(patient_id):

    logs = AdherenceLog.query.filter_by(patient_id=patient_id).all()

    if not logs:
        return jsonify({
            "stable": 0,
            "risk": 0,
            "critical": 0,
            "on_time": 0,
            "late": 0,
            "missed": 0,
            "ai_insight": ""
        })

    total = len(logs)

    taken = sum(1 for l in logs if l.status == "taken")
    missed = sum(1 for l in logs if l.status == "missed")
    late = sum(1 for l in logs if l.status == "late")

    adherence = (taken / total) * 100

    # ONLY HERE
    ai_insight = generate_clinical_insight(adherence)

    if adherence >= 85:
        stable = 1
        risk = 0
        critical = 0
    elif adherence >= 60:
        stable = 0
        risk = 1
        critical = 0
    else:
        stable = 0
        risk = 0
        critical = 1

    return jsonify({
        "stable": stable,
        "risk": risk,
        "critical": critical,
        "on_time": int((taken / total) * 100),
        "late": int((late / total) * 100),
        "missed": int((missed / total) * 100),
        "ai_insight": ai_insight
    })

@patient_bp.route("/log-dose", methods=["POST"])
def log_dose():

    data = request.json

    patient_id = data["patient_id"]
    medication_id = data["medication_id"]
    status = data["status"]

    # 🔥 check last log (prevent duplicates)
    last_log = AdherenceLog.query.filter_by(
        patient_id=patient_id,
        medication_id=medication_id
    ).order_by(AdherenceLog.timestamp.desc()).first()

    if last_log:
        time_diff = datetime.utcnow() - last_log.timestamp

        if time_diff < timedelta(hours=2):
            return jsonify({
                "message": "Dose already logged recently",
                "status": "duplicate"
            })

    # ✅ create new log
    log = AdherenceLog(
        patient_id=patient_id,
        medication_id=medication_id,
        status=status
    )

    db.session.add(log)
    db.session.commit()

    return jsonify({
        "message": "Dose logged successfully",
        "status": "success"
    })

@patient_bp.route("/<int:patient_id>/weekly-adherence", methods=["GET"])
def weekly_adherence(patient_id):

    logs = AdherenceLog.query.filter_by(patient_id=patient_id).all()

    days_map = {
        0: "Mon",
        1: "Tue",
        2: "Wed",
        3: "Thu",
        4: "Fri",
        5: "Sat",
        6: "Sun",
    }

    result = {d: [] for d in days_map.values()}

    for log in logs:
        day = days_map[log.timestamp.weekday()]

        if log.status == "taken":
            result[day].append(True)
        else:
            result[day].append(False)

    return jsonify(result)

@patient_bp.route("/<int:patient_id>/adherence", methods=["GET"])
def get_patient_adherence(patient_id):

    logs = AdherenceLog.query.filter_by(patient_id=patient_id)\
        .order_by(AdherenceLog.timestamp.desc()).all()

    if not logs:
        return jsonify({
            "adherence_rate": 0,
            "taken": 0,
            "missed": 0,
            "logs": []
        })

    total = len(logs)
    taken = sum(1 for l in logs if l.status == "taken")
    missed = sum(1 for l in logs if l.status == "missed")

    return jsonify({
        "adherence_rate": int((taken / total) * 100),
        "taken": taken,
        "missed": missed,
        "logs": [
            {
                "status": l.status,
                "timestamp": l.timestamp.strftime("%Y-%m-%d %H:%M")
            } for l in logs
        ]
    })

@patient_bp.route("/top-risk", methods=["GET"])
def top_risk():

    patients = User.query.filter_by(role="patient").all()

    top_patient = None
    highest_risk_score = -1

    for p in patients:
        logs = AdherenceLog.query.filter_by(patient_id=p.id).all()
        if not logs:
            continue

        taken = sum(1 for l in logs if l.status == "taken")
        adherence = (taken / len(logs)) * 100

        # convert to risk score (lower adherence = higher risk)
        risk_score = 100 - adherence

        if risk_score > highest_risk_score:
            highest_risk_score = risk_score
            top_patient = {
                "patient": p.full_name,
                "adherence": round(adherence),
                "risk":
                    "HIGH" if adherence < 60 else
                    "MEDIUM" if adherence < 85 else
                    "LOW"
            }

    return jsonify(top_patient if top_patient else {})


@patient_bp.route("/trend/<int:patient_id>")
def trend(patient_id):

    logs = AdherenceLog.query.filter_by(patient_id=patient_id)\
        .order_by(AdherenceLog.id.desc())\
        .limit(6).all()

    if len(logs) < 2:
        return {"trend": "stable"}

    recent = logs[:3]
    older = logs[3:]

    def calc(logs):
        taken = sum(1 for l in logs if l.status == "taken")
        return taken / len(logs)

    recent_score = calc(recent)
    older_score = calc(older)

    if recent_score > older_score:
        return {"trend": "up"}
    elif recent_score < older_score:
        return {"trend": "down"}
    else:
        return {"trend": "stable"}


@patient_bp.route("/medication/<int:med_id>/insight", methods=["GET"])
def medication_insight(med_id):

    logs = AdherenceLog.query.filter_by(medication_id=med_id).all()

    if not logs:
        return jsonify({"insight": "No data available"})

    taken = sum(1 for l in logs if l.status == "taken")
    adherence = (taken / len(logs)) * 100

    insight = generate_clinical_insight(adherence)

    return jsonify({"insight": insight})

@patient_bp.route("/ai/chat", methods=["POST"])
def ai_chat():
    data = request.json

    # Flutter sends the full conversation history as a list of
    # {"role": "user"|"assistant", "content": "..."} objects.
    # The first user message already contains the patient context prefix
    # injected by the Flutter client.
    history = data.get("history", [])

    # Fallback: support old single-message format so nothing breaks
    if not history:
        message = data.get("message", "")
        if not message:
            return jsonify({"response": "Empty message"}), 400
        history = [{"role": "user", "content": message}]

    if not history:
        return jsonify({"response": "Empty message"}), 400

    response = generate_chat_response(history)
    return jsonify({"response": response})