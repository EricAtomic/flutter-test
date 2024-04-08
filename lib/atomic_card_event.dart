/// Card events that the SDK can communicate back to the host app.
enum AACCardEventKind {
  /// A card was successfully submitted.
  submitted,

  /// A card was successfully dismissed.
  dismissed,

  /// A card was successfully snoozed.
  snoozed,

  /// A card was voted as useful.
  votedUseful,

  /// A card was voted as not useful.
  votedNotUseful,

  /// A card failed to submit, either due to an API error or lack of network connectivity.
  submitFailed,

  /// A card failed to dismiss, either due to an API error or lack of network connectivity.
  dismissFailed,

  /// A card failed to snooze, either due to an API error or lack of network connectivity.
  snoozeFailed
}

extension AACCardEventKindSerialzed on AACCardEventKind {
  String get stringValue {
    switch (this) {
      case AACCardEventKind.submitted:
        return "cardSubmitted";
      case AACCardEventKind.dismissed:
        return "cardDismissed";
      case AACCardEventKind.snoozed:
        return "cardSnoozed";
      case AACCardEventKind.votedUseful:
        return "cardVotedUseful";
      case AACCardEventKind.votedNotUseful:
        return "cardVotedNotUseful";
      case AACCardEventKind.submitFailed:
        return "cardSubmitFailed";
      case AACCardEventKind.dismissFailed:
        return "cardDismissFailed";
      case AACCardEventKind.snoozeFailed:
        return "cardSnoozeFailed";
    }
  }
}

/// An event pertaining to a card, such as when a card is submitted,
/// dismissed, snoozed or voted on.
class AACCardEvent {
  AACCardEvent.fromJson(Map<String, dynamic> jsonData)
      : kind = AACCardEventKind.values
            .firstWhere((element) => element.stringValue == jsonData["kind"]);
  final AACCardEventKind kind;
}

mixin AACCardEventDelegate {
  void didTriggerCardEvent(AACCardEvent event);
}
