import json
from extensions import db


class Medication(db.Model):

    __tablename__ = "medications"

    id = db.Column(db.Integer, primary_key=True)

    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("user.id"),
        nullable=False
    )

    name      = db.Column(db.String(100), nullable=False)
    dosage    = db.Column(db.String(50))
    frequency = db.Column(db.String(50))

    # Legacy single-time field kept for backward compatibility
    time = db.Column(db.String(50))

    # --- New prescription fields ---
    # e.g. "2025-01-15"
    start_date = db.Column(db.String(20), nullable=True)

    # e.g. "2025-02-15" — null means ongoing
    end_date = db.Column(db.String(20), nullable=True)

    # JSON-encoded list of times e.g. '["08:00", "20:00"]'
    # Stored as text, parsed on read
    schedule_times = db.Column(db.Text, nullable=True)

    def get_schedule_times(self):
        """Returns list of time strings e.g. ['08:00', '20:00']"""
        if self.schedule_times:
            try:
                return json.loads(self.schedule_times)
            except Exception:
                pass
        # Fall back to legacy time field
        if self.time:
            return [self.time]
        return []

    def is_active(self):
        """Returns True if prescription is currently active based on dates."""
        from datetime import date
        today = date.today()

        if self.start_date:
            try:
                start = date.fromisoformat(self.start_date)
                if today < start:
                    return False
            except ValueError:
                pass

        if self.end_date:
            try:
                end = date.fromisoformat(self.end_date)
                if today > end:
                    return False
            except ValueError:
                pass

        return True

    def to_dict(self):
        return {
            "id":             self.id,
            "patient_id":     self.patient_id,
            "name":           self.name,
            "dosage":         self.dosage,
            "frequency":      self.frequency,
            "time":           self.time,
            "start_date":     self.start_date,
            "end_date":       self.end_date,
            "schedule_times": self.get_schedule_times(),
            "is_active":      self.is_active(),
        }