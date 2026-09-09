/// P2 · 名片档案编辑 bottom sheet（首次用名片强制；⋮ 菜单可再编辑）。
library;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/profile/user_profile.dart';
import '../l10n/app_localizations.dart';

class ProfileSheet extends StatefulWidget {
  final UserProfile initial;
  const ProfileSheet({super.key, required this.initial});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.name);
  late final TextEditingController _title =
      TextEditingController(text: widget.initial.title);
  late final TextEditingController _qr =
      TextEditingController(text: widget.initial.qrContent);

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _qr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      color: T.paper,
      padding: EdgeInsets.fromLTRB(
          T.s3, T.s3, T.s3, MediaQuery.of(context).viewInsets.bottom + T.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.profileSheetTitle.toUpperCase(), style: T.micro),
          const SizedBox(height: T.s2),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.nameField),
          ),
          const SizedBox(height: T.s2),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l.titleField),
          ),
          const SizedBox(height: T.s2),
          TextField(
            controller: _qr,
            decoration:
                InputDecoration(labelText: l.qrField, helperText: l.qrHelper),
          ),
          const SizedBox(height: T.s3),
          SizedBox(
            width: double.infinity,
            height: T.primaryHeight,
            child: FilledButton(
              onPressed: () async {
                final ctx = context; // async gap 前捕获，gap 后用 ctx.mounted 守卫
                await UserProfileStore.save(UserProfile(
                  name: _name.text.trim(),
                  title: _title.text.trim(),
                  qrContent: _qr.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: T.accent,
                foregroundColor: T.onAccent,
              ),
              child: Text(l.save, style: T.title.copyWith(color: T.onAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
