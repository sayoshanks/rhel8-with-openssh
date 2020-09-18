FROM registry.access.redhat.com/ubi8/ubi-init

ARG user
ARG userpass
ARG rootuser
ARG rootuserpass
ARG pub_key

RUN yum install sudo -y
RUN sed -i '/%wheel\s*\ALL=(ALL)\s*\NOPASSWD: ALL/s/^# //g' /etc/sudoers
RUN sed -i '/%wheel\s*\ALL=(ALL)\s*\ALL/s/^/#/g' /etc/sudoers #comment
RUN echo '$$rootuser:$$rootuserpass' | sudo chpasswd
#User Creation
RUN useradd -G wheel $user
RUN echo '$user:$userpass' | sudo chpasswd
RUN mkdir /home/$user/.ssh && \
chmod 700 /home/$user/.ssh && \
touch /home/$user/.ssh/authorized_keys && \
chmod 600 /home/$user/.ssh/authorized_keys && \
echo "$pub_key" >> /home/$user/.ssh/authorized_keys && \
chown $user -R /home/$user/.ssh


RUN mkdir /$rootuser/.ssh && \
chmod 700 /$rootuser/.ssh && \
touch /$rootuser/.ssh/authorized_keys && \
chmod 600 /$rootuser/.ssh/authorized_keys && \
echo "$pub_key" >> /$rootuser/.ssh/authorized_keys

RUN yum install diffutils.x86_64 -y && \
yum install wget -y && \
dnf install zlib-devel openssl-devel -y && \
yum install pam.x86_64 -y && \
yum install pam.i686 -y && \
yum install systemd-pam.x86_64 -y && \
yum install passwd.x86_64 -y

RUN cd $home && \
mkdir open && \
cd open && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/pam-1.3.1-8.el8.x86_64.rpm && \
yum install  pam-1.3.1-8.el8.x86_64.rpm -y && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/pam-devel-1.3.1-8.el8.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/pam_ssh_agent_auth-0.10.3-7.4.el8_1.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/pam_ssh_agent_auth-0.10.3-7.4.el8_1.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/libcgroup-pam-0.41-19.el8.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/libselinux-2.9-3.el8.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/libselinux-devel-2.9-3.el8.x86_64.rpm && \
wget -c http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/libselinux-utils-2.9-3.el8.x86_64.rpm && \
yum install libselinux-2.9-3.el8.x86_64.rpm -y && \
yum install libselinux-devel-2.9-3.el8.x86_64.rpm -y && \
yum install libselinux-utils-2.9-3.el8.x86_64.rpm -y && \
yum install pam-devel-1.3.1-8.el8.x86_64.rpm -y && \
yum install pam_ssh_agent_auth-0.10.3-7.4.el8_1.x86_64.rpm -y && \
yum install pam_ssh_agent_auth-0.10.3-7.4.el8_1.x86_64.rpm -y && \
yum install libcgroup-pam-0.41-19.el8.x86_64.rpm -y && \
yum install make -y && \
dnf install gcc -y

RUN sudo mkdir /var/lib/sshd && \
chmod -R 700 /var/lib/sshd/ && \
chown -R $rootuser:sys /var/lib/sshd/ && \
useradd -r -U -d /var/lib/sshd/ -c "sshd privsep" -s /bin/false sshd
#-r – tells useradd to create a system user
#-U – instructs it to create a group with the same name and group ID
#-d – specifies the users directory
#-c – used to add a comment
#-s – specifies the user’s shell


RUN mkdir openssh && \
cd openssh && \
sudo wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.3p1.tar.gz && \
tar -xzf openssh-8.3p1.tar.gz && \
cd openssh-8.3p1 && \
./configure --with-md5-passwords --with-pam --with-selinux --with-privsep-path=/var/lib/sshd/ --sysconfdir=/etc/ssh  && \
make && \
sudo make install
RUN cp  /usr/local/sbin/sshd /usr/sbin
RUN cp  /usr/local/sbin/sshd /usr/bin


RUN echo -e "[Unit] \nDescription=OpenSSH server daemon \nDocumentation=man:sshd(8) man:sshd_config(5) \nAfter=network.target sshd-keygen.target \nWants=sshd-keygen.target \n[Service] \nType=notify \nEnvironmentFile=-/etc/crypto-policies/back-ends/opensshserver.config \nEnvironmentFile=-/etc/sysconfig/sshd \nExecStart=/usr/sbin/sshd -D $OPTIONS $CRYPTO_POLICY \nExecReload=/bin/kill -HUP $MAINPID \nKillMode=process \nRestart=on-failure \nRestartSec=42s \n[Install] \nWantedBy=multi-user.target" > /usr/lib/systemd/system/sshd.service

RUN systemctl enable sshd
#systemctl daemon-reload
#systemctl status sshd
#RUN cd $home && \
#mkdir bootscript && \
#wget -c http://anduin.linuxfromscratch.org/BLFS/blfs-bootscripts/blfs-bootscripts-20200818.tar.xz && \
#yum install xz -y && \
#unxz blfs-bootscripts-20200818.tar.xz && \
#tar -xvf blfs-bootscripts-20200818.tar && \
#cd blfs-bootscripts-20200818 && \
#make install-sshd
