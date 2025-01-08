"""
build.py: Build script for Music Is Illegal
"""

import subprocess
import macos_pkg_builder


class BuildMusicIsIllegal:

    def __init__(self):
        self._file_structure = {
            "build/Release/Music-is-Illegal.app": "/Library/PrivilegedHelperTools/Music-is-Illegal.app",
            "extras/launch services/com.khronokernel.music-is-illegal.daemon.plist": "/Library/LaunchDaemons/com.khronokernel.music-is-illegal.daemon.plist",
        }
        self._version = self._version_from_constants()


    def _version_from_constants(self) -> str:
        """
        Fetch version from Constants.swift
        """
        file = "music-is-illegal/Library/Constants.swift"
        with open(file, "r") as f:
            for line in f:
                if "let projectVersion" not in line:
                    continue
                return line.split('"')[1]

        raise Exception("Failed to fetch version from Constants.swift")


    def _installer_pkg_welcome_message(self) -> str:
        """
        Generate installer README message for PKG
        """
        message = [
            "# Overview",
            f"This package will install 'Music is Illegal' (v{self._version}) on your system. This utility simply blocks Music.app from launching (ex. when stealing media hotkeys).\n",
            "Note: Upon installation, you will need to provide the application with Full Disk Access in System Settings. Once completed, you can restart the associated launch daemon or reinstall this PKG to apply changes.\n",
            "# Files Installed",
            "Installation of this package will add the following files to your system:\n",
        ]

        for item in self._file_structure:
            if self._file_structure[item].startswith("/tmp/"):
                continue
            message.append(f"* `{self._file_structure[item]}`\n")

        return "\n".join(message)


    def _xcodebuild(self):
        """
        Build application
        """
        print("Building Music Is Illegal")
        subprocess.run(["/bin/rm", "-rf", "build"], check=True)
        subprocess.run(["/usr/bin/xcodebuild"], check=True)


    def _package(self):
        """
        Convert application to package
        """
        print("Packaging Music Is Illegal")
        assert macos_pkg_builder.Packages(
            pkg_output="Music-is-Illegal-Installer.pkg",
            pkg_bundle_id="com.khronokernel.music-is-illegal",
            pkg_file_structure=self._file_structure,
            pkg_allow_relocation=False,
            pkg_preinstall_script="extras/install scripts/remove.sh",
            pkg_postinstall_script="extras/install scripts/install.sh",
            pkg_signing_identity="Developer ID Installer: Mykola Grymalyuk (S74BDJXQMD)",
            pkg_background="extras/icons/PKG-Install.png",
            pkg_as_distribution=True,
            pkg_title="Music Is Illegal",
            pkg_version=self._version,
            pkg_welcome=self._installer_pkg_welcome_message(),
        ).build() is True

        print("Packaging uninstaller")
        assert macos_pkg_builder.Packages(
            pkg_output="Music-is-Illegal-Uninstaller.pkg",
            pkg_bundle_id="com.khronokernel.music-is-illegal.uninstall",
            pkg_preinstall_script="extras/install scripts/remove.sh",
            pkg_as_distribution=True,
            pkg_background="extras/icons/PKG-Uninstall.png",
            pkg_version=self._version,
            pkg_title="Music Is Illegal Uninstaller",
        ).build() is True



    def run(self):
        self._xcodebuild()
        self._package()



if __name__ == "__main__":
    BuildMusicIsIllegal().run()
