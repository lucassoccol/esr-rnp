#!/bin/bash

CA_USER="sshca"
CA_ADDR="10.0.42.2"
CA_USER_PASS="seg10sshca"
SSH_OPTS="-o PreferredAuthentications=password -o PubkeyAuthentication=no"


function cleanup() {
  sed -i '/^HostCertificate/d' /etc/ssh/sshd_config
  sed -i '/^TrustedUserCAKeys/d' /etc/ssh/sshd_config

  rm -f ~/.ssh/known_hosts       \
    /etc/ssh/ssh_host_*      \
    /etc/ssh/ssh_known_hosts \
    /etc/ssh/user_ca.pub 2> /dev/null
  dpkg-reconfigure openssh-server &> /dev/null

  systemctl restart sshd.service
}


# resetar sistema para estado conhecido
cleanup

# escanear chave do host ssh-ca
[ -d ~/.ssh ] || { mkdir ~/.ssh; chmod 700 ~/.ssh; }
if ! ssh-keygen -F ${CA_ADDR} 2>/dev/null 1>/dev/null; then
  ssh-keyscan -t rsa -T 10 ${CA_ADDR} 2> /dev/null >> ~/.ssh/known_hosts
fi

# iterar em todas as pubkeys SSH
for pkeypath in /etc/ssh/ssh_host_*.pub; do
  pkeyname="$( echo "${pkeypath}" | awk -F'/' '{print $NF}' )"
  certname="$( echo "${pkeyname}" | sed 's/\(\.pub$\)/-cert\1 /' )"
  echo "Signing ${pkeyname} key..."

  # copiar pubkey
  sshpass -p "${CA_USER_PASS}" \
    scp ${SSH_OPTS} ${pkeypath} ${CA_USER}@${CA_ADDR}:~

  # assinar pubkey, validade [-5 min -> 3 anos]
  identity="$(hostname --fqdn)"
  principals="$(hostname),$(hostname --fqdn),$(hostname -I | tr ' ' ',' | sed 's/,$//')"
  sshpass -p "${CA_USER_PASS}" \
    ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} \
      ssh-keygen -s server_ca \
      -I "${identity}" \
      -n "${principals}" \
      -V -5m:+1095d \
      -h \
      ${pkeyname} 2> /dev/null

  # copiar pubkey assinada de volta
  sshpass -p "${CA_USER_PASS}" \
    scp ${SSH_OPTS} ${CA_USER}@${CA_ADDR}:${certname} /etc/ssh/

  # remover temporarios do diretorio remoto
  sshpass -p "${CA_USER_PASS}" \
    ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} \
      rm ${pkeyname} ${certname}

  # remover pubkey RSA antiga e configurar ssh para apresentar pubkey assinada
  rm -f ${pkeypath} 2> /dev/null
  echo "HostCertificate /etc/ssh/${certname}" >> /etc/ssh/sshd_config
done

# copiar pubkey da server_ca e configurar reconhecimento de chaves de host assinadas
echo "Configuring host key trust..."
echo "@cert-authority * $(sshpass -p "${CA_USER_PASS}" ssh ${SSH_OPTS} ${CA_USER}@${CA_ADDR} cat server_ca.pub)" > /etc/ssh/ssh_known_hosts

# copiar pubkey da user_ca e configurar reconhecimento de chaves de usuario assinadas
echo "Configuring user key trust..."
sshpass -p "${CA_USER_PASS}" \
  scp ${SSH_OPTS} ${CA_USER}@${CA_ADDR}:~/user_ca.pub /etc/ssh/
echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" >> /etc/ssh/sshd_config

echo "All done!"
systemctl restart sshd.service
