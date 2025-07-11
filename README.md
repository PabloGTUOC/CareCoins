# CareCoins

CareCoins is a Flutter application backed by Supabase. The project rewards care actions in a family setting by giving members "CareCoins" for their efforts. This repository contains the Flutter client code.

## Features

- Google or email authentication using Supabase
- Family setup flow to join or create a family
- Dashboard showing family members ordered by balance and a calendar of activities
- Login history recorded in Supabase

## Getting Started

1. **Install Flutter** – Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install) for your platform.
2. **Clone this repository**:
   ```bash
   git clone <repo-url>
   cd CareCoins
   ```
3. **Configure Supabase credentials** – Update `lib/main.dart` with your own Supabase URL and `anonKey`.
4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── screens/       # UI pages (landing, email auth, family setup, home)
├── services/      # Authentication and other helpers
└── main.dart      # Entry point initializing Supabase and loading AuthGate
```

Platform-specific folders (`android/`, `ios/`, `web/`, etc.) are generated by Flutter and contain build files for each platform.

## User Journey Overview

1. Launching the app shows the landing page with Google sign‑in and email options.
2. After authentication, new users are inserted into the `users` table and start the family setup flow if they have no `family_id`.
3. Returning users with a `family_id` go directly to the dashboard showing their balance and family information.
4. Logging out updates the last login entry with a session duration and signs the user out.

## Notes

- The project includes a placeholder `test/widget_test.dart` but has no custom tests.
- Supabase functions (`join-family-search`, `create-family`) must be deployed to your Supabase project for full functionality.
- Google sign‑in may require configuring the `redirectTo` URL in `landing_page.dart` for web builds.

## Edge Function Payloads

The `create-family` Supabase Edge Function now expects each actor record to include a `type`:

```json
{
  "family_name": "<string>",
  "role": "<string>",
  "actors": [
    {"name": "<actor name>", "type": "<actor type>"}
  ]
}
```

Update your edge function implementation to read the `type` field for each actor when creating the family.

