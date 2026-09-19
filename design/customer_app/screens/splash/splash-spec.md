# UNIQUE BASKET — Splash Screen

## Status

Implemented and verified.

## Purpose

Initial launch screen for the UNIQUE BASKET customer application.

## Design Reference

Approved Figma export:

`design/customer_app/screens/splash/assets/00_Splash.png` (~390 × 884 px)

## Assets

Production logo asset:

`apps/customer_app/assets/logos/unique_basket_logo.png`

Declared in:

`apps/customer_app/pubspec.yaml` under `assets: - assets/logos/`

## Brand

Primary:
#014D40

Secondary:
#E7F5F4

Tertiary:
#8F4E00

## Typography

Global font family:

Montserrat

## Implementation

Component:

`apps/customer_app/lib/features/splash/presentation/screens/splash_screen.dart`

Route:

`RouteNames.splash` (`/`) navigating to `RouteNames.placeholder` (`/placeholder`) after 1200ms.

## Animation & Motion

- Subtle fade (0.0 -> 1.0) and scale (0.88 -> 1.0) with `Curves.easeOutCubic` over 550ms.
- Reduced motion support via `MediaQuery.disableAnimations`.

## Responsive Behavior

- Responsive logo sizing: 65% of screen width bounded between 180dp and 280dp.
- Seamless layout across small phones, standard phones, large phones, and tablets.
