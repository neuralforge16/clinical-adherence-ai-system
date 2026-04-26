# clinical-adherence-ai-system

Mousavi,Ehsan



\# Clinical Adherence AI System



\## Project Description

A full-stack clinical medication adherence platform designed to help doctors monitor and manage patient medication compliance. The system allows doctors to manage patients, prescribe medications, track daily adherence schedules, and receive AI-generated clinical insights based on each patient's adherence rate. Patients can log their medication intake through their own dashboard.



\---



\## Author

\*\*Mousavi, Seyedehsan - 300459758\*\*



\---



\## Folder Structure



\### `backend\_flask/`

Python/Flask REST API backend:

\- `app.py` — Main Flask application entry point

\- `config.py` — App configuration and environment setup

\- `extensions.py` — Database and JWT initialization

\- `models/` — Database models (User, Medication, AdherenceLog)

\- `routes/` — API route handlers (auth, patients, medications, adherence)

\- `ai/gpt\_service.py` — AI clinical insight generation using Groq (LLaMA 3.1)

\- `instance/database.db` — SQLite database file



\### `frontend\_flutter/`

Flutter web frontend:

\- `lib/main.dart` — App entry point

\- `lib/pages/` — Login, Patients, Reports, Settings pages

\- `lib/dashboards/` — Doctor and Patient dashboards

\- `lib/widgets/` — Reusable UI components (charts, AI chat, medication dialogs)

\- `lib/core/api\_service.dart` — API communication layer



\---



\## How to Run

\### Backend (Flask)

cd backend\_flask

venv\\Scripts\\activate

python app.py



The backend will start at: `http://localhost:5000`


Default test accounts (auto-created on first run):

\- Doctor: `doctor@test.com` / `1234`

\- Patient: `patient@test.com` / `1234`



\### Frontend (Flutter)

cd frontend\_flutter

flutter run -d chrome





