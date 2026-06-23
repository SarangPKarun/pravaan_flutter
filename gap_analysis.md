# Pravaan Flutter — Gap Analysis (Updated)

> **App context:** Pravaan is a habit-quitting app (smoking, alcohol, etc.).
> It tracks streaks, money saved, health recovery milestones, and provides
> craving-SOS tools and a marketplace for wellness products.

---

## Status Legend
| Symbol | Meaning |
|--------|---------|
| ✅ | Complete & production-ready |
| 🔨 | Built this session — functional |
| ⚠️ | Exists but needs revision |
| ❌ | Missing / stub only |

---

## Screen-by-Screen Status

### 1. Splash Screen
**Route:** app launch (before `/login`)

| Element | Status |
|---------|--------|
| App logo + tagline | ❌ Missing — no splash screen file exists |
| Animated loading indicator | ❌ Missing |
| Route: auto-navigate to `/login` or `/home` | ❌ No `/splash` route in router |

**What to build:**
- [ ] `lib/features/splash/screens/splash_screen.dart`
- [ ] Register `/splash` as `initialLocation` in `app_router.dart`
- [ ] Logo mark + "Pravaan" wordmark + tagline animation
- [ ] After ~2s: redirect based on auth state (login / onboarding / home)

---

### 2. Login Screen
**Route:** `/login`

| Element | Status |
|---------|--------|
| Email + password fields | ✅ Done |
| Google Sign-In button with G logo | ✅ Done |
| Forgot password link + dialog | ✅ Done |
| Sign Up toggle | ✅ Done |
| Gradient background + glass card | ✅ Done |
| App branding (logo + wordmark) | ✅ Done |
| Error snackbar | ✅ Done |

**Remaining:**
- [ ] Google OAuth Android config (`google-services.json`, intent filter, redirect URI)

---

### 3. Onboarding — 3 Steps
**Route:** `/onboarding`

> ⚠️ **The onboarding built this session is wrong** — it collects name/goals/activity.
> The actual spec requires: **habit type → quantity+cost → goal+date+savings**.
> The existing `onboarding_screen.dart` needs to be **replaced**.

| Step | What it collects | Status |
|------|-----------------|--------|
| Step 1 | **Habit type grid** — e.g. Smoking, Alcohol, Vaping, Sugar, Social media | ❌ Wrong content |
| Step 2 | **Quantity + cost inputs** — how many per day, cost per unit | ❌ Wrong content |
| Step 3 | **Goal + quit date + projected savings** — target date, savings preview | ❌ Wrong content |

**What to build (replace current onboarding):**
- [ ] Step 1: Full-screen habit type selector grid (icon tiles, single-select)
- [ ] Step 2: Number inputs for daily quantity + cost per item; auto-calculate daily spend
- [ ] Step 3: Goal date picker + live "projected savings" card (computed from Step 2 data)
- [ ] `onboarding_provider.dart` — keep the `complete()` + `is_onboarded: true` logic ✅
- [ ] Save `habit_type`, `daily_qty`, `unit_cost`, `quit_date` to Supabase user metadata

---

### 4. Home Dashboard
**Route:** `/home`

| Element | Status |
|---------|--------|
| Greeting with user name | ❌ Stub |
| AI message / motivational card | ❌ Stub |
| Streak widget (days clean counter) | ❌ Stub |
| Savings card (money saved so far) | ❌ Stub |
| Quick action buttons (Check-In, SOS) | ❌ Stub |
| `dashboard_provider.dart` | ❌ Empty |

**What to build:**
- [ ] `dashboard_provider.dart` — compute streak days from `quit_date`, compute savings from `daily_qty × unit_cost × days_clean`
- [ ] Greeting header (time-aware: Good morning/afternoon/evening, {name})
- [ ] AI motivational message card (static strings by streak milestone for now)
- [ ] Streak counter widget — large number + "days clean" label, ring or badge
- [ ] Savings card — currency amount saved, subtle animation on load
- [ ] Two FAB-style quick actions: **Daily Check-In** → `/checkin`, **SOS** → `/sos`

