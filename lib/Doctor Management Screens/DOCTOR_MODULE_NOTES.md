# Doctor module – handover notes

## 0. First thing to do
I could not run `flutter analyze` / build in my environment (Dart SDK downloads are blocked there).
The code was checked with a Dart parser (all 18 files parse), a custom cross-reference check (imports,
member names, constructor arguments, all `AppColors.*` tokens exist), a scan for illegal `const`
expressions, and a byte-for-byte diff against your original zip. That catches most mistakes but is **not a compiler**.

    flutter pub get
    flutter analyze lib/Doctor\ Management\ Screens lib/services

If anything shows up, send me the exact message and I'll fix it.

## 1. Nothing of your teammates was touched
32 original files are byte-identical (main.dart, terms_screen.dart, booking_service.dart, staff_auth_service.dart,
email_service.dart, every Patient / OPD / common screen, theme).
Changed or added files are only inside `Doctor Management Screens/` and `services/doctor_*.dart`.
`DoctorDashboardScreen`'s constructor is unchanged, so `terms_screen.dart` still works as-is.
No new packages: `pubspec.yaml` does not need to change.

## 2. Mockup → screen map
| Mockup | File |
|---|---|
| dashboard-pro | `doctor_home_screen.dart` |
| appointments-pro | `doctor_appointments_screen.dart` |
| queue-pro | `doctor_queue_screen.dart` |
| patient-details-pro + patient-medical-history | `doctor_patient_details_screen.dart` (Overview / History / Appointments tabs) |
| consultation | `doctor_consultation_screen.dart` |
| doctor-profile | `doctor_profile_screen.dart` |
| edit-doctor-profile | `doctor_edit_profile_screen.dart` |
| available-time-slots | `doctor_availability_screen.dart` |
| request-availability-change | `doctor_request_change_screen.dart` |
| request-submitted | `doctor_request_submitted_screen.dart` |
| my-availability-requests | `doctor_availability_requests_screen.dart` |
| request-details | `doctor_request_details_screen.dart` |
Shell: `doctor_dashboard_screen.dart`. Shared widgets/formatters: `doctor_ui.dart`.

## 3. Architecture
* Each bottom tab has its own Navigator, so detail screens open inside the tab and the bottom bar stays visible (as in the designs). Android back closes detail → Home → exits.
* Every screen reads the logged-in doctor from `DoctorSessionScope` (live profile stream), so editing the profile updates all screens instantly.
* `terms_screen.dart` only passes name / staffId / hospital, so specialty, room, email, phone, department are loaded from `staff/{staffId}` automatically.

## 4. Bugs fixed in the old doctor code
* `Navigator.pop()` on the Appointments tab popped the whole dashboard (black screen).
* Initials code `w[0]` threw `RangeError` on names with double spaces.
* Search typing re-created the Firestore stream on every keystroke (spinner flicker); 4 listeners per screen → 1.
* "Complete" could mark two patients as `next`; it used a stale list from the UI. Transitions now re-read Firestore and run in one batch.
* Notes were saved and then completed in 2 separate writes; now one atomic write.
* Consultation pre-selected "Common Cold" as diagnosis (safety risk). Now an explicit choice; "Other" has a text box.
* Request status overwrote the slot's real status ("Available" was lost). Now the slot keeps its real status and the request state is stored separately; status only changes after approval.
* Hard-coded "AM", fake "18 Scheduled / 3 Pending / today+14d" – now real data.
* Logout went to the patient login; now rebuilds LoginScreen → StaffLoginScreen so "Back to Patient Login" works.
* Dropdowns can no longer assert when the stored value is not in the preset list.

## 5. Firestore contract (doctor-owned collections)
* `doctor_appointments` – existing; added optional `patientPhone`, `source`, `bookingId`, `startedAt`, `completedAt`.
* `doctor_availability/{doctorId}_{date}_{HHmm}` – `status` (available|unavailable, **effective**), `requestStatus` (none|pending|approved|rejected), `requestedStatus`, `requestId`.
* `availability_requests/{REQ-yyyy-NNNN}` – doctorId, doctorName, hospital, slotId, date, startTime, endTime, currentStatus, requestedStatus, reason, status (pending|approved|rejected|cancelled), submittedAt, reviewedAt/By/Note.
* `patient_records/{patientId}` – name, gender, age, phone, address, bloodGroup, overview[], allergies[], conditions[], medications[], visits[] (each `{title, subtitle, details?}`).
* Writes into teammates' `staff/{id}`: only `name, specialty, department, email (lower-case), contactNo, avatarColor, bookingDoctorId, updatedAt`. A staff document is never created.
* All queries use equality filters only → **no composite indexes needed**.

## 6. Link to patient bookings (new)
Patient bookings live in `appointments`, the doctor module in `doctor_appointments`, so they never met.
`DoctorService.startBookingSync` now watches today's `appointments` (read-only) and copies bookings for this doctor into
`doctor_appointments` (`bk_<bookingId>`, idempotent, never overwrites doctor edits). Matching is by doctor name, then remembered as
`staff.bookingDoctorId` so renaming the doctor later does not break it. Time is derived from session + queue number (Morning 09:00, Evening 16:00, 15 min each).

## 7. Suggestions (most important first)
1. **Security – rotate the Gmail app password.** `services/email_service.dart` (line 20) contains it in plain text; anyone with the zip/repo has it. Move it to a backend/Cloud Function or at least `--dart-define`.
2. **Staff passwords are stored in plain text** in `staff` and staff are not Firebase Auth users, so Firestore rules cannot tell a doctor from anyone else. Move staff to Firebase Auth (custom claims `role: doctor`) and lock the rules down.
3. **Hospital-staff approval side is missing** (OPD screens have no Firestore). Ready for them: `DoctorAvailabilityService.resolveRequest(requestId:, approve:, reviewerName:, note:)` – listen to `availability_requests where status == 'pending'`.
4. **Close the loop to patients:** when a consultation completes, also set `appointments/{bookingId}.status = 'completed'` so patients see it (needs the patient-side owner's OK; I did not write to their collection).
5. Add a `doctorId` field to hospital doctors / staff documents; name matching (section 6) is only a fallback.
6. `terms_screen.dart`: could pass only `staffId` now; the rest is loaded live.
7. Demo data: set `DoctorService.enableDemoSeed = false` before release (seeds sample patients when a doctor has no appointments today).
8. Real photo upload needs `image_picker` + `firebase_storage` in pubspec. Until then "Change Photo" lets the doctor pick an avatar colour; `DoctorAvatar` already shows `photoUrl` if one is stored.

## 8. Deliberate differences from the mockups
* The two patient-detail frames used different tab-bar styles; unified to the underline style (title switches to "Patient Medical History" on the History tab).
* Mockups were inconsistent (diabetes 2020 vs 2022, "no drug allergies" vs penicillin); demo data was made consistent and the Overview "Allergies" row is computed from the allergy list.
* Edit-profile / consultation frames highlight "Home"; the owning tab is highlighted instead.
* Requests list got a "Rejected" filter chip; cancelled requests are supported.
* Hamburger icon on the Queue header is decorative (there is no drawer in the app).
* "View Calendar" opens a date picker, then that day's slots.
