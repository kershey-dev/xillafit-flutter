import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/profile/presentation/profile_providers.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';

class ProfilePlaceholderScreen extends ConsumerStatefulWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  ConsumerState<ProfilePlaceholderScreen> createState() => _ProfilePlaceholderScreenState();
}

class _ProfilePlaceholderScreenState extends ConsumerState<ProfilePlaceholderScreen> {
  bool _loading = false;

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final authEmail = session?.user.email;
    final authUserId = session?.user.id;

    final profileAsync = ref.watch(currentProfileProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 32, child: Icon(Icons.person_outline, size: 30)),
            const SizedBox(height: AppSpacing.sm),
            Text('Profile', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            profileAsync.when(
              loading: () => Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  const CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  const SizedBox(height: 10),
                  Text('Loading profile…', style: AppTextStyles.caption),
                ],
              ),
              error: (Object error, StackTrace stack) => Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text('Could not load profile.', style: AppTextStyles.caption.copyWith(color: AppColors.goldDark)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(error.toString(), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
              data: (profile) {
                if (profile == null) {
                  return Column(
                    children: [
                      Text('Profile not found.', style: AppTextStyles.caption),
                      if (authUserId != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text('ID: $authUserId', style: AppTextStyles.body.copyWith(fontSize: 12)),
                      ],
                      if (authEmail != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(authEmail, style: AppTextStyles.body.copyWith(fontSize: 12)),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.email != null) ...[
                      Text(profile.email!, style: AppTextStyles.body.copyWith(fontSize: 13)),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    if (profile.fullName != null && profile.fullName!.isNotEmpty) ...[
                      Text(profile.fullName!, style: AppTextStyles.body.copyWith(fontSize: 13)),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text('ID: ${profile.id}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    if (profile.role != null && profile.role!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text('Role: ${profile.role}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlineButtonX(
              text: _loading ? 'Signing out…' : 'Sign out',
              onPressed: _loading ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
