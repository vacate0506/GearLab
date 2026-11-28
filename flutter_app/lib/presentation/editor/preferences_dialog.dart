import 'package:material_ui/material_ui.dart';

import '../../app/app_preferences.dart';
import '../../design/components.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'editor_controller.dart';

class PreferencesDialog extends StatelessWidget {
  const PreferencesDialog({super.key, required this.controller});

  final GearLabController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return GlDialogFrame(
      title: l10n.preferences,
      description: l10n.preferencesNote,
      maxWidth: 360,
      onClose: () => Navigator.pop(context),
      actions: <Widget>[
        GlButton(
          label: l10n.done,
          variant: GlButtonVariant.primary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: AnimatedBuilder(
        animation: controller.preferences,
        builder: (BuildContext context, Widget? child) {
          final AppPreferences preferences = controller.preferences.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Label(l10n.theme),
              GlSegmentedControl<GlThemePreference>(
                value: preferences.theme,
                options: <GlSegmentedOption<GlThemePreference>>[
                  GlSegmentedOption<GlThemePreference>(
                    value: GlThemePreference.system,
                    label: l10n.themeSystem,
                  ),
                  GlSegmentedOption<GlThemePreference>(
                    value: GlThemePreference.light,
                    label: l10n.themeLight,
                  ),
                  GlSegmentedOption<GlThemePreference>(
                    value: GlThemePreference.dark,
                    label: l10n.themeDark,
                  ),
                ],
                onChanged: controller.setThemePreference,
              ),
              const SizedBox(height: GlSpace.lg),
              _Label(l10n.language),
              GlSegmentedControl<String?>(
                value: preferences.localeCode,
                options: <GlSegmentedOption<String?>>[
                  GlSegmentedOption<String?>(
                    value: null,
                    label: l10n.languageSystem,
                  ),
                  GlSegmentedOption<String?>(
                    value: 'zh',
                    label: l10n.languageZh,
                  ),
                  GlSegmentedOption<String?>(
                    value: 'en',
                    label: l10n.languageEn,
                  ),
                ],
                onChanged: controller.setLocaleCode,
              ),
              const SizedBox(height: GlSpace.lg),
              Text(
                l10n.aboutLocal,
                style: GlType.micro.copyWith(color: context.gl.ink3),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GlType.label.copyWith(color: context.gl.ink2),
      ),
    );
  }
}
