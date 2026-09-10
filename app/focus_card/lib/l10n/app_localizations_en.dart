// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome1Title => 'Your status card';

  @override
  String get welcome1Desc =>
      'Sticks to the back of your phone. No battery, no charging.\nOnce refreshed, the image stays forever.';

  @override
  String get welcome2Title => 'Flip to write';

  @override
  String get welcome2Desc =>
      'Pick a state, flip your phone onto the card.\nSeconds later the card shows your current state.';

  @override
  String get welcome3Title => 'An automatic log';

  @override
  String get welcome3Desc =>
      'Every switch leaves a record.\nSee exactly how long you focused.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get bindDiscovering => 'Meet your card';

  @override
  String get bindDiscoverHint => 'Hold your phone onto the card…';

  @override
  String get bindMockNote => '(Demo mode: simulated discovery)';

  @override
  String get bindFound => 'Card found';

  @override
  String get bindUidPrefix => 'ID';

  @override
  String get bindNameLabel => 'Name it';

  @override
  String get bindNameHelper => 'Skipped = default name';

  @override
  String get bindDefaultName => 'My Focus Card';

  @override
  String get bindComplete => 'Bind';

  @override
  String get bindDone => 'Bound';

  @override
  String get bindDoneSub => 'This card is yours now';

  @override
  String get demoBanner =>
      'Demo mode · simulated writes, no real card connected';

  @override
  String get tabStatus => 'Status';

  @override
  String get tabRecords => 'Log';

  @override
  String get statusTitle => 'Status';

  @override
  String get nowLabel => 'Now';

  @override
  String get notWritten => 'Not on card yet';

  @override
  String get notWrittenHint => 'Pick a state below, flip to write';

  @override
  String writtenAt(String time) {
    return 'Written at $time';
  }

  @override
  String get switchTitle => 'Switch state';

  @override
  String get onCard => 'on card';

  @override
  String since(String time) {
    return 'since $time';
  }

  @override
  String get flipHint => 'flip to write';

  @override
  String get menuAbout => 'About';

  @override
  String get menuProfile => 'Card profile (M4)';

  @override
  String get menuUnbind => 'Unbind card (M3)';

  @override
  String get menuLanguage => 'Language';

  @override
  String get aboutTagline =>
      'Status card, focus first — make your state visible';

  @override
  String get writeTitleCard => 'Card preview';

  @override
  String get writeTitle => 'Write to card';

  @override
  String get guideAuto =>
      'Flip your phone onto the card — writing automatically';

  @override
  String get guideMock => 'Demo mode: tap \"Write to card\" to simulate';

  @override
  String get mockFailToggle => 'Simulate write failure';

  @override
  String get guideManual => 'Flip your phone onto the card';

  @override
  String get addMessageFirst => 'Add a message first?';

  @override
  String get messageLabel => 'Message (optional)';

  @override
  String get messageHelper => 'e.g. Available after 15:30';

  @override
  String messageTooLong(int max) {
    return 'Message max $max chars';
  }

  @override
  String get writing => 'Writing…';

  @override
  String get writeButton => 'Write to card';

  @override
  String get retry => 'Retry';

  @override
  String get updated => 'Updated';

  @override
  String updatedSub(String state) {
    return 'Card now shows \"$state\"';
  }

  @override
  String get recordsTitle => 'Log';

  @override
  String get recordsBuilding =>
      'Stats page under construction (M2) — sessions are being logged silently';

  @override
  String get recordedSessions => 'recorded sessions';

  @override
  String get recordsEmpty =>
      'Switch a state once and your first session appears here';

  @override
  String get focusToday => 'Focus today';

  @override
  String streakDays(int n) {
    return '$n-day streak';
  }

  @override
  String get sessionsHeader => 'Sessions';

  @override
  String get todayEmpty => 'No sessions yet today';

  @override
  String get openSessionTitle => 'Still focusing?';

  @override
  String openSessionBody(String state, String time) {
    return 'Card has shown \"$state\" since $time.';
  }

  @override
  String get retryHint => 'Remove the card, tap retry, then tap again';

  @override
  String get endNow => 'End it now';

  @override
  String get stillGoing => 'Still going';

  @override
  String get profileSheetTitle => 'Card profile';

  @override
  String get nameField => 'Name';

  @override
  String get titleField => 'Title';

  @override
  String get qrField => 'QR content';

  @override
  String get qrHelper => 'URL or text — rendered as QR on the card';

  @override
  String get save => 'Save';

  @override
  String get errTimeout =>
      'Can\'t read the card — press the phone firmly on the card center and retry';

  @override
  String get errCapacity =>
      'Content exceeds card capacity — try a shorter message';

  @override
  String get errReadOnly => 'Card is write-protected';

  @override
  String get errNotNdef =>
      'Not a writable NDEF card (encrypted / bank / access card)';

  @override
  String get errCanceled => 'Write canceled';

  @override
  String get errNfcDisabled => 'NFC is off — enable it in system settings';

  @override
  String get errTagLost => 'Card moved during write — hold still and retry';

  @override
  String get errUnknown => 'Write failed — please retry';
}
