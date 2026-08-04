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
GatewayPorts no
X11Forwarding no
PermitRootLogin no
#Subsystem sftp internal-sftp
Subsystem sftp /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO
UsePAM yes
ChallengeResponseAuthentication yes
PasswordAuthentication no
AuthenticationMethods publickey,keyboard-interactive

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
EOF

RUN cat <<'EOF' > /etc/pam.d/sshd
#%PAM-1.0                                                                                                                                                                                                                                       
auth            required        pam_google_authenticator.so       echo_verification_code grace_period=57600 nullok
EOF

RUN ln /etc/pam.d/sshd /etc/pam.d/sshd.pam

EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
