import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_settings_view_model.dart';
import '../../../services/session_service.dart';
import '../../Menu/menu_view.dart';
import '../../../utils/restart_widget.dart';

class SuperAdminSettingsView extends StatelessWidget {
  const SuperAdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SuperAdminSettingsViewModel(),
      child: const _SuperAdminSettingsContent(),
    );
  }
}

class _SuperAdminSettingsContent extends StatefulWidget {
  const _SuperAdminSettingsContent();

  @override
  State<_SuperAdminSettingsContent> createState() => _SuperAdminSettingsContentState();
}

class _SuperAdminSettingsContentState extends State<_SuperAdminSettingsContent> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminSettingsViewModel>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(vm),
            const SizedBox(height: 24),
            _buildSection('Application Settings', [
              _buildToggleTile('Dark Mode', 'Switch between light and dark themes', Icons.dark_mode_rounded, vm.isDarkMode, (v) => vm.toggleDarkMode(v)),
              _buildToggleTile('Push Notifications', 'Receive system alerts', Icons.notifications_rounded, vm.pushNotifications, (v) => vm.togglePushNotifications(v)),
              _buildToggleTile('Email Reports', 'Weekly performance reports', Icons.email_rounded, vm.emailAlerts, (v) => vm.toggleEmailAlerts(v)),
            ]),
            const SizedBox(height: 24),
            _buildSection('Regional', [
              _buildLanguageTile(vm),
              _buildNavTile('Currency Settings (SAR)', Icons.payments_rounded, Colors.green),
            ]),
            const SizedBox(height: 24),
            _buildSection('Security & Support', [
              _buildNavTile('Two-Factor Authentication', Icons.security_rounded, Colors.blue),
              _buildNavTile('Report a System Issue', Icons.bug_report_rounded, Colors.redAccent),
              _buildNavTile('Help Documentation', Icons.help_outline_rounded, Colors.grey),
            ]),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 12),
            const Center(child: Text('Super Admin Console • Version 1.2.0', style: TextStyle(color: Colors.grey, fontSize: 11))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(SuperAdminSettingsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.secondaryLight.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network('https://ui-avatars.com/api/?name=${Uri.encodeComponent(vm.adminName)}&background=FCC247&color=23262D', width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vm.adminName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text('System Super Admin', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('FULL ACCESS CONTROL', style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) Divider(height: 1, color: Colors.grey.withOpacity(0.05), indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: AppColors.secondaryLight.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.secondaryLight, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryLight)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primaryLight),
    );
  }

  Widget _buildNavTile(String title, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
      onTap: () {},
    );
  }

  Widget _buildLanguageTile(SuperAdminSettingsViewModel vm) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.translate_rounded, color: Colors.indigo, size: 20),
      ),
      title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryLight)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.selectedLanguage,
          elevation: 8,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight, fontSize: 13),
          items: ['English', 'Arabic'].map((lang) {
            return DropdownMenuItem(value: lang, child: Text(lang));
          }).toList(),
          onChanged: (val) {
            if (val != null) vm.changeLanguage(val);
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
        title: const Text('Log Out of Console', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent, size: 20),
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log out',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out of Super Admin?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final session = SessionService();
                        await session.clearSession(role: 'admin');
                        await session.saveLastPortal('');
                        if (context.mounted) {
                          RestartWidget.restartApp(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Log out', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
