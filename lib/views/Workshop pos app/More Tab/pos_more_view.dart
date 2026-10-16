import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../Home Screen/pos_view_model.dart';
import '../Petty Cash/petty_cash_view_model.dart';
import '../../../l10n/app_localizations.dart';

class PosMoreView extends StatelessWidget {
  final Function(int)? onSelect;
  const PosMoreView({super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isTablet ? 180 : 120,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F6),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Consumer<PosViewModel>(
            builder: (context, vm, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelect != null) {
                        onSelect!(4); // Index 4: Petty Cash
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: isTablet ? 20 : 16,
                            color: context.watch<PettyCashViewModel>().isLowPettyCashBalance
                                ? Colors.red
                                : AppColors.secondaryLight.withOpacity(0.7),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.moreMenuPettyCash,
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: context.watch<PettyCashViewModel>().isLowPettyCashBalance
                                  ? Colors.red
                                  : AppColors.secondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    label: l10n.moreMenuPromoCode,
                    icon: Icons.local_offer,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelect != null) {
                        onSelect!(5); // Index 5: Promo Code
                      }
                    },
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    label: l10n.moreMenuStoreClosing,
                    icon: Icons.door_front_door_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelect != null) {
                        onSelect!(6); // Index 6: Store Closing
                      }
                    },
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    label: l10n.moreMenuSalesReturn,
                    icon: Icons.assignment_return_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelect != null) {
                        onSelect!(7); // Index 7: Sales Return
                      }
                    },
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isTablet = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: isTablet ? 18 : 15, color: AppColors.secondaryLight.withOpacity(0.7)),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLight,
                fontSize: isTablet ? 12 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, Function(int) onSelect) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.moreMenuBarrierLabel,
      barrierColor: Colors.black.withOpacity(0.1),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 85),
            child: PosMoreView(onSelect: onSelect),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
    );
  }
}
