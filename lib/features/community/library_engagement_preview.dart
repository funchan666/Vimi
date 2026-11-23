import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryEngagementPreview {
  const LibraryEngagementPreview._(this._clipId, this.likes, this._comments);

  static const enabled =
      !kReleaseMode && bool.fromEnvironment('VIMI_PREVIEW_ENGAGEMENT');

  static LibraryEngagementPreview? forClip(String clipId) {
    if (!enabled) return null;
    final example = _examples[clipId];
    if (example == null) return null;
    return LibraryEngagementPreview._(clipId, example.likes, example.comments);
  }

  final String _clipId;
  final int likes;
  final List<String> _comments;

  String _hiddenKey(String owner, int index) =>
      'library-engagement-preview.v1.${Uri.encodeComponent(owner)}.$_clipId.$index';

  List<({int index, String body})> visibleComments(
    SharedPreferences prefs,
    String owner,
  ) => [
    for (var index = 0; index < _comments.length; index++)
      if (prefs.get(_hiddenKey(owner, index)) != true)
        (index: index, body: _comments[index]),
  ];

  Future<void> hideComment(
    SharedPreferences prefs,
    String owner,
    int index,
  ) async {
    if (index < 0 || index >= _comments.length) return;
    final key = _hiddenKey(owner, index);
    if (prefs.get(key) == true) return;
    try {
      if (await prefs.setBool(key, true)) return;
    } catch (_) {}
    // SharedPreferences can change its local cache before the write succeeds.
    await prefs.remove(key);
    throw const FileSystemException(
      'Could not hide this Studio note. Try again.',
    );
  }

  // Keep comment positions stable because the indexes are stored on the device.
  static const _examples = <String, ({int likes, List<String> comments})>{
    'open-air-group': (
      likes: 118,
      comments: [
        'Try marking each spot on the floor before dancing the whole formation.',
        'I would practice the travel first and add the arms on the second pass.',
        'Counting the last eight aloud makes the group ending easier to line up.',
        'Film from far enough back to see the full spacing between dancers.',
        'The step into the next formation is worth looping on its own.',
        'Pick a starting cue everyone can catch without looking down.',
      ],
    ),
    'street-style-group': (
      likes: 91,
      comments: [
        'Start with the groove before trying to match every arm accent.',
        'I would keep the first run loose and sharpen the stops on the next one.',
        'A wide take is handy when the group rehearses the direction changes.',
        'Count the offbeats out loud when practicing the quick steps.',
      ],
    ),
    'night-plaza-solo': (
      likes: 64,
      comments: [
        'For night practice, record a short test so you can still see your feet.',
        'Loop the entry and exit together to check that your weight transfers cleanly.',
      ],
    ),
    'studio-mirror': (
      likes: 163,
      comments: [
        'I use the mirror for the hand angles, then try one pass looking forward.',
        'Practice the arm sequence at half speed before adding footwork.',
        'Put a marker at your starting spot so you can check how far you travel.',
        'Looping one eight-count makes small timing slips easier to hear.',
        'Try a side view if the front angle makes the shoulder movement hard to see.',
        'Keep your knees soft when the steps get faster.',
        'Save a full-speed take to compare with the slow rehearsal.',
      ],
    ),
    'holiday-duet': (
      likes: 214,
      comments: [
        'Agree on a cue for the first step so neither partner has to guess.',
        'Rehearse the hand timing without the footwork once.',
        'I would mark the distance between partners before filming.',
        'Check the entry from both sides of the frame.',
        'Give yourselves one count to reset between practice loops.',
        'Try one pass facing the same direction to learn the steps.',
        'A quick glance can be a better cue than counting louder.',
        'Play it back slowly to see whether both arms hit together.',
        'Keep the groove going even when you start on different feet.',
        'Finish the final count together before you relax the pose.',
      ],
    ),
    'room-formation': (
      likes: 132,
      comments: [
        'Use tape marks for the middle and the two outer spots.',
        'Walk through the crossings before adding the choreography.',
        'Each dancer can pick a landmark to avoid drifting during the change.',
        'Film from the front to see whether the diagonals line up.',
        'Practice entering the formation from the last two counts before it.',
      ],
    ),
    'evening-plaza-duet': (
      likes: 105,
      comments: [
        'Use a shared breath to cue the start when the music is hard to hear.',
        'Check that your partner is in view before starting the take.',
        'I would rehearse the turn with extra space and close the gap later.',
      ],
    ),
    'studio-partner': (
      likes: 147,
      comments: [
        'Decide who leads each change before you work up to full speed.',
        'Rehearse one side with a mirror and one side without it.',
        'Try the hand cue at half tempo so it feels natural later.',
        'Check the distance between you in the turn.',
        'Keep the transitions as light as the first few steps.',
        'Film one take from farther back to compare pathways.',
        'Slow the video down to catch differences in the arm timing.',
        'Try ending on the same count even if your shapes are different.',
      ],
    ),
    'group-studio': (
      likes: 186,
      comments: [
        'Have everyone clap the accents once before you dance them.',
        'A wide angle helps check who drifts out of the line.',
        'Work on one row at a time if the group is still learning the steps.',
        'Practice the formation change without music before the first full take.',
        'Ask the dancers in back whether they can still see the cue.',
        'Start the loop a count early so you can practice arriving on time.',
        'Keep a short note about the trickiest crossing for the next rehearsal.',
        'Watch the feet first, then replay to check the arm lines.',
        'Use the last pose as a clean stopping point between runs.',
      ],
    ),
    'hallway-take': (
      likes: 47,
      comments: [
        'Break the short phrase in two and link it when both halves feel easy.',
      ],
    ),
  };
}
