cask "atoll" do
  version "1.0.0"
  sha256 "1b05fd5c55c7f1663969f0fd2ea83ca6398529873864157f4e96ab53df87e9ae"

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
