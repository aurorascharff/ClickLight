cask "clicklight" do
  auto_updates true
  version "0.3.0"
  sha256 "efe5a33154b2113cdc1cf4b3ee8712286c2b3d0ab1e78a44d60a67326bfc27bd"

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
