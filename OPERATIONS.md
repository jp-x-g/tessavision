# Shared release baseline

All floors should use the same revision of the application and recovery scripts.
Floor, hostname, console colors, Wi-Fi interface and saved connection name are
configuration. API credentials, NetworkManager passwords, SSH authorized keys
and Tailscale identities are private installation state, not source code.

The unified baseline includes Unicode-safe border padding, wrapped event titles,
validated quote/event refreshes, a configurable Wi-Fi watchdog that preserves
connections in progress, USB recovery assets, and bounded persistent logs.

## Publication is not deployment

The owner's instruction on 2026-09-14 is to publish this baseline while leaving
both working TVs untouched. A later rollout requires a separate request. No
deployment automation is added by this update. The observed Pi app directories
are not Git checkouts; publishing the repository does not update their files.

Do not run `install_pi.sh`, `startup.sh`, or `startup_cron.sh` merely to publish
or check a release. The installer provisions a Pi and schedules a reboot. The
other startup scripts are legacy entry points, not the deployed systemd flow.

## Verified working state, 2026-09-14

| Setting/component | 1F (`tessavision-1f`) | 3F (`tessavision`) |
| --- | --- | --- |
| Floor / colors | 1 / yellow on green | 3 / yellow on black |
| Connected Wi-Fi | `Mox-dongle` on external `wlan1` | `preconfigured` on onboard `wlan0` |
| Renderer and events | Current shared versions | Same versions as 1F |
| Ticker | Validated refreshes, preserves cached values on failure | Older refresh script; replacement deferred |
| Wi-Fi watchdog | Current shared script, `wlan1` override | Not installed; rollout deferred |
| USB recovery | Previously tested, fixed Pi address `10.77.0.2` | Not yet established/tested |
| Persistent diagnostic logs | 16 MiB cap, seven-day retention | Parity deferred |

The 1F TP-Link Archer T2U Nano is USB `2357:011e`, MAC `3c:78:95:f1:40:98`.
Its separate `preconfigured` profile remains on `wlan0` as fallback. Match the
actual interface to the physical radio when rebuilding; profile names can be
misleading. `config/1f.conf.example` and `config/3f.conf.example` describe the
selected settings for the common installer, not proof of identical installed
services on both Pis today.

1F passed a live boot check after its SD filesystem journal was recovered:
external Wi-Fi and Tailscale SSH connected, NTP synchronized, events and prices
refreshed, all display/refresh/watchdog units were active, and the borders were
verified from the console and by the user. 3F's border fix was also verified live.
No additional reboot or deployment was performed for this publication.

Recorded SHA-256 hashes for comparing future deployments:

| Script | Shared baseline / 1F | 3F at publication |
| --- | --- | --- |
| `compose.sh` | `f9ee98c4ad05c5704be4b0898c01d397afa8698c41e208c239f9cf43bf3c2bab` | Same |
| `events.sh` | `8e257ea938075a9662aff169287a570167fb51cb5a813f012dcc3483a068e8ee` | Same |
| `ticker.sh` | `3608906e92b220714736b8edf3ec59ce35093c75b1d24eb04f5af6c7af43838b` | `2692dba12a9cacb87479794023478c7aab2429eecfd86641b0b7ccc8b4fcbc23` |
| `network_watchdog.sh` | `4549186231d9f64c4ea333da9989f5347980b25f9d9ad57391ca0be5b1352912` | Not installed |

## Future rollout procedure

1. Select one Git commit for both TVs and run the local tests and shell syntax
   checks in README. The installer configuration changes are tested locally;
   the complete unified installer has not been run on either working TV.
2. Before changing either Pi, read its current files, service units and device
   settings. Back up the deployed app, `auth/`, floor file, service overrides,
   SSH access and network profiles privately. Retain a rollback copy.
3. Establish a recovery route and arrange a maintenance window. In particular,
   verify a recovery route for 3F before changing its networking. Provisioning
   instructions are in PROVISIONING.md; do not clone Tailscale identities.
4. Stage the same reviewed application revision on each Pi. Preserve its
   credentials and per-floor configuration. Review service changes separately;
   copying scripts alone does not install timers or recovery services.
5. Update one Pi at a time. Verify the correct floor/colors, border geometry,
   fresh events and all three quotes, synchronized time, active services,
   Tailscale SSH and the recovery path. Test reboot recovery when authorized.
6. Record the installed commit and hashes for both Pis, and update this table.
   Keep the rollback until both have passed acceptance.

The local emergency runbook on Hatsune is `/home/x/tessavision/AGENTS.md`.
Private 1F recovery archives and the filesystem undo file are under
`/home/x/tessavision-backups/1f-recovery-20260914.YFIRgr`; they are not in Git.
