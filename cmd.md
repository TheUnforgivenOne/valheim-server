## Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

## Example connection
ubuntu@ec2-52-19-26-42.eu-west-1.compute.amazonaws.com

## Connect ssh
ssh -i "vh.pem" ubuntu@ec2-52-19-26-42.eu-west-1.compute.amazonaws.com

## Transfer file
scp -i "vh.pem" ~/Projects/valheim/docker-compose.yml ubuntu@ec2-52-19-26-42.eu-west-1.compute.amazonaws.com:~/

## Screen
screen - start new screen
screen -ls - list of screens
screen -r <name> - attach to <name>
screen - r -d <name> - detach if attached somewhere and attach here <name>
Ctrl + a + d - detach active screen

## Docker
docker ps (docker compose ps) - list of running containers
docker attach <name> - attach to <name>
docker compose up --detach - run compose and detach
docker exec -it <name> /bin/bash - enter to the <name> command line
exit - exit shell
