import 'dart:async';

import 'package:flutter/foundation.dart';

class QueueNotification {
  final String title;
  final String body;
  final DateTime time;
  final bool important;

  const QueueNotification({
    required this.title,
    required this.body,
    required this.time,
    this.important = false,
  });
}

class QueueFlowController extends ChangeNotifier {
  QueueFlowController._();

  static final QueueFlowController instance = QueueFlowController._();

  // ------------------------------------------------------------
  // QUEUE SETTINGS
  // ------------------------------------------------------------

  int yourQueueNumber = 9;

  int currentQueueNumber = 9;

  int patientsAhead = 8;

  int averageMinutesPerPatient = 2;

  int initialWaitingMinutes = 12;

  int remainingWaitingSeconds = 12 * 60;

  // ------------------------------------------------------------
  // FLOW STATE
  // ------------------------------------------------------------

  bool isWaiting = true;
  bool isMyTurn = false;
  bool isMissedTurn = false;
  bool isCompleted = false;
  bool isOnMyWay = false;

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------

  final List<QueueNotification> notifications = [];

  Timer? _waitingTimer;
  Timer? _turnTimer;

  bool _started = false;

  List<QueueNotification> get latestNotifications =>
      List.unmodifiable(notifications);

  int get remainingMinutes =>
      (remainingWaitingSeconds / 60).ceil();

  double get waitingProgress {
    if (initialWaitingMinutes <= 0) {
      return 0;
    }

    final totalSeconds = initialWaitingMinutes * 60;

    return (remainingWaitingSeconds / totalSeconds)
        .clamp(0.0, 1.0);
  }

  // ------------------------------------------------------------
  // START QUEUE FLOW
  // ------------------------------------------------------------

  void startQueueFlow() {
    if (_started) {
      return;
    }

    _started = true;

    isWaiting = true;
    isMyTurn = false;
    isMissedTurn = false;
    isCompleted = false;
    isOnMyWay = false;

    remainingWaitingSeconds =
        initialWaitingMinutes * 60;

    _startWaitingTimer();

    notifyListeners();
  }

  void _startWaitingTimer() {
    _waitingTimer?.cancel();

    _waitingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!isWaiting) {
          return;
        }

        if (remainingWaitingSeconds > 0) {
          remainingWaitingSeconds--;

          notifyListeners();
        }

        if (remainingWaitingSeconds <= 0) {
          _waitingTimer?.cancel();
          showMyTurn();
        }
      },
    );
  }

  // ------------------------------------------------------------
  // MY TURN
  // ------------------------------------------------------------

  void showMyTurn() {
    if (isMyTurn || isCompleted || isMissedTurn) {
      return;
    }

    _waitingTimer?.cancel();

    isWaiting = false;
    isMyTurn = true;
    isMissedTurn = false;
    isCompleted = false;
    isOnMyWay = false;

    addNotification(
      title: 'It’s Your Turn',
      body: 'Please proceed to Room 03 for your consultation.',
      important: true,
    );

    _startFiveMinuteTurnTimer();

    notifyListeners();
  }

  void _startFiveMinuteTurnTimer() {
    _turnTimer?.cancel();

    _turnTimer = Timer(
      const Duration(minutes: 5),
      () {
        if (isMyTurn && !isOnMyWay && !isCompleted) {
          missedTurn();
        }
      },
    );
  }

  // ------------------------------------------------------------
  // ON MY WAY
  // ------------------------------------------------------------

  void onMyWay() {
    if (!isMyTurn) {
      return;
    }

    _turnTimer?.cancel();

    isMyTurn = false;
    isWaiting = false;
    isOnMyWay = true;
    isCompleted = true;
    isMissedTurn = false;

    addNotification(
      title: 'Appointment Completed',
      body:
          'Your appointment has been completed successfully.',
      important: true,
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // NEED MORE TIME
  // ------------------------------------------------------------

  void needMoreTime() {
    if (!isMyTurn) {
      return;
    }

    _turnTimer?.cancel();

    missedTurn();

    notifyListeners();
  }

  // ------------------------------------------------------------
  // MISSED TURN
  // ------------------------------------------------------------

  void missedTurn() {
    _waitingTimer?.cancel();
    _turnTimer?.cancel();

    isWaiting = false;
    isMyTurn = false;
    isMissedTurn = true;
    isCompleted = false;
    isOnMyWay = false;

    addNotification(
      title: 'Missed My Turn',
      body:
          'You did not respond within 5 minutes. Your queue turn has been marked as missed.',
      important: true,
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // NOTIFICATION
  // ------------------------------------------------------------

  void addNotification({
    required String title,
    required String body,
    bool important = false,
  }) {
    notifications.insert(
      0,
      QueueNotification(
        title: title,
        body: body,
        time: DateTime.now(),
        important: important,
      ),
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  void reset() {
    _waitingTimer?.cancel();
    _turnTimer?.cancel();

    _waitingTimer = null;
    _turnTimer = null;

    _started = false;

    yourQueueNumber = 9;
    currentQueueNumber = 9;
    patientsAhead = 8;

    averageMinutesPerPatient = 2;

    initialWaitingMinutes = 12;

    remainingWaitingSeconds =
        initialWaitingMinutes * 60;

    isWaiting = true;
    isMyTurn = false;
    isMissedTurn = false;
    isCompleted = false;
    isOnMyWay = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _waitingTimer?.cancel();
    _turnTimer?.cancel();

    super.dispose();
  }
}