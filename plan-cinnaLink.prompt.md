## Plan: CinnaLink OOSD MVP

Implement the proposal as a Firebase-backed Flutter MVP that respects the OO analysis model: `User` as the shared profile/auth root, role-specialized worker and landowner behavior, workflow entities for `Job`, `Application`, `Schedule`, `Task Progress Record`, `Rating and Feedback`, `Worker Group`, and `Verification Profile`. The recommended approach is to map these entities into a small domain/repository layer first, then replace the current hardcoded UI flows with Firestore-backed workflows that preserve the proposal’s original rule that a worker may need to choose one job when multiple approvals occur.

**Steps**
1. Phase 1 - Domain and Firestore design. Define entity-to-data mappings for users, landowners, workers, worker groups, jobs, applications, schedules, task progress records, ratings, and verification profiles. Explicitly model OO responsibilities from the proposal so the code can express operations such as `applyForJob`, `approveWorker`, `recordDailyProgress`, `chooseJob`, and schedule overlap validation. This step blocks all later work.
2. Create a thin repository/service layer in `d:/Project/CinnaLink/lib/` that encapsulates Firestore reads, writes, and workflow checks. Keep authentication/profile concerns in `d:/Project/CinnaLink/lib/auth.dart`, but move job, application, schedule, progress, and rating behavior out of widgets. This step depends on step 1.
3. Phase 2 - Profiles and verification. Extend the current user profile flow so workers and landowners can store role-specific fields from the OO model, including NIC and verification-related information. Add verification profile persistence as data capture/status only for MVP unless an external verification process is later introduced. This step depends on step 2.
4. Refactor `d:/Project/CinnaLink/lib/job_posting_page.dart` so landowners can create, edit, and close jobs backed by Firestore. Job records should include type, required workers, start/end dates, payment rate, location, status, expected output context, and cumulative yield fields needed for later progress tracking. This step depends on steps 1 and 2.
5. Refactor `d:/Project/CinnaLink/lib/worker_dashboard.dart` `FindJobsPage` so workers and group coordinators can browse real jobs, apply, withdraw applications, and view pending decision states instead of static snackbars and mock data. This step depends on step 4.
6. Phase 3 - Approval workflow and decision windows. Implement the proposal’s original application lifecycle: landowner approves one or more applicants, approved workers can see pending decisions, and if a worker receives multiple approvals the worker must choose one within a defined decision window. Add application statuses and deadlines so expiration, acceptance, and decline paths are explicit. This step depends on steps 2, 4, and 5.
7. Add `Schedule` handling as the availability source of truth. Confirmed acceptances create schedule records, and overlap checks should be used both before applying and before accepting a job. This implements the OO examples around encapsulated schedule validation and prevents double booking without reducing everything to a single boolean availability flag. This step depends on step 6.
8. Phase 4 - Worker groups. Add group creation and membership management, group coordinator actions, group applications, and group-level scheduling. Approval and acceptance logic must account for all members when checking overlap and when creating schedules. This step depends on steps 1, 2, 5, 6, and 7.
9. Phase 5 - Task progress and cumulative yield. Add daily progress reporting tied to jobs so workers or group coordinators can record production progress, including quill/output measures described in the proposal. Landowners should be able to view job progress and cumulative yield up to the current day. This step depends on accepted jobs and schedule state from steps 6 and 7.
10. Add mutual rating and feedback after job completion. Use completed job records to open role-specific rating flows for workers and landowners, then update aggregate profile metrics such as rating score, completed job count, and reliability indicators. This step depends on step 9 or, at minimum, on a job completion flow from earlier phases.
11. Phase 6 - History and analytics. Build worker and landowner history views using completed jobs, schedule records, progress totals, and rating aggregates. Keep analytics operational and MVP-sized: completion history, reliability, output totals, and basic workforce efficiency indicators. This step depends on steps 9 and 10.
12. Phase 7 - Navigation integration and polish. Update `d:/Project/CinnaLink/lib/main.dart`, `d:/Project/CinnaLink/lib/landowner_dashboard.dart`, `d:/Project/CinnaLink/lib/worker_dashboard.dart`, and `d:/Project/CinnaLink/lib/account_settings_page.dart` so the new features fit the existing role-based structure without a full rewrite. This step depends on prior phases and should remain incremental.
13. Add targeted tests and verification per phase, especially for job creation rules, application state transitions, schedule overlap checks, decision deadline handling, group scheduling conflicts, progress aggregation, and rating summaries. This step can be done incrementally once each feature exists.

**Relevant files**
- `d:/Project/CinnaLink/lib/auth.dart` — keep shared auth/profile bootstrap and role detection; extend only for profile/verification consistency.
- `d:/Project/CinnaLink/lib/main.dart` — preserve `AuthGate` and app shell while integrating new loading and routing states.
- `d:/Project/CinnaLink/lib/job_posting_page.dart` — convert placeholder landowner posting UI into real create/edit/close job management.
- `d:/Project/CinnaLink/lib/worker_dashboard.dart` — replace hardcoded find-jobs and approved-jobs lists with live application, decision, active-job, and history sections.
- `d:/Project/CinnaLink/lib/worker_scheduling_page.dart` — evolve from mock scheduling into landowner views for approvals, schedules, and progress monitoring.
- `d:/Project/CinnaLink/lib/account_settings_page.dart` — preserve current settings flow while extending role-specific profile and verification fields.
- `d:/Project/CinnaLink/pubspec.yaml` — add only minimal support packages if the implementation requires date formatting or model serialization helpers.

**Verification**
1. Validate the Firestore schema and role-based permissions for users, jobs, applications, schedules, progress records, ratings, groups, and verification profiles.
2. Validate the worker flow: register, complete profile, browse jobs, apply, receive one or multiple approvals, choose one within the deadline, and see schedule updates.
3. Validate the landowner flow: create job, edit/close job, review applicants, approve candidates, monitor accepted workers, and track daily progress and cumulative yield.
4. Validate conflict prevention by creating overlapping jobs and confirming `validateBeforeApply` and `validateBeforeAccept` style checks behave correctly.
5. Validate group behavior by approving a group and confirming every member’s schedule and conflict state update correctly.
6. Validate completion, ratings, and analytics by completing jobs with progress data and confirming aggregates update in history views.
7. Run Flutter analysis and focused tests after each phase rather than deferring all verification to the end.

**Decisions**
- Latest source of truth: this OO analysis supersedes the earlier simplified assumption that landowner approval immediately locks the worker.
- Included in scope: worker and landowner profiles, worker groups, multi-approval decision handling, schedules, daily task progress, cumulative yield tracking, ratings, analytics, and verification profile capture.
- Backend assumption: Firebase Auth plus Cloud Firestore only for MVP; no custom backend/API.
- Recommended MVP boundary: verification should start as profile/document status capture, not full manual review tooling or third-party identity validation.
- Recommended MVP boundary: analytics should remain operational summaries derived from jobs, schedules, progress, and ratings rather than advanced forecasting.
- Recommended MVP boundary: payment should remain recorded job payment data and history, not payment gateway integration.

**Further Considerations**
1. Firestore security rules are still not visible in the current workspace. They should be designed alongside repositories because schedule and approval integrity cannot rely on client widgets alone.
2. The OO model uses class terminology such as superclass, subclass, and entity methods. In Flutter/Dart implementation, mirror these concepts through models and services without forcing unnecessary inheritance if composition produces simpler, safer code.
3. Offline data entry support appears in the non-functional requirements. For MVP planning, treat it as optional deferred support unless the team explicitly wants Firestore offline caching and conflict behavior included in the first build.
