cask "clicklight" do
  version "0.17.0"
  sha256 "21f5b653b8a47af8e564782274361919302f4601c36736809c63be5352edb037"

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
