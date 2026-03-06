import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark_app/theme/spark_theme.dart';
import 'package:spark_app/models/player.dart';
import 'package:spark_app/providers/player_provider.dart';

/// Create / edit player dialog with name + avatar emoji picker.
class PlayerFormDialog extends StatefulWidget {
  final Player? existing;
  const PlayerFormDialog({super.key, this.existing});

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  late TextEditingController _nameCtrl;
  String _avatar = '🏓';

  static const _avatars = [
    '🏓', '⚡', '🔥', '🌟', '🎯', '🏅', '🥇', '👑',
    '🦊', '🐉', '🦈', '🦅', '🐺', '🦁', '🐸', '🎃',
    '❤️', '💙', '💚', '💜', '🧡', '💛', '🖤', '🤍',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _avatar = widget.existing?.avatar ?? '🏓';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: SparkTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? 'Edit Player' : 'New Player',
        style: const TextStyle(color: SparkTheme.accent),
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar picker
            CircleAvatar(
              radius: 36,
              backgroundColor: SparkTheme.surface,
              child: Text(_avatar, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _avatars.map((a) {
                final selected = a == _avatar;
                return GestureDetector(
                  onTap: () => setState(() => _avatar = a),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? SparkTheme.accent.withOpacity(0.2)
                          : Colors.transparent,
                      border: selected
                          ? Border.all(color: SparkTheme.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(a, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                hintText: 'e.g. Timo Boll',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<PlayerProvider>();
    if (widget.existing != null) {
      widget.existing!.name = name;
      widget.existing!.avatar = _avatar;
      provider.updatePlayer(widget.existing!);
    } else {
      provider.addPlayer(Player(name: name, avatar: _avatar));
    }
    Navigator.pop(context);
  }
}
