from extensions import db


class User(db.Model):
    __tablename__ = "user"

    id = db.Column(db.Integer, primary_key=True)

    full_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    role = db.Column(db.String(50), nullable=False)

    phone = db.Column(db.String(50))
    age = db.Column(db.Integer)
    sex = db.Column(db.String(20))
    date_of_birth = db.Column(db.String(50))
    medical_condition = db.Column(db.String(200))
    notes = db.Column(db.Text)

    medications = db.relationship(
        "Medication",
        backref="patient",
        lazy=True,
    )

    def to_dict(self):
        return {
            "id": self.id,
            "full_name": self.full_name,
            "email": self.email,
            "role": self.role,
            "phone": self.phone,
            "age": self.age,
            "sex": self.sex,
            "date_of_birth": self.date_of_birth,
            "medical_condition": self.medical_condition,
            "notes": self.notes,
        }