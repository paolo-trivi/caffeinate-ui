# Launch direction

Research checked on 2026-10-25. The repository and preview downloads are public.

## Positioning

**A small, native interface for `caffeinate -disu`. Keep your Mac awake and get back to building.**

The category already has mature alternatives: [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) has approximately 7,000 stars and dates to 2014; [OnlySwitch](https://github.com/jacklandrin/OnlySwitch) has approximately 6,000 and dates to 2021. [Lungo](https://sindresorhus.com/lungo) already offers a focused, polished keep-awake experience. A timer and a menu bar icon are baseline features. Our design and floating panel are a positioning hypothesis to validate with users, not a proven competitive advantage.

## First release

Freeze functionality at start/stop, optional duration, menu bar, optional desktop panel, and launch at login. Prioritize correct state, a clear selected duration, clean shutdown, and a compact interface. Keep author and project links discreet. Explain sleep and VPN limits accurately.

Ask 5–10 Mac developers to install a build and complete three tasks without guidance: start Unlimited, change to two hours, and stop from the desktop panel. Record installation failures, wrong selections, and unclear controls. Fix those before adding features.

## Distribution

The current build uses an ad hoc signature and needs no Apple Developer account. Source installation needs Swift 6; downloaded binaries can encounter Gatekeeper. This is real installation friction to test and document. Homebrew's official cask rules require passing Gatekeeper checks, so an official cask is not currently an installation promise we can make. [Homebrew policy](https://docs.brew.sh/Acceptable-Casks)

Keep one installation path prominent in the README, include actual screenshots, and publish versioned binaries with checksums. Do not claim runtime testing on Intel or older macOS versions until it happens.

## Launch

Before a wider announcement, collect installation and usability feedback on the public preview. Prepare a working demo for trivisonno.dev: a short recording of start, duration change, and stop; one sentence explaining the tool; and clear download and source links.

For Show HN, follow its requirements for a personally developed, substantive project people can actually try, with minimal installation barriers. A generated wrapper alone is not a compelling launch story. Explain the real use case and the engineering decisions, and be available to discuss them. [Show HN guidelines](https://news.ycombinator.com/showhn.html)

Judge the first release by successful installations, useful feedback, repeat use reported by testers, and resolved bugs. Set reach targets after collecting that evidence. Stars are an outcome, not a guarantee.
