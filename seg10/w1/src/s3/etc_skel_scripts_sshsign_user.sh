#!/bin/bash

CA_user="sshca"
CA_addr="10.0.42.2"
SSH_OPTS="-o PreferredAuthentications=password -o PubkeyAuthentication=no"

# testar se chave ja foi assinada
if [ -f ~/.ssh/id_rsa-cert.pub ]; then
  echo "key already signed"
  exit 1
fi

# obter senha para sshpass
echo -n "(${CA_user}@${CA_addr}) Enter passphrase: "
read -s pass
echo

# escanear chave do host ssh-ca, se necessario
[ -d ~/.ssh ] || { mkdir ~/.ssh; chmod 700 ~/.ssh; }
if ! ssh-keygen -F ${CA_addr} 2>/dev/null 1>/dev/null; then
  ssh-keyscan -t rsa -T 10 ${CA_addr} >> ~/.ssh/known_hosts
fi

# testar se senha correta
if ! sshpass -p "${pass}" ssh ${SSH_OPTS} ${CA_user}@${CA_addr} exit 0; then
  echo "wrong password"
  exit 1
fi

# gerar par de chaves RSA, se inexistentes
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 4096 -N '' &> /dev/null

# copiar pubkey RSA
sshpass -p "${pass}" \
  scp ${SSH_OPTS} ~/.ssh/id_rsa.pub ${CA_user}@${CA_addr}:~

# assinar pubkey RSA, validade [-5 min -> 1 ano]
user="$( whoami )"
echo -ne "\n(CA private key) "
sshpass -p "${pass}" \
  ssh ${SSH_OPTS} ${CA_user}@${CA_addr} \
    ssh-keygen -s user_ca \
    -I ${user} \
    -n ${user} \
    -V -5m:+1095d \
    id_rsa.pub

# copiar pubkey assinada de volta
sshpass -p "${pass}" \
  scp ${SSH_OPTS} ${CA_user}@${CA_addr}:~/id_rsa-cert.pub ~/.ssh/

# remover temporarios do diretorio remoto
sshpass -p "${pass}" \
  ssh ${SSH_OPTS} ${CA_user}@${CA_addr} \
    rm id_rsa.pub id_rsa-cert.pub

# copiar pubkey da server_ca e configurar reconhecimento de chaves de host assinadas
echo "@cert-authority * $(sshpass -p "$pass" ssh ${SSH_OPTS} ${CA_user}@${CA_addr} cat server_ca.pub)" >> ~/.ssh/known_hosts

# remover pubkey RSA antiga
rm -f ~/.ssh/id_rsa.pub 2> /dev/null