---

### 5. Daily Check-In
**Route:** `/checkin`

| Element | Status |
|---------|--------|
| Clean / Slipped large buttons | ❌ Stub |
| Mood selector (emoji/slider) | ❌ Stub |
| Craving log (conditional — if slipped) | ❌ Stub |
| Submit to Supabase | ❌ Missing |
| Check-in provider | ❌ Missing |

**What to build:**
- [ ] `checkin_provider.dart` — `submitCheckin(isClean, mood, note)` → Supabase insert
- [ ] Two large hero buttons: **✅ Stayed Clean** (green) / **😔 Had a Slip** (amber)
- [ ] Mood selector: 5-emoji row (😔 → 😊)
- [ ] Conditional craving log text field (shown only when "Slipped")
- [ ] Confirmation animation on submit (Lottie tick or confetti for clean days)
- [ ] `checkin_model.dart` — `{id, user_id, date, is_clean, mood, note}`

---

### 6. Goal Wallet
**Route:** `/wallet`

| Element | Status |
|---------|--------|
| Balance display (money saved) | ❌ Stub |
| Progress ring toward target | ❌ Stub |
| Target amount + quit date info | ❌ Stub |
| Transaction history list | ❌ Stub |
| Withdraw button | ❌ Stub |
| `wallet_provider.dart` | ❌ Empty |

**What to build:**
- [ ] `wallet_provider.dart` — compute balance from streak × daily_savings; fetch transaction log from Supabase
- [ ] `transaction_model.dart` — `{id, user_id, date, amount, type, description}`
- [ ] Large balance display (animated counter on load)
- [ ] `fl_chart` circular progress ring: current savings / target amount
- [ ] Target info tile (goal amount, quit date, % achieved)
- [ ] Transaction history: scrollable list with `wallet_card.dart` per item
- [ ] "Withdraw / Redeem" button → modal with redemption options

---


from this we have to do

### 7. Health Timeline
**Route:** `/health`

| Element | Status |
|---------|--------|
| Vertical milestone list | ❌ Stub |
| Current day highlighted | ❌ Stub |
| Past milestones checked | ❌ Stub |
| Health data source | ❌ Missing |

**What to build:**
- [ ] Static milestone data (e.g. "20 min: Heart rate normalises", "8h: CO levels drop", "1 day: Nicotine clears", "1 week: Taste returns", etc.)
- [ ] `health_provider.dart` — compute which milestones are reached based on `days_clean`
- [ ] Vertical timeline widget: past = green check, current = pulsing highlight, future = greyed
- [ ] Current-day "you are here" marker with elapsed time
- [ ] No external health API needed — milestone data is time-based on `quit_date`

---

### 8. Craving SOS
**Route:** `/sos`

| Element | Status |
|---------|--------|
| Full-screen calm design | ❌ Stub |
| 3 option cards (Breathing / Distraction / Your Why) | ❌ Stub |
| Breathing exercise UI | ❌ Missing |
| "Your Why" — user's motivational note | ❌ Missing |

**What to build:**
- [ ] Calm full-screen layout — dark teal/navy gradient, soft typography
- [ ] 3 large option cards:
  - **🌬 Breathing** → animated inhale/exhale circle (4-7-8 technique)
  - **🎯 Distraction** → random tip from a static list (walk, drink water, call friend…)
  - **💚 Your Why** → display the user's saved motivation text
- [ ] "Save my Why" input — prompt user to type their reason if not yet saved
- [ ] Craving timer: "Cravings pass in ~3 minutes" countdown

---

### 9. Marketplace
**Route:** `/marketplace`

| Element | Status |
|---------|--------|
| Product grid | ❌ Stub |
| Filter chips | ❌ Stub |
| AI recommendation strip | ❌ Stub |
| `product_model.dart` | ⚠️ Stub (no Freezed codegen) |
| `marketplace_provider.dart` | ⚠️ Stub |
| `product_card.dart` | ⚠️ Stub |

