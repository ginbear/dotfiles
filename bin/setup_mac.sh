# Disable Game Center launching
sudo defaults write /System/Library/LaunchAgents/com.apple.gamed Disabled -bool true
# Avoid creation of .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Speed up expose
defaults write com.apple.dock expose-animation-duration -float 0.1; killall Dock
