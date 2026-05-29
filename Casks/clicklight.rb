cask "clicklight" do
  auto_updates true
  version "0.8.0"
  sha256 "aad155d58c4d1a271921a9f9d14c26dd4b4580769d9be8fe4fa1e53114ac523a"

  url "https://github.com/aurorascharff/ClickLight/releases/download/v#{version}/ClickLight.zip"
  name "ClickLight"
  desc "Highlight clicks anywhere on your Mac for live demos"
  homepage "https://github.com/aurorascharff/ClickLight"

  app "ClickLight.app"

  postflight do
    system "xattr", "-cr", "#{appdir}/ClickLight.app"
  end

  zap trash: [
    "~/Library/Preferences/com.aurorascharff.ClickLight.plist",
  ]
end
