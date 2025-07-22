cask "trackweight" do
  version "0.0.0+20250722"
  sha256 :no_check # built from source — checksum indeterminable ahead of build

  desc "Turn your MacBook's trackpad into a precise digital weighing scale"
  homepage "https://github.com/KrishKrosh/TrackWeight"
  url "https://github.com/KrishKrosh/TrackWeight.git",
      branch:   "main",
      revision: "f9c555ce690c6e1b917b6b86f527779a0464dccb",
      using:    :git

  name "TrackWeight"

  # Hardware prerequisites
  depends_on macos: ">= :ventura"   # macOS 13 or newer
  depends_on arch:  :arm64          # Force‑Touch trackpad is Apple‑silicon‑only in current Macs

  # ────────────────────────────────────────────────────────────
  # Build the .app from source during cask installation
  # ────────────────────────────────────────────────────────────
  preflight do
    require "fileutils"

    Dir.chdir(staged_path) do
      # 1. Create an ad‑hoc entitlements plist that disables the macOS App Sandbox
      entitlements = staged_path/"TrackWeight.entitlements"
      system "/usr/libexec/PlistBuddy", "-c", "Add :com.apple.security.app-sandbox bool false", entitlements

      # 2. Compile with the custom entitlements and with SwiftPM sandboxing disabled
      swift_flags = "OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox"

      system "xcodebuild",
             "-project", "TrackWeight.xcodeproj",
             "-scheme", "TrackWeight",
             "-configuration", "Release",
             "-derivedDataPath", "build",
             "-IDEPackageSupportDisableManifestSandbox=YES",
             "-IDEPackageSupportDisablePluginExecutionSandbox=YES",
             swift_flags,
             "CODE_SIGN_IDENTITY=-",
             "CODE_SIGNING_REQUIRED=NO",
             "CODE_SIGNING_ALLOWED=NO",
             "OTHER_CODE_SIGN_FLAGS=--entitlements=#{entitlements}"

      # 3. Move the resulting .app to the staging root so the `app` artifact picks it up
      FileUtils.cp_r "build/Build/Products/Release/TrackWeight.app", staged_path
    end
  end

  app "TrackWeight.app"
  binary "#{appdir}/TrackWeight.app/Contents/MacOS/TrackWeight", target: "trackweight"

  # Clean‑up leftovers if the user later runs `brew uninstall --zap trackweight`
  zap trash: [
    "~/Library/Application Support/TrackWeight",
    "~/Library/Preferences/com.krishkrosh.TrackWeight.plist",
    "~/Library/Saved Application State/com.krishkrosh.TrackWeight.savedState",
  ]
end
