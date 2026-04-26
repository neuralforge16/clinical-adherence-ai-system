from flask import Blueprint, request, jsonify
from models.user import User

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["POST"])
def login():

    data = request.get_json()

    # validate input
    if not data or "email" not in data or "password" not in data:
        return jsonify({"error": "Email and password required"}), 400

    # find user
    user = User.query.filter_by(email=data["email"]).first()

    if not user:
        return jsonify({"error": "User not found"}), 404

    # check password
    if user.password != data["password"]:
        return jsonify({"error": "Wrong password"}), 401

    # success response
    return jsonify(
        {
            "message": "Login successful",
            "user_id": user.id,
            "role": user.role,
            "name": user.full_name,
        }
    )