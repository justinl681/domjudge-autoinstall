#!/usr/bin/env bash
set -e

if [ "$(stat -fc %T /sys/fs/cgroup)" != "cgroup2fs" ]; then
    echo "Needs cgroup!"
    exit 1 
fi

echo "Waiting for apt lock..."
while sudo fuser /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "apt is locked, retrying in 5s..."
    sleep 5
done

curl -fsSL https://get.docker.com | sudo sh
wget https://raw.githubusercontent.com/justinl681/domjudge-autoinstall/refs/heads/main/docker-compose.yml
sudo docker compose up -d mariadb domserver

echo "Waiting for domserver to be reachable at localhost:80..."
until curl -fsSL -o /dev/null http://localhost:80; do
    echo "Not ready yet, retrying in 5s..."
    sleep 5
done

echo "This is your admin password:"
sudo docker exec domserver cat /opt/domjudge/domserver/etc/initial_admin_password.secret
JUDGEHOST_PASSWORD=$(sudo docker exec domserver cat /opt/domjudge/domserver/etc/restapi.secret | grep -v '^#' | awk '{print $4}')

echo "JUDGEHOST_PASSWORD=$JUDGEHOST_PASSWORD" > .env
sudo docker compose up -d judgehost-0 judgehost-1
