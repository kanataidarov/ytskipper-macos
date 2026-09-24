# YTSkipper

A macOS menu bar utility that presses YouTube's Skip Button on the user's behalf while videos play in Safari, so ads end as soon as YouTube allows.

## Language

**Skip Button**:
The control YouTube shows during a skippable ad that ends the ad when pressed.
_Avoid_: Skip Ad button, skip link, skip image

**YouTube Page**:
The web content a Safari window currently shows when its address is on `www.youtube.com` or `music.youtube.com`. Skip Buttons are looked for only inside YouTube Pages; embedded players on other sites do not count.
_Avoid_: tab, video page, player page

**Scan**:
One pass over every Safari window, looking for a Skip Button inside each shown YouTube Page. Scans repeat on a fixed cadence; nothing happens between them.
_Avoid_: poll, tick, check

**Skip**:
A press of a Skip Button that took effect, meaning the button was gone on the next Scan. The app counts Skips, not presses.
_Avoid_: click, press (for the counted event)

**Skip Label**:
One of the exact visible texts (such as "Skip" or "Skip Ad") by which a Skip Button is recognized. Matching is exact, so "Skip navigation" is never a Skip Label.
_Avoid_: keyword, pattern, selector
