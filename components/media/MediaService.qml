import QtQuick

import Quickshell.Services.Mpris

Item {
    id: root

    visible: false

    readonly property var players:
        Mpris.players
            ? Mpris.players.values.filter(
                function(candidate) {
                    if (!candidate)
                        return false

                    const name = String(
                        (candidate.dbusName || "")
                        + " "
                        + (candidate.identity || "")
                    )

                    if (/playerctld/i.test(name))
                        return false

                    return candidate.playbackState
                            !== MprisPlaybackState.Stopped
                        || String(candidate.trackTitle || "") !== ""
                }
            )
            : []

    readonly property var player: {
        let pausedPlayer = null

        for (let i = 0; i < root.players.length; i++) {
            const candidate = root.players[i]

            if (
                candidate.playbackState
                    === MprisPlaybackState.Playing
            ) {
                return candidate
            }

            if (
                !pausedPlayer
                && candidate.playbackState
                    === MprisPlaybackState.Paused
            ) {
                pausedPlayer = candidate
            }
        }

        return pausedPlayer
    }

    readonly property bool active: root.player !== null
    readonly property bool playing: {
        const current = root.player
        return current !== null
            && current.playbackState
                === MprisPlaybackState.Playing
    }

    readonly property string title: {
        const current = root.player
        return current
            ? (current.trackTitle || "Sin título")
            : "Sin reproducción"
    }

    readonly property string artist: {
        const current = root.player
        return current
            ? (current.trackArtist || current.identity || "")
            : "Abre Spotify, YouTube o tu reproductor"
    }

    readonly property string album: {
        const current = root.player
        return current ? (current.trackAlbum || "") : ""
    }

    readonly property string artUrl: {
        const current = root.player
        return current ? (current.trackArtUrl || "") : ""
    }

    readonly property string playerName: {
        const current = root.player
        if (!current)
            return "MPRIS"

        const value = String(
            current.identity
            || current.dbusName
            || "MPRIS"
        )

        return value.replace(
            /^org\.mpris\.MediaPlayer2\./,
            ""
        )
    }

    property real currentPosition: 0
    property real currentLength: 0
    property real lastReportedPosition: -1

    function resetPosition() {
        const current = root.player
        root.lastReportedPosition = -1
        root.currentPosition = current
            ? (current.position || 0)
            : 0
        root.currentLength = current
            ? (current.length || 0)
            : 0
    }

    function previous() {
        const current = root.player
        if (current && current.canGoPrevious)
            current.previous()
    }

    function togglePlaying() {
        const current = root.player
        if (current && current.canTogglePlaying)
            current.togglePlaying()
    }

    function next() {
        const current = root.player
        if (current && current.canGoNext)
            current.next()
    }

    function seekTo(fraction) {
        const current = root.player
        if (
            !current
            || !current.canSeek
            || root.currentLength <= 0
        ) {
            return
        }

        const nextPosition = Math.max(
            0,
            Math.min(1, fraction)
        ) * root.currentLength

        current.position = nextPosition
        root.currentPosition = nextPosition
        root.lastReportedPosition = nextPosition
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00"

        const minutes = Math.floor(seconds / 60)
        const remainder = Math.floor(seconds % 60)

        return minutes
            + ":"
            + (remainder < 10 ? "0" : "")
            + remainder
    }

    onPlayerChanged: root.resetPosition()
    onPlayingChanged: root.lastReportedPosition = -1

    Connections {
        target: root.player
        ignoreUnknownSignals: true

        function onTrackChanged() {
            root.resetPosition()
        }

        function onPositionChanged() {
            root.lastReportedPosition = -1
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.active
        triggeredOnStart: true

        onTriggered: {
            const current = root.player
            if (!current)
                return

            const reported = current.position || 0
            root.currentLength = current.length || 0

            if (
                root.lastReportedPosition < 0
                || Math.abs(
                    reported - root.lastReportedPosition
                ) > 0.08
            ) {
                root.currentPosition = reported
                root.lastReportedPosition = reported
            } else if (root.playing) {
                const limit = root.currentLength > 0
                    ? root.currentLength
                    : root.currentPosition + 1

                root.currentPosition = Math.min(
                    limit,
                    root.currentPosition + 0.5
                )
            }
        }
    }
}
