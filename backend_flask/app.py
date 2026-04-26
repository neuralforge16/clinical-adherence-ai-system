from flask import Flask
from flask_cors import CORS

# Load .env file automatically so os.environ picks up GROQ_API_KEY etc.
from dotenv import load_dotenv
load_dotenv()

from config import Config
from extensions import db, jwt

from models.user import User
from routes.auth_routes import auth_bp
from routes.patient_routes import patient_bp
from routes.medication_routes import medication_bp
from models.adherence_log import AdherenceLog
from routes.adherence_routes import adherence_bp

app = Flask(__name__)
app.config.from_object(Config)

CORS(app)

db.init_app(app)
jwt.init_app(app)

app.register_blueprint(auth_bp,      url_prefix="/api/auth")
app.register_blueprint(patient_bp,   url_prefix="/api/patients")
app.register_blueprint(medication_bp, url_prefix="/api/medications")
app.register_blueprint(adherence_bp, url_prefix="/api/adherence")

if __name__ == "__main__":

    with app.app_context():

        db.create_all()

        if not User.query.first():

            doctor = User(
                full_name="Dr Smith",
                email="doctor@test.com",
                password="1234",
                role="doctor",
            )

            patient = User(
                full_name="John Patient",
                email="patient@test.com",
                password="1234",
                role="patient",
            )

            db.session.add(doctor)
            db.session.add(patient)
            db.session.commit()

    app.run(debug=True)
