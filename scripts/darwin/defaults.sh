#!/usr/bin/env bash

defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10
mkdir -p /Library/Preferences/FeatureFlags/Domain
sudo defaults write /Library/Preferences/FeatureFlags/Domain/UIKit.plist redesigned_text_cursor -dict-add Enabled -bool NO
