cask "atoll" do
  version "1.0.0"
  sha256 "71c1dbcac4039f721fa5716f930157e54949c76b16f8e21fe4b5a2cb7c2830b3"

  url "https://github.com/SlimmyTee/Atoll/releases/download/v#{version}/Atoll.dmg"
  name "Atoll"
  desc "Native Dynamic Island for macOS"
  homepage "https://atoll-nine.vercel.app/"

  app "Atoll.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Atoll.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/DynamicIsland",
    "~/Library/Preferences/com.danielumoren.dynamicisland.plist",
    "~/Library/Preferences/app.atoll.desktop.plist",
  ]
end
