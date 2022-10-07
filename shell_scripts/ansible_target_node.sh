#!/bin/bash
sudo su
sudo apt update -y
sudo apt install wget -y
sudo apt install ansible -y
sudo apt install git -y
sudo apt install unzip -y
sudo echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers