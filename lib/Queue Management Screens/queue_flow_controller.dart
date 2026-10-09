import 'package:flutter/foundation.dart';

class HealthQNotification {
  final String title;
  final String body;
  final String time;

  const HealthQNotification({
    required this.title,
    required this.body,
    required this.time,
  });
}

class QueueFlowController {
  QueueFlowController._();

  static final QueueFlowController instance =
      QueueFlowController._();

  final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);

  final List<HealthQNotification> notifications = [];

  int yourQueueNumber = 9;
  int currentQueueNumber = 7;
  int averageMinutesPerPatient = 2;

  int estimatedWaitMinutes = 25;
  int patientsAhead = 8;

  String doctorName = 'Dr. R. Fernando';
  String roomNumber = 'Room 03';

  bool appointmentCompleted = false;
  bool queueActive = true;

  int _nextGeneratedQueueNumber = 19;

  void _notify() {
    updateNotifier.value++;
  }

  String _formatTime() {
    final now = DateTime.now();

    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;

    final minute = now.minute.toString().padLeft(2, '0');

    final period = now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  void addNotification({
    required String title,
    required String body,
  }) {
    notifications.insert(
      0,
      HealthQNotification(
        title: title,
        body: body,
        time: _formatTime(),
      ),
    );

    _notify();
  }

  void completeAppointment() {
    appointmentCompleted = true;
    queueActive = false;

    addNotification(
      title: 'Appointment Completed',
      body:
          'You are on your way to the consultation. Your queue appointment has been completed.',
    );
  }

  void missedTurn() {
    queueActive = false;

    addNotification(
      title: 'Missed My Turn',
      body:
          'You did not respond within 5 minutes. Your queue position has been changed.',
    );
  }

  int generateNewQueuePosition() {
    final newPosition = _nextGeneratedQueueNumber;

    _nextGeneratedQueueNumber++;

    yourQueueNumber = newPosition;

    currentQueueNumber = newPosition - 2;

    patientsAhead = 10;

    estimatedWaitMinutes =
        patientsAhead * averageMinutesPerPatient;

    queueActive = true;
    appointmentCompleted = false;

    _notify();

    return newPosition;
  }

  void updateQueueDetails({
    required int queueNumber,
    required int currentNumber,
    required int waitMinutes,
    required int ahead,
  }) {
    yourQueueNumber = queueNumber;
    currentQueueNumber = currentNumber;
    estimatedWaitMinutes = waitMinutes;
    patientsAhead = ahead;

    queueActive = true;

    _notify();
  }

  void reset() {
    clear();
  }

  void clear() {
    notifications.clear();

    yourQueueNumber = 9;
    currentQueueNumber = 7;
    averageMinutesPerPatient = 2;
    estimatedWaitMinutes = 25;
    patientsAhead = 8;

    appointmentCompleted = false;
    queueActive = true;

    _notify();
  }
}