#!/bin/bash

CA_user="sshca"
CA_addr="10.0.42.2"
SSH_OPTS="-o PreferredAuthentications=password -o PubkeyAuthentication=no"

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

# iterar em todas as pubkeys SSH
for pkeypath in /etc/ssh/ssh_host_*.pub; do
  pkeyname="$( echo "${pkeypath}" | awk -F'/' '{print $NF}' )"
  certname="$( echo "${pkeyname}" | sed 's/\(\.pub$\)/-cert\1 /' )"

  # copiar pubkey
  sshpass -p "${pass}" \
    scp ${SSH_OPTS} ${pkeypath} ${CA_user}@${CA_addr}:~

  # assinar pubkey, validade [-5 min -> 3 anos]
  identity="$(hostname --fqdn)"
  principals="$(hostname),$(hostname --fqdn),$(hostname -I | tr ' ' ',' | sed 's/,$//')"
  echo -ne "\n(CA private key) "
  sshpass -p "${pass}" \
    ssh ${SSH_OPTS} ${CA_user}@${CA_addr} \
      ssh-keygen -s server_ca \
      -I "${identity}" \
      -n "${principals}" \
      -V -5m:+1095d \
      -h \
      ${pkeyname}

  # copiar pubkey assinada de volta
  sshpass -p "${pass}" \
    scp ${SSH_OPTS} ${CA_user}@${CA_addr}:${certname} /etc/ssh/

  # remover temporarios do diretorio remoto
  sshpass -p "${pass}" \
    ssh ${SSH_OPTS} ${CA_user}@${CA_addr} \
      rm ${pkeyname} ${certname}

  # remover pubkey RSA antiga e configurar ssh para apresentar pubkey assinada
  rm -f ${pkeypath} 2> /dev/null
  echo "HostCertificate /etc/ssh/${certname}" >> /etc/ssh/sshd_config
done

# copiar pubkey da server_ca e configurar reconhecimento de chaves de host assinadas
echo "@cert-authority * $(sshpass -p "$pass" ssh ${SSH_OPTS} ${CA_user}@${CA_addr} cat server_ca.pub)" > /etc/ssh/ssh_known_hosts

# copiar pubkey da user_ca e configurar reconhecimento de chaves de usuario assinadas
sshpass -p "${pass}" \
  scp ${SSH_OPTS} ${CA_user}@${CA_addr}:~/user_ca.pub /etc/ssh/
echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" >> /etc/ssh/sshd_config

systemctl restart sshd.service