**What to build:**
- [ ] Run `build_runner` for `product_model.dart` Freezed codegen
- [ ] `marketplace_provider.dart` — fetch products from Supabase `products` table
- [ ] Filter chips row: All / Nicotine Replacement / Wellness / Books / Gadgets
- [ ] `product_card.dart` — image, name, price, "Use savings" badge
- [ ] AI recommendation strip — top 3 products based on user's habit type (rule-based for now)
- [ ] `cached_network_image` for product images (already in pubspec)

---

### 10. Insights
**Route:** `/insights`

| Element | Status |
|---------|--------|
| Chart 1 — streak / check-in history | ❌ Stub |
| Chart 2 — savings over time | ❌ Stub |
| Stats summary cards | ❌ Stub |
| Opportunity cost card | ❌ Stub |

**What to build:**
- [ ] `insights_provider.dart` — fetch last 30 check-ins from Supabase
- [ ] Chart 1 (bar): daily check-in history (clean=green / slipped=amber) — `fl_chart` BarChart
- [ ] Chart 2 (line): cumulative savings over time — `fl_chart` LineChart
- [ ] Summary cards row: Longest streak, Total saved, Success rate %
- [ ] Opportunity cost card: "In 1 year you could afford ___" (computed from annual savings)

---

## Infrastructure Gaps

| Item | Status | Action |
|------|--------|--------|
| `build_runner` codegen | ❌ Never run | Run once; re-run after any model change |
| `Inter` font in `pubspec.yaml` | ❌ Not declared | Add `fonts:` section or use `google_fonts` package |
| Google OAuth Android config | ❌ Missing | Add `google-services.json` + intent filter |
| `/splash` route | ❌ Missing | Add to router as `initialLocation` |
| `/habits` route | ❌ Missing | Route exists in feature dir but not registered |
| Supabase DB schema | ❌ Unverified | Need `checkins`, `transactions`, `products` tables |

---

## Revised Build Order

```
Sprint 1 — Replace / fix existing screens
  1. Replace OnboardingScreen (habit type → qty+cost → goal+date+savings)
  2. Build Splash screen + register /splash route

Sprint 2 — Core loop screens  
  3. Home Dashboard (streak, savings, AI card, quick actions)
  4. Daily Check-In (clean/slipped, mood, craving log)
  5. Craving SOS (3-card calm screen, breathing timer)

Sprint 3 — Progress & wallet
  6. Goal Wallet (balance, progress ring, transaction list)
  7. Health Timeline (milestone list, days-clean gating)

Sprint 4 — Discovery & analysis
  8. Marketplace (product grid, filter chips, AI strip)
  9. Insights (2 charts, stats cards, opportunity cost)

Sprint 5 — Polish & infrastructure
 10. Run build_runner (Freezed codegen for all models)
 11. Fix Inter font in pubspec.yaml
 12. Google OAuth Android config
 13. Supabase DB schema verification
 14. Profile screen (settings, sign-out, edit "Your Why")
 15. Error states, loading skeletons, empty states
```

---

## Quick Summary Table

| Screen | Required Elements | Status |
|--------|------------------|--------|
| Splash | Logo, tagline, loading | ❌ Not built |
| Login | Email, password, Google, forgot pw | ✅ Done |
| Onboarding Step 1 | Habit type grid | ❌ Wrong — needs rebuild |
| Onboarding Step 2 | Quantity + cost inputs | ❌ Wrong — needs rebuild |
| Onboarding Step 3 | Goal + date + projected savings | ❌ Wrong — needs rebuild |
| Home Dashboard | Greeting, AI card, streak, savings, quick actions | ❌ Stub |
| Daily Check-In | Clean/slipped, mood, craving log | ❌ Stub |
| Goal Wallet | Balance, progress ring, target, history, withdraw | ❌ Stub |
| Health Timeline | Milestones, current day, past checked | ❌ Stub |
| Craving SOS | 3 option cards, breathing, your why | ❌ Stub |
| Marketplace | Product grid, filters, AI strip | ❌ Stub |
| Insights | 2 charts, stats cards, opportunity cost | ❌ Stub |
