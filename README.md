# TERMINAL-ZERO


### An EV Cyber Academy CTF Experience

A pure-Bash, terminal-based cybersecurity decision game. No GUI, no browser —
just your terminal, real-world security scenarios, and the choices you make.

## Run it

```bash
chmod +x game.sh
./game.sh
```

That's it. No dependencies beyond Bash 4+.

## How it plays

You're a recruit at EV Cyber Academy's Training Range. Each mission drops you
into a real-world security scenario — a phishing email, a suspicious log
entry, a risky file permission, an active incident — and asks:

**"What would you do?"**

Pick a number (1–4). Get it right, earn XP and points. Get it wrong, get a
full debrief on why. Spend points on hints if you're stuck.

## Progression

- **12 missions** across **4 belts**: Recruit → Operative → Specialist → Elite
- **XP & Rank system**: Recruit → Operative → Specialist → Elite → Certified
- **Points & Hints**: spend points to unlock a hint before answering
- **Save/resume**: progress is saved locally in `saves/progress.dat`

## Requirements

- Bash 4.0+
- A terminal (Linux, WSL, or macOS with a recent Bash)

## Project structure

```
terminal-zero/
├── game.sh          # the entire game
├── saves/           # local save data (gitignored)
└── README.md
```

## About

Built by EV Cyber Academy as a hands-on, beginner-friendly way to practice
security decision-making — recognizing phishing, reading permissions,
spotting persistence mechanisms, and prioritizing incident response — all
from the terminal.
