# pyenv が必要なので先に `bin/setup_mac_homebrew.sh` を実行する

pyenv install 2.7.10
pyenv global 2.7.10
pip install -U pip

brew install pyenv
pip install python-openstackclient python-neutronclient python-novaclient
