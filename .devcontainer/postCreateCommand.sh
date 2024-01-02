#!/bin/bash

git clone https://github.com/awslabs/git-secrets.git ~/git-secrets
cd ~/git-secrets
sudo make install
git secrets --register-aws --global
