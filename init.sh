#!/usr/bin/env bash
if [ "$(stat -fc %T /sys/fs/cgroup)" != "cgroup2fs" ]; then
    echo "Needs cgroup!"
    exit 1 
fi

curl -fsSL https://get.docker.com | sudo sh
sudo docker network create domjudge
wget https://raw.githubusercontent.com/justinl681/domjudge-autoinstall/refs/heads/main/docker-compose.yml
sudo docker up -d mariadb domserver

echo "Waiting for domserver to be reachable at localhost:80..."
until curl -fsSL -o /dev/null http://localhost:80; do
    echo "Not ready yet, retrying in 5s..."
    sleep 5
done

echo "This is your admin password:"
sudo docker exec domserver cat /opt/domjudge/domserver/etc/initial_admin_password.secret
JUDGEHOST_PASSWORD=$(sudo docker exec domserver cat /opt/domjudge/domserver/etc/restapi.secret)

echo "JUDGEHOST_PASSWORD=$JUDGEHOST_PASSWORD" > .env
sudo docker compose up -d judgehost-0 judgehost-1