cask "atoll" do
  version "1.0.0"
  sha256 "7284722eb6587246d90b92ec7f30dc2b178fb8b4a0925bc7e1c7802b8353c4f5"

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
