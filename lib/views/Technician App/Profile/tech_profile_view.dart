import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../widgets/tech_app_bar_actions.dart';
import '../widgets/tech_list_shimmer.dart';
import '../technician_view_model.dart';

class TechProfileView extends StatefulWidget {
  const TechProfileView({super.key});

  @override
  State<TechProfileView> createState() => _TechProfileViewState();
}

class _TechProfileViewState extends State<TechProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechAppViewModel>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TechAppViewModel>(
      builder: (context, vm, child) {
        final profile = vm.profile;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            backgroundColor: AppColors.primaryLight,
            elevation: 0,
            toolbarHeight: 70,
            leadingWidth: 70,
            leading: Center(
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryLight.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            title: Text(
              l10n.techProfileTitle,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            actions: techAppBarTrailingActions(context),
          ),
          body: vm.isLoading
              ? const TechDetailShimmer()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildProfileCard(l10n, profile),
                      const SizedBox(height: 24),
                      _buildSection(l10n.techProfileBasicInfo, [
                        _buildInfoTile(
                          l10n.techProfileEmail,
                          profile?.email ?? l10n.techProfileNA,
                          Icons.email_rounded,
                          Colors.orange,
                        ),
                        _buildInfoTile(
                          l10n.techProfileMobile,
                          profile?.mobile ?? l10n.techProfileNA,
                          Icons.phone_android_rounded,
                          Colors.orange,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(l10n.techProfileDutyDetails, [
                        _buildInfoTile(
                          l10n.techProfileType,
                          (profile?.technicianType ?? l10n.techProfileNA)
                              .toUpperCase(),
                          Icons.work_rounded,
                          AppColors.primaryLight,
                        ),
                        _buildInfoTile(
                          l10n.techProfileDutyMode,
                          (profile?.dutyMode ?? l10n.techProfileNA)
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          Icons.electric_bolt_rounded,
                          AppColors.primaryLight,
                        ),
                        _buildInfoTile(
                          l10n.techProfileCommission,
                          '${profile?.commissionPercent ?? 0}%',
                          Icons.percent_rounded,
                          AppColors.primaryLight,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(l10n.techProfileAssociations, [
                        _buildInfoTile(
                          l10n.techProfileWorkshop,
                          profile?.workshop?.name ?? l10n.techProfileNA,
                          Icons.store_rounded,
                          const Color(0xFF2D9CDB),
                        ),
                        _buildInfoTile(
                          l10n.techProfileBranch,
                          profile?.branch?.name ?? l10n.techProfileNA,
                          Icons.account_tree_rounded,
                          const Color(0xFF2D9CDB),
                        ),
                        if (profile?.departments != null &&
                            profile!.departments!.isNotEmpty)
                          _buildInfoTile(
                            l10n.techProfileDepartments,
                            profile.departments!.map((e) => e.name).join(', '),
                            Icons.category_rounded,
                            const Color(0xFF2D9CDB),
                          ),
                      ]),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          l10n.techProfileFooter('1.0.1'),
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n, profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile?.name ?? "Tech")}&background=FCC247&color=23262D',
                width: 64,
                height: 64,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? l10n.techProfileTechnicianName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.techProfileRoleId(
                    profile?.employeeId ?? l10n.techProfileNA,
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (profile?.technicianType ?? l10n.techProfileStandard)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
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
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.grey.withOpacity(0.05),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.secondaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
