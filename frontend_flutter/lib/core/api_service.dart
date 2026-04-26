import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "http://127.0.0.1:5000/api";

  static Future login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await http.get(Uri.parse("$baseUrl/patients/"));
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> getPatientById(int patientId) async {
    final response = await http.get(Uri.parse("$baseUrl/patients/$patientId"));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception("Failed to load patient");
  }

  static Future addPatient({
    required String fullName,
    required String email,
    String? phone,
    int? age,
    String? sex,
    String? dateOfBirth,
    String? medicalCondition,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/patients/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "age": age,
        "sex": sex,
        "date_of_birth": dateOfBirth,
        "medical_condition": medicalCondition,
        "notes": notes,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future updatePatient({
    required int patientId,
    required String fullName,
    required String email,
    String? phone,
    int? age,
    String? sex,
    String? dateOfBirth,
    String? medicalCondition,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/patients/$patientId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "age": age,
        "sex": sex,
        "date_of_birth": dateOfBirth,
        "medical_condition": medicalCondition,
        "notes": notes,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future deletePatient(int patientId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/patients/$patientId"),
    );

    return jsonDecode(response.body);
  }

  static Future addMedication({
    required int patientId,
    required String name,
    required String dosage,
    required String frequency,
    required String time,
    List<String> scheduleTimes = const [],
    String? startDate,
    String? endDate,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/medications/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patient_id": patientId,
        "name": name,
        "dosage": dosage,
        "frequency": frequency,
        "time": time,
        "schedule_times": scheduleTimes.isNotEmpty ? scheduleTimes : [time],
        "start_date": startDate,
        "end_date": endDate,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future getMedications() async {
    final response = await http.get(Uri.parse("$baseUrl/medications/"));
    return jsonDecode(response.body);
  }

  static Future deleteMedication(int id) async {
    await http.delete(Uri.parse("$baseUrl/medications/$id"));
  }

  static Future updateMedication({
    required int id,
    required String name,
    required String dosage,
    required String frequency,
    required String time,
    List<String> scheduleTimes = const [],
    String? startDate,
    String? endDate,
  }) async {
    await http.put(
      Uri.parse("$baseUrl/medications/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "dosage": dosage,
        "frequency": frequency,
        "time": time,
        "schedule_times": scheduleTimes.isNotEmpty ? scheduleTimes : [time],
        "start_date": startDate,
        "end_date": endDate,
      }),
    );
  }

  static Future<List> getPatientMedications(int patientId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/$patientId/medications"),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPatientAdherence(int patientId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/$patientId/adherence"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load adherence data");
  }

  static Future getCalendarEvents() async {
    var response = await http.get(Uri.parse("$baseUrl/calendar"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiskSummary() async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/risk-summary"),
    );

    return jsonDecode(response.body);
  }

  static Future<List> getPopulationAdherence() async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/adherence-overview"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List> getAdherenceOverview() async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/adherence-overview"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List> getAIInsights() async {
    final response = await http.get(Uri.parse("$baseUrl/patients/ai-insights"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List> getRiskPredictions() async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/risk-predictions"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<Map<String, dynamic>> getPatientReport(int patientId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/$patientId/report"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load report");
  }

  static Future<Map<String, dynamic>> logDose({
    required int patientId,
    required int medicationId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/patients/log-dose"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patient_id": patientId,
        "medication_id": medicationId,
        "status": status,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getTodaySchedule(
    int patientId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medications/today-schedule/$patientId'),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>> getDailyAdherence(int patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/daily-adherence'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load daily adherence');
  }

  static Future<Map<String, dynamic>> getMonthlyAdherence(int patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/monthly-adherence'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load monthly adherence');
  }

  static Future<Map<String, dynamic>> getWeeklyAdherence(int patientId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients/$patientId/weekly-adherence"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load weekly adherence");
  }

  static Future<List> getAlerts() async {
    final response = await http.get(Uri.parse("$baseUrl/patients/alerts"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> getAdherenceLogs(int patientId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/adherence/patient/$patientId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load adherence logs");
    }
  }

  static Future getTopRiskPatient() async {
    final res = await http.get(Uri.parse("$baseUrl/patients/top-risk"));
    return jsonDecode(res.body);
  }

  static Future<List> getMedicationLogs(int medId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/adherence/medication/$medId'),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMedicationInsight(int medId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/medication/$medId/insight'),
    );

    return jsonDecode(response.body);
  }

  // history = list of {"role": "user"|"assistant", "content": "..."}
  // Sends the full conversation so the backend can maintain context
  static Future<String> sendChatMessage(
    List<Map<String, String>> history,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/ai/chat'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"history": history}),
    );

    final data = jsonDecode(response.body);
    return data["response"];
  }
}
