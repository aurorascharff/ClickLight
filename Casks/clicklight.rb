cask "clicklight" do
  auto_updates true
  version "0.9.0"
  sha256 "fb3775cdf33c8e20fc4658d94d2e8f78c75884c11a10c6162c3500b923b9ef20"

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
