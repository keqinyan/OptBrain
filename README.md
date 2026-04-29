# OptBrain

A personal cognitive performance tracker for iOS. OptBrain helps users discover
*when* their brain performs best by capturing short cognitive tasks (reaction
time, Stroop, number order) and surfacing trends across time of day and recent
context. It is **not** a medical product and makes no diagnostic or
self-improvement claims.

> Positioning: a lightweight personal cognitive lab. Local-first, explainable,
> careful with language.

## A. Project structure

```
OptBrain/
├── App/                       # @main entry, root scene, navigation shell
│   └── OptBrainApp.swift
├── Models/                    # SwiftData models + value types
│   ├── TestType.swift
│   ├── Session.swift
│   └── Trial.swift
├── Persistence/               # ModelContainer wiring
│   └── PersistenceController.swift
├── Services/                  # Pure logic, no SwiftUI
│   ├── AnalyticsService.swift
│   ├── InsightsService.swift
│   ├── ExportService.swift
│   └── HealthKitService.swift
├── DesignSystem/              # Theme, reusable components
│   ├── Theme.swift
│   └── Components.swift
├── Features/
│   ├── Onboarding/OnboardingView.swift
│   ├── Home/HomeView.swift
│   ├── Insights/InsightsView.swift
│   ├── Settings/SettingsView.swift
│   └── Tests/
│       ├── ReactionTime/{ReactionTimeView,ReactionTimeViewModel}.swift
│       ├── Stroop/{StroopView,StroopViewModel}.swift
│       └── NumberOrder/{NumberOrderView,NumberOrderViewModel}.swift
└── Resources/
    ├── en.lproj/Localizable.strings
    └── zh-Hans.lproj/Localizable.strings
```

These Swift files are framework-only (SwiftUI + SwiftData + optional HealthKit).
To run: create a new Xcode iOS App target named `OptBrain`, drag this folder
into the project, set the deployment target to **iOS 17+**, and add the
HealthKit capability when you're ready to use it.

## G. Step-by-step implementation plan

1. **Bootstrap the Xcode project** — iOS 17 minimum, SwiftUI lifecycle,
   SwiftData enabled. Add the source files in this folder.
2. **Wire persistence** — `PersistenceController` exposes a `ModelContainer`
   for `Session` and `Trial`. Inject via `.modelContainer(...)` at the root.
3. **Onboarding flow** — first-launch only, sets `hasOnboarded` in
   `@AppStorage`. Explains the app's purpose and avoids medical framing.
4. **Home screen** — today's snapshot, weekly streak, three quick-start
   buttons routing into the test views.
5. **Reaction Time test** — random delay → color flip → tap; capture trial
   timestamps, false starts, missed trials.
6. **Stroop test** — color word with mismatched ink color; user picks ink
   color; record congruent/incongruent + RT + correctness.
7. **Number Order test** — N×N grid with shuffled `1..N²`; user taps in
   order; record completion time and mistakes.
8. **Persist sessions** — at end of each test, build a `Session` and `Trial`
   set, hand off to the model context, navigate back to Home.
9. **Analytics service** — speed (mean), accuracy, stability (SD/CV),
   fatigue (first half vs second half), time-of-day bucketing.
10. **Insights service** — rule-based, threshold-gated by sample size,
    careful copy ("your data suggests…").
11. **Settings** — language switch (App Language `String?` in
    `@AppStorage`), CSV/JSON export via `ExportService`, full-wipe action,
    privacy explanation.
12. **HealthKit (optional)** — `HealthKitService` shell with permission
    request and read accessors for sleep, steps, resting HR, HRV. Not
    required for MVP behavior.
13. **Localization** — English + Simplified Chinese strings live in
    `Resources/*.lproj/Localizable.strings`.
14. **Polish** — dark mode, dynamic type, haptics on test events, accessibility
    labels for all interactive elements.

See inline comments in each file for the contracts between layers.
