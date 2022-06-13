# pyenv が必要なので先に `bin/setup_mac_homebrew.sh` を実行する

PYVERSION="3.6.13"

# https://github.com/pyenv/pyenv/wiki/Common-build-problems
# High Sierra にしてから標準の openssl が LibreSSL になったので
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
pyenv install -v ${PYVERSION}
pyenv global ${PYVERSION}
pip install -U pip
pip install python-openstackclient python-neutronclient python-novaclient
