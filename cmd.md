## Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

## Example connection
ubuntu@ec2-52-19-26-42.eu-west-1.compute.amazonaws.com

## Connect ssh
ssh -i "vh.pem" <conn>

## Transfer file
scp -i "vh.pem" ~/Projects/valheim/docker-compose.yml <conn>:~/