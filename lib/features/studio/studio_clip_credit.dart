import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/media_library.dart';
import '../../design/vimi_ui.dart';

class StudioClipCredit {
  const StudioClipCredit({
    required this.name,
    required this.handle,
    required this.caption,
    required this.bio,
    this.portraitId,
  });

  final String name, handle, caption, bio;
  final String? portraitId;

  static StudioClipCredit forClip(LibraryClip clip) =>
      _credits[clip.id] ??
      StudioClipCredit(
        name: 'Studio',
        handle: '@studio',
        caption: clip.title,
        bio: 'Dance practice clips.',
      );

  static List<LibraryClip> findClips(MediaLibrary library, String query) {
    final normalized = query.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final handleOnly = normalized.startsWith('@');
    final term = handleOnly ? normalized.substring(1).trim() : normalized;
    return library.clips.where((clip) {
      final credit = _credits[clip.id];
      if (credit == null) return false;
      return credit.handle.toLowerCase().contains(term) ||
          (!handleOnly && credit.name.toLowerCase().contains(term));
    }).toList();
  }

  // These are Studio bylines for the supplied library. Member posts use the
  // registered publisher's profile.
  static const _credits = <String, StudioClipCredit>{
    'open-air-group': StudioClipCredit(
      name: 'Eli Navarro',
      handle: '@elinavarro',
      portraitId: 'portrait-022',
      caption: 'An open-air group take with a finish worth replaying.',
      bio: 'Outdoor dance sessions and group formations.',
    ),
    'street-style-group': StudioClipCredit(
      name: 'Jordan Vale',
      handle: '@jordanvale',
      portraitId: 'portrait-001',
      caption:
          'A street-corner take that makes the walk-in part of the routine.',
      bio: 'Street routines with a soft spot for a good groove.',
    ),
    'night-plaza-solo': StudioClipCredit(
      name: 'Nyla Rose',
      handle: '@nylarose',
      portraitId: 'portrait-051',
      caption: 'Low light, quick footwork, and just enough room to move.',
      bio: 'Solo footwork, turns, and clean stops.',
    ),
    'studio-mirror': StudioClipCredit(
      name: 'Remy Park',
      handle: '@remypark',
      portraitId: 'portrait-047',
      caption: 'The mirror makes those little timing changes easier to catch.',
      bio: 'Mirror drills for details you catch on the second watch.',
    ),
    'holiday-duet': StudioClipCredit(
      name: 'Mina Reed',
      handle: '@minareed',
      portraitId: 'portrait-039',
      caption: 'Holiday lights and a chorus made for two.',
      bio: 'Duets with a soft spot for a familiar chorus.',
    ),
    'room-formation': StudioClipCredit(
      name: 'Kai Moreno',
      handle: '@kaimoreno',
      portraitId: 'portrait-030',
      caption: 'Watch how the spacing changes when the group switches places.',
      bio: 'Group covers and quick formation changes.',
    ),
    'evening-plaza-duet': StudioClipCredit(
      name: 'Cleo Bennett',
      handle: '@cleobennett',
      portraitId: 'portrait-018',
      caption: 'A quick two-person take before the last of the evening light.',
      bio: 'Partner timing and evening takes.',
    ),
    'studio-partner': StudioClipCredit(
      name: 'Avery Lin',
      handle: '@averylin',
      portraitId: 'portrait-033',
      caption: 'A partner run where the small cues do most of the work.',
      bio: 'Choreography made for two dancers.',
    ),
    'group-studio': StudioClipCredit(
      name: 'Jae Morgan',
      handle: '@jaemorgan',
      portraitId: 'portrait-014',
      caption: 'The formation change is worth a second watch.',
      bio: 'Studio group runs, clean lines, and sharp count-ins.',
    ),
    'hallway-take': StudioClipCredit(
      name: 'Rio Walsh',
      handle: '@riowalsh',
      portraitId: 'portrait-024',
      caption: 'A short hallway take with just enough room to hit the beat.',
      bio: 'Short routines for small spaces.',
    ),
  };
}

class StudioClipAvatar extends StatelessWidget {
  const StudioClipAvatar({super.key, required this.clip, required this.size});

  final LibraryClip clip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final credit = StudioClipCredit.forClip(clip);
    return FutureBuilder<MediaLibrary>(
      future: VimiScope.of(context).avatarLibrary,
      builder: (_, snapshot) {
        final photo = snapshot.data?.portraits
            .where((photo) => photo.id == credit.portraitId)
            .firstOrNull;
        return Avatar(
          name: credit.name,
          label: 'Studio profile photo',
          url: photo?.thumbnail,
          alignment: const Alignment(0, -.42),
          size: size,
        );
      },
    );
  }
}
