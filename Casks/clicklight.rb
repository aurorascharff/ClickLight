cask "clicklight" do
  version "0.16.0"
  sha256 "92ad5cc4364acb74a47a13735b0747f4b06f64de883bea2a77cdf43b9622ea7b"

  url "https://github.com/aurorascharff/ClickLight/releases/download/v#{version}/ClickLight.zip"
  name "ClickLight"
  desc "Highlight mouse clicks for live demos and screen sharing"
  homepage "https://github.com/aurorascharff/ClickLight"

  auto_updates true
  depends_on :macos

  app "ClickLight.app"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/ClickLight.app"]
  end

  zap trash: "~/Library/Preferences/com.aurorascharff.ClickLight.plist"
end
