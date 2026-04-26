import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'router_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF3F7FF);
  static const Color _fieldFill = Color(0xFFF0F4FF);
  static const Color _mutedText = Color(0xFF6B7280);

  // ── State (all unchanged from original) ───────────────────────────────────
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String selectedRole = "doctor";
  String errorMessage = "";
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Login logic (unchanged) ────────────────────────────────────────────────
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    var result = await ApiService.login(
      emailController.text,
      passwordController.text,
    );
    print(result);

    if (!mounted) return;

    if (result["role"] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RouterPage(role: result["role"], userId: result["user_id"]),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Login failed. Please check your credentials.";
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;
            return isMobile ? _mobileLayout() : _desktopLayout();
          },
        ),
      ),
    );
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────
  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "eHospital",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Smart Medication Adherence Monitoring",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _loginCard(),
        ],
      ),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────────────
  // FIX: use plain color instead of LinearGradient — avoids Flutter web
  // shader compilation crash (known bug with gradients on certain GPU drivers)
  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — solid primary blue (no gradient = no shader crash)
        Expanded(
          flex: 5,
          child: Container(
            color: _primary, // ← plain color, not gradient
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "eHospital",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // Doctor illustration
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      "assets/doctors_illustration.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // System name badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "Smart Medication Adherence Monitoring",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Smarter care,\nbetter outcomes.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Track, monitor and improve patient medication\nadherence with AI-powered clinical insights.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 40),

                // Feature pills
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _FeaturePill(
                      icon: Icons.show_chart,
                      label: "Adherence Analytics",
                    ),
                    _FeaturePill(
                      icon: Icons.smart_toy,
                      label: "AI Risk Prediction",
                    ),
                    _FeaturePill(
                      icon: Icons.notifications,
                      label: "Smart Alerts",
                    ),
                    _FeaturePill(
                      icon: Icons.picture_as_pdf,
                      label: "Clinical Reports",
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),

        // Right panel — scrollable so card never overflows
        // FIX: wrap in SingleChildScrollView to prevent overflow
        Expanded(
          flex: 4,
          child: Container(
            color: _pageBg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              child: Center(child: _loginCard()),
            ),
          ),
        ),
      ],
    );
  }

  // ── Login card ─────────────────────────────────────────────────────────────
  Widget _loginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Login to your clinical dashboard",
                style: TextStyle(color: _mutedText, fontSize: 14),
              ),

              const SizedBox(height: 28),

              // Role dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _inputDecoration("Select role"),
                items: const [
                  DropdownMenuItem(value: "doctor", child: Text("Doctor")),
                  DropdownMenuItem(value: "patient", child: Text("Patient")),
                ],
                onChanged: (value) => setState(() => selectedRole = value!),
              ),

              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email address"),
                validator: (v) {
                  final val = (v ?? "").trim();
                  if (val.isEmpty) return "Email is required";
                  if (!val.contains("@")) return "Enter a valid email";
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _inputDecoration("Password").copyWith(
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: _mutedText,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v ?? "").isEmpty ? "Password is required" : null,
              ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // Error banner
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFBE123C),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Color(0xFF9F1239),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Footer
              Center(
                child: Text(
                  "Smart Medication Adherence Monitoring System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mutedText.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _mutedText, fontSize: 14),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

// ── Feature pill (left panel) ─────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
