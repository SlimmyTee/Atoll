cask "atoll" do
  version "1.2.0"
  sha256 "33a9725a5663dcab549360a5c1a0825155e31d12dfa1d06a38b9e9b4a6baa318"

  url "https://atoll-nine.vercel.app/downloads/Atoll.dmg"
  name "Atoll"
  desc "Dynamic Island for your Mac"
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
  ]
end
