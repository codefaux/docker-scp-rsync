FROM alpine:latest

RUN apk add --no-cache \
    shadow \
    openssh-server-pam \
    openssh-sftp-server \
    rsync \
    google-authenticator

RUN apk del apk-tools libapk
RUN rm -rf /etc/motd /etc/alpine-release /etc/apk /etc/crontabs /etc/periodic /etc/fstab /etc/inittab /etc/issue /etc/modprobe.d /etc/modules /etc/modules-load.d /etc/network /etc/opt /etc/os-release /etc/protocols /etc/secfixes.d /etc/securetty /etc/sysctl.d /etc/udhcpc


RUN rm /etc/ssh/sshd_config
RUN cat <<'EOF' > /etc/ssh/sshd_config
AuthorizedKeysFile      .ssh/authorized_keys
AllowAgentForwarding no
AllowStreamLocalForwarding no
AllowTcpForwarding no
DisableForwarding yes
GatewayPorts no
X11Forwarding no
PermitRootLogin no
PermitEmptyPasswords no
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
PasswordAuthentication no
GSSAPIAuthentication no
HostbasedAuthentication no
PermitUserEnvironment no
PermitUserRC no
#Subsystem sftp internal-sftp
Subsystem sftp /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO
UsePAM yes
PasswordAuthentication no
AuthenticationMethods publickey,keyboard-interactive

PerSourceMaxStartups 2:85:4
MaxAuthTries 2
PerSourcePenalties noauth:24h invaliduser:24h authfail:24h grace-exceeded:24h
PerSourceNetblockSize 24:64

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
EOF

RUN cat <<'EOF' > /etc/pam.d/sshd
#%PAM-1.0
auth required pam_google_authenticator.so   grace_period=7200
EOF

RUN ln /etc/pam.d/sshd /etc/pam.d/sshd.pam

EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
