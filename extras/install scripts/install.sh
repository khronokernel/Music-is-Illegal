#!/bin/zsh --no-rcs
# -----------------------------------------------
# Load new Music is Illegal installation
# -----------------------------------------------


# MARK: Variables
# -----------------------------------------------
launchServicePrefix="com.khronokernel.music-is-illegal"


# MARK: Functions
# -----------------------------------------------

# Load launch agent/daemon service file
# Arguments:
#  $1: Launch service file
function loadLaunchServiceFile {
    local launchServiceFile="$1"

    local currentUser
    local uid

    currentUser=$(echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }')
    uid=$(/usr/bin/id -u "${currentUser}")

    if [[ "$launchServiceFile" == *"/Library/LaunchAgents"* ]]; then
        /bin/launchctl bootstrap gui/"$uid" "$launchServiceFile" || true
        return
    fi

    /bin/launchctl load "$launchServiceFile" || true
}


# Load all launch agent service files
function loadLaunchServiceFiles {
    local launchServiceFiles

    launchServiceFiles=$(/bin/ls -1 /Library/LaunchDaemons | /usr/bin/grep "$launchServicePrefix")

    for launchServiceFile in $launchServiceFiles; do
        echo "Loading launch service file: $launchServiceFile"
        loadLaunchServiceFile "/Library/LaunchDaemons/$launchServiceFile"
    done

    launchServiceFiles=$(/bin/ls -1 /Library/LaunchAgents | /usr/bin/grep "$launchServicePrefix")

    for launchServiceFile in $launchServiceFiles; do
        echo "Loading launch service file: $launchServiceFile"
        loadLaunchServiceFile "/Library/LaunchAgents/$launchServiceFile"
    done


}


# Main function
function main {
    loadLaunchServiceFiles
}


# MARK: Main
# -----------------------------------------------
main
