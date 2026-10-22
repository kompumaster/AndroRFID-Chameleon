import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/openspool/openspool_data.dart';
import '../openspool/openspool_page.dart';
import '../qidi/qidi_page.dart';
import '../widgets/l_text.dart';

enum _TagSelection { qidi, openspool, snapmakerU1 }

class TagPage extends StatelessWidget {
  const TagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selection = switch ((appState.mode, appState.openspoolProfile)) {
      (TagMode.qidi, _) => _TagSelection.qidi,
      (TagMode.openspool, OpenSpoolProfile.u1) =>
        _TagSelection.snapmakerU1,
      _ => _TagSelection.openspool,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<_TagSelection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _TagSelection.qidi,
                label: LText('QIDI'),
              ),
              ButtonSegment(
                value: _TagSelection.openspool,
                label: LText('OpenSpool'),
              ),
              ButtonSegment(
                value: _TagSelection.snapmakerU1,
                label: LText('Snapmaker U1'),
              ),
            ],
            selected: {selection},
            onSelectionChanged: (value) {
              final state = context.read<AppState>();
              switch (value.first) {
                case _TagSelection.qidi:
                  state.mode = TagMode.qidi;
                  break;
                case _TagSelection.openspool:
                  state.mode = TagMode.openspool;
                  state.openspoolProfile = OpenSpoolProfile.standard;
                  if (state.openspoolTier == OpenSpoolTier.all) {
                    state.openspoolTier = OpenSpoolTier.standard;
                  }
                  break;
                case _TagSelection.snapmakerU1:
                  state.mode = TagMode.openspool;
                  state.openspoolProfile = OpenSpoolProfile.u1;
                  if (state.openspoolTier == OpenSpoolTier.basic) {
                    state.openspoolTier = OpenSpoolTier.standard;
                  }
                  break;
              }
            },
          ),
        ),
        Expanded(
          child: appState.mode == TagMode.qidi
              ? const QidiPage()
              : const OpenSpoolPage(),
        ),
      ],
    );
  }
}
