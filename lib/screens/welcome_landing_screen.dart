import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/sensor_service.dart';
import 'home_navigation_screen.dart';

class WelcomeLandingScreen extends StatelessWidget {
  final AppLocaleController localeController;
  final SensorService sensorService;

  const WelcomeLandingScreen({
    super.key,
    required this.localeController,
    required this.sensorService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final tr = localeController.tr;
        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Language Pill Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          tr('welcomeBadge'),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Row(
                        children: ['es', 'en', 'pt'].map((lang) {
                          final selected = localeController.langCode == lang;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => localeController.setLocale(lang),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF161F30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF2D3C52),
                                  ),
                                ),
                                child: Text(
                                  lang.toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF0B0F19)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Emblem / Botanical Photometer Badge
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF161F30), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 54,
                          color: Color(0xFF10B981),
                        ),
                        Positioned(
                          right: 18,
                          top: 18,
                          child: Icon(
                            Icons.wb_sunny_rounded,
                            size: 24,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // App Title & Headline
                  Text(
                    tr('appTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('welcomeHeadline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('welcomeDesc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature Highlights Grid
                  _buildFeatureRow(
                    Icons.grass_rounded,
                    const Color(0xFF10B981),
                    tr('featBotany'),
                    'Monstera, Ficus, Phalaenopsis, Strelitzia, Suculentas & más',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    Icons.camera_alt_rounded,
                    const Color(0xFFF59E0B),
                    tr('featPhoto'),
                    'EV₁₀₀, ISO 50–12800, f/1.4–f/22 & Velocidad de Obturación',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    Icons.verified_user_rounded,
                    const Color(0xFF10B981),
                    tr('featNorm'),
                    'Oficinas, Laboratorios, Dibujo CAD, Aulas y Almacenes',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    Icons.picture_as_pdf_rounded,
                    const Color(0xFFF59E0B),
                    tr('featPdf'),
                    'Exportación A4 con firma manuscrita digital en dispositivo',
                  ),
                  const SizedBox(height: 32),

                  // Primary Enter CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      key: const Key('btnWelcomeEnter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF0B0F19),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => HomeNavigationScreen(
                              localeController: localeController,
                              sensorService: sensorService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 22),
                      label: Text(
                        tr('btnEnter'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    Color accent,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D3C52)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
