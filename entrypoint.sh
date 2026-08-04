#!/bin/sh
set -e

# Ensure sshd runtime directory exists
mkdir -p /var/run/sshd

# Write out login restrictions, every container start
mkdir -p /etc/ssh/sshd_config.d

echo "- Checking users vs homedirs"
for homedir in /home/*; do
  [ -d "$homedir" ] || continue

  username="$(basename "$homedir")"

  if ! getent passwd "$username" >/dev/null; then
    userid=$(stat -c '%u' $homedir)
    groupid=$(stat -c '%g' $homedir)
    if ! getent group "$groupid" > /dev/null; then
      echo "- Creating missing user/group: $username (U: $userid G: $groupid)"
      useradd -M -u "$userid" -d "$homedir" "$username"
    else
      echo "- Creating missing user: $username (U: $userid G: $groupid)"
      useradd -M -u "$userid" -g "$groupid" -d "$homedir" "$username"
    fi

    echo "- Enabling user $username"
    passwd -d -u "$username"
  else
    echo "- User exists: $username"
  fi
done


mkdir -p /var/run/sshd

found_key=false

for key in /etc/ssh/ssh_host_*_key; do
  if [ -e "$key" ]; then
    found_key=true
    echo "- Found ssh host keys in container"
    break
  fi
done

if [ "$found_key" = false ]; then
  for key in /data/ssh/ssh_host_*_key; do
  if [ -e "$key" ]; then
      echo "- Found ssh host keys in /data/ssh"
      echo "- Copying ssh config to /etc/ssh"
      found_key=true
      rm -rf /etc/ssh
      cp -a /data/ssh /etc/ssh
      break
  fi
  done
fi

if [ "$found_key" = false ]; then
  for key in /data/ssh.base/ssh_host_*_key; do
    if [ -e "$key" ]; then
      found_key=true
      echo "- Found ssh host keys in /data/ssh.base"
      echo "- Copying base config to /data/ssh.base"
      echo "- NOTE: STRONGLY RECOMMEND EDITING DEFAULTS"
      echo "- EXPOSE AT /data/ssh WHEN ADJUSTED"
      rm -rf /etc/ssh
      cp -a /data/ssh.base /etc/ssh
      break
    fi
  done
fi

if [ "$found_key" = false ]; then
  echo "- Generating SSH host keys..."
  ssh-keygen -A
  cp -a /etc/ssh /data/ssh.base
else
  echo "- /etc/ssh exists, nothing to do"
fi

exec /usr/sbin/sshd.pam -D -e
