cask "atoll" do
  version "1.0.0"
  sha256 "f8dbd286ea0d1589bdbd68267149f876c3df820feefb8d71e9a65bb4a6691e55"

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
