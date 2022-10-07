#!/bin/bash
sudo su
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo apt install git -y
cd /var/www/html
rm index.html
git clone https://github.com/codewithsadee/tourest.git
cd tourest/
mv ./* ../