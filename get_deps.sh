#!/bin/bash

echo "#### Getting prereqs ####"

echo Base prereqs
apt-get update --fix-missing
apt-get upgrade -y
apt-get install -y build-essential git python3-pip clang ninja-build vim

echo Python prereqs
ln -sf /usr/bin/python3.7 /usr/bin/python
pip install --upgrade git+https://github.com/Maratyszcza/PeachPy
pip install --upgrade git+https://github.com/Maratyszcza/confu
