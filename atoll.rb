cask "atoll" do
  version "1.0.0"
  sha256 "851da4db90f92459e654a5df478d9a06ed5399186c7dba8958abea53aff934ba"

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
