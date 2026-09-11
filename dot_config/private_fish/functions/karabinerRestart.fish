function karabinerRestart
    # ROOT CAUSE (KE 16.x, Apple Silicon, macOS 15.x — known unfixed upstream bug,
    # pqrs-org/Karabiner-Elements #3914 & #4470). On wake-from-sleep two things break:
    #
    #   1. CGEventTap gets disabled and won't re-arm. Karabiner intercepts keys via a
    #      macOS event tap. macOS has a watchdog that force-disables a tap whose
    #      callback stalls; during wake the tap times out and macOS kills it. Karabiner
    #      tries to re-enable it (log: "Re-enable event_tap_") but every attempt returns
    #      "CGEventTapEnable failed" — so keystrokes flow through unremapped.
    #   2. SMAppService registration loops. Since KE 15.0 the daemons register via
    #      Apple's SMAppService; after wake the check returns status 1 ("not running as
    #      expected") and the GUI app re-registers every ~3s forever, pegging a core at
    #      ~100% CPU (the stuck process is Karabiner-Core-Service).
    #
    # A reboot was the only thing that worked because it re-arms the tap and resets the
    # SMAppService/background-task state. Relaunching the GUI app does NOT fix it — the
    # *root daemons* must be cycled, which is what this function does (bottom-up:
    # driver -> root daemons -> per-user agent).

    echo "Restarting Karabiner daemons (sudo password needed)…"

    # Re-activate the DriverKit extension (no-op when already [activated enabled])
    if test -x '/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager'
        sudo '/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager' activate
    end

    # Cycle the two root daemons (this is what actually clears the stuck state)
    sudo launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon
    sudo launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-Core-Service

    # Cycle the per-user agent (same thing the app's "Restart Karabiner" menu does)
    launchctl kickstart -k gui/(id -u)/org.pqrs.service.agent.karabiner_console_user_server

    echo "Done. Try your remaps now (no reboot needed)."
end
