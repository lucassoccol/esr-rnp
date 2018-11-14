#!/bin/bash

CA_USER="sshca"
CA_ADDR="10.0.42.2"
CA_USER_PASS="seg10sshca"
SSH_OPTS="-o PreferredAuthentications=password -o PubkeyAuthentication=no"

# testar se chave ja foi assinada
if [ -f ~/.ssh/id_rsa-cert.pub ]; then
  echo "Key already signed, bailing."
  exit 1
fi

# escanear chave do host ssh-ca, se necessario
rm -f ~/.ssh/known_hosts 2> /dev/null
[ -d ~/.ssh ] || { mkdir ~/.ssh; chmod 700 ~/.ssh; }
if ! ssh-keygen -F ${CA_ADDR} 2>/dev/null 1>/dev/null; then
  ssh-keyscan -t rsa -T 10 ${CA_ADDR} 2> /dev/null >> ~/.ssh/known_hosts
fi

# gerar par de chaves RSA, se inexistentes
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 4096 -N '' &> /dev/null

# copiar pubkey RSA
sshpass -p "${CA_USER_PASS}" \
  scp ${SSH_OPTS} ~/.ssh/id_rsa.pub ${CA_USER}@${CA_ADDR}:~

# assinar pubkey RSA, validade [-5 min -> 1 ano]
echo "Signing ~/.ssh/id_rsa.pub key..."
user="$( whoami )"
sshpass -p "${CA_USER_PASS}" \
  ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} \
    ssh-keygen -s user_ca \
    -I ${user} \
    -n ${user} \
    -V -5m:+1095d \
    id_rsa.pub 2> /dev/null

# copiar pubkey assinada de volta
sshpass -p "${CA_USER_PASS}" \
  scp ${SSH_OPTS} ${CA_USER}@${CA_ADDR}:~/id_rsa-cert.pub ~/.ssh/

# remover temporarios do diretorio remoto
sshpass -p "${CA_USER_PASS}" \
  ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} \
    rm id_rsa.pub id_rsa-cert.pub

# copiar pubkey da server_ca e configurar reconhecimento de chaves de host assinadas
echo "@cert-authority * $(sshpass -p "${CA_USER_PASS}" ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} cat server_ca.pub)" > ~/.ssh/known_hosts

# remover pubkey RSA antiga
rm -f ~/.ssh/id_rsa.pub 2> /dev/null

echo "All done!"
