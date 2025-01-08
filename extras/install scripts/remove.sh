#!/bin/zsh --no-rcs
# -----------------------------------------------
# Clear existing Music is Illegal installations
# -----------------------------------------------


# MARK: Variables
# -----------------------------------------------
launchServicePrefix="com.khronokernel.music-is-illegal"
installationDestinationCore="/Library/PrivilegedHelperTools/music-is-illegal.app"


# MARK: Functions
# -----------------------------------------------

# Delete file or directory
# Arguments:
#  $1: File or directory
function deleteItem {
    local item="$1"

    if [[ ! -e "$item" ]]; then
        return
    fi

    if [[ -d "$item" ]]; then
        /bin/rm -rf "$item"
        return
    fi

    /bin/rm -f "$item"
}


# Unload launch agent/daemon service file
# Arguments:
#  $1: Launch service file
function unloadLaunchServiceFile {
    local launchServiceFile="$1"
    local launchServiceName

    launchServiceName="$(/usr/bin/basename "$launchServiceFile" | /usr/bin/sed 's/.plist//g')"

    echo "Unloading launch service file: $launchServiceFile"

    local currentUser
    local uid

    currentUser=$(echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }')
    uid=$(/usr/bin/id -u "${currentUser}")

    if [[ "$launchServiceFile" == *"/Library/LaunchAgents"* ]]; then
        if [[ $(hostSupportsLaunchctlBootoutCommand) == "true" ]]; then
            echo "Unloading as launch agent: $launchServiceName"
            /bin/launchctl bootout gui/"$uid" "$launchServiceFile" || true
            return
        fi
    fi

    echo "Unloading as launch daemon: $launchServiceName"
    /bin/launchctl unload "$launchServiceFile" || true
}

# Unload all launch agent service files
function unloadLaunchServiceFiles {
    local launchServiceFiles

    launchServiceFiles=$(/bin/ls -1 /Library/LaunchAgents | /usr/bin/grep "$launchServicePrefix")

    for launchServiceFile in $launchServiceFiles; do
        unloadLaunchServiceFile "/Library/LaunchAgents/$launchServiceFile"
        deleteItem "/Library/LaunchAgents/$launchServiceFile"
    done

    launchServiceFiles=$(/bin/ls -1 /Library/LaunchDaemons | /usr/bin/grep "$launchServicePrefix")

    for launchServiceFile in $launchServiceFiles; do
        unloadLaunchServiceFile "/Library/LaunchDaemons/$launchServiceFile"
        deleteItem "/Library/LaunchDaemons/$launchServiceFile"
    done
}

# Apple didn't add launchctl bootout until macOS 10.11
function hostSupportsLaunchctlBootoutCommand {
    local osVersion

    osVersion=$(/usr/bin/sw_vers -productVersion)

    osMajorVersion=$(echo "$osVersion" | /usr/bin/awk -F. '{print $1}')
    osMinorVersion=$(echo "$osVersion" | /usr/bin/awk -F. '{print $2}')
    osMinorVersion="10"

    if [[ "$osMajorVersion" -gt 10 ]]; then
        echo "true"
        return
    fi

    if [[ "$osMinorVersion" -gt 10 ]]; then
        echo "true"
        return
    fi

    echo "false"
}

# Main function
function main {
    echo "Clearing existing Escalate installation..."
    deleteItem "$installationDestinationCore"
    unloadLaunchServiceFiles
}


# MARK: Main
# -----------------------------------------------
main
