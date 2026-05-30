cask "clicklight" do
  auto_updates true
  version "0.12.0"
  sha256 "2f3034f589e885b0efa126254dd7de3e622b7869bddff64621df34b50c3d7fad"

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
