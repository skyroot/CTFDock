FROM debian

# Change apt sources list
RUN \
  echo 'deb http://debian.uberglobalmirror.com/debian/ stable main contrib' > /etc/apt/sources.list && \
  echo 'deb-src http://debian.uberglobalmirror.com/debian/ stable main contrib' >> /etc/apt/sources.list && \
  echo 'deb http://security.debian.org/ jessie/updates main' >> /etc/apt/sources.list && \
  echo 'deb-src http://security.debian.org/ jessie/updates main' >> /etc/apt/sources.list

# Add the Peleus user
RUN \
  groupadd -g 1000 peleus && \
  useradd -m -s /usr/bin/zsh -u 1000 -g 1000 -G sudo peleus && \
  echo peleus:peleus | chpasswd && \
  chmod 700 /home/peleus

# Install dependancies
RUN \
  apt-get update && \
  apt-get install sudo git coreutils net-tools isc-dhcp-client openssh-client openssh-server zsh curl wget vim python-pip python-dev libffi-dev libssl-dev apt-file gdbserver ruby2.1 ruby2.1-dev \
  build-essential libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev gdb supervisor \
  autoconf postgresql-9.4 zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev zlib1g-dev nmap -y && \
  apt-file update && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure peleus user
USER peleus
ADD ./files/vimrc /home/peleus/.vimrc
ADD ./files/vim /home/peleus/.vim
ADD ./files/id_rsa.pub /home/peleus/.ssh/authorized_keys
ADD ./files/tmux.conf /home/peleus/.tmux.conf

# Set up oh-my-zsh
RUN \
  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

ADD ./files/zshrc /home/peleus/.zshrc
ADD ./files/peleus.zsh-theme /home/peleus/.oh-my-zsh/themes/peleus.zsh-theme

# Setup metasploit database
USER root
ADD ./scripts/db.sql /tmp/
RUN \
  mkdir /var/lib/gems && \
  chown -R peleus:peleus /var/lib/gems && \
  chown -R peleus:peleus /usr/local

USER postgres
RUN \
  /etc/init.d/postgresql start && \
  psql -f /tmp/db.sql

# Setup metasploit
USER peleus
RUN \
  mkdir /home/peleus/Tools && \
  cd /home/peleus/Tools && \
  git clone https://github.com/rapid7/metasploit-framework.git

# Setting up symlinks
USER root
RUN \
  ln -s /usr/bin/ruby2.1 /usr/bin/ruby && \
  ln -s /usr/bin/gem2.1 /usr/bin/gem

# Installing metasploit gems
USER peleus
RUN \
  gem install bundler && \
  cd /home/peleus/Tools/metasploit-framework && \
  bundle install && \
  for MSF in $(ls msf*); do ln -s /home/peleus/Tools/metasploit-framework/$MSF /usr/local/bin/$MSF; done

ADD ./files/database.yml /home/peleus/Tools/metasploit-framework/config/database.yml

# Set up peda
RUN \
  cd /home/peleus/Tools/ && \
  git clone https://github.com/longld/peda.git

ADD ./files/gdbinit /home/peleus/.gdbinit

# Setup HashID
RUN \
  cd /home/peleus/Tools/ && \
  git clone https://github.com/psypanda/hashID.git

# Setup Sqlmap
RUN \
  cd /home/peleus/Tools/ && \
  git clone https://github.com/sqlmapproject/sqlmap.git 

# Setup gobuster
RUN \
  cd /home/peleus/Tools/ && \
  wget https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.6.2.linux-amd64.tar.gz && \
  git clone https://github.com/OJ/gobuster.git

ENV GOPATH=/usr/local/go/path

RUN \
  cd /home/peleus/Tools/gobuster && \
  mkdir /usr/local/go/path && \
  /usr/local/go/bin/go get golang.org/x/crypto/ssh && \
  /usr/local/go/bin/go build main.go && \
  mv ./main ./gobuster && \
  wget https://raw.githubusercontent.com/0x42424242/subbrute/master/names.txt && \
  cd .. && \
  rm go1.6.2.linux-amd64.tar.gz

# Install angr
USER root
RUN \
  pip install angr 

# Install pwntools
RUN \
  pip install --upgrade cffi && \
  pip install pwntools

# Setting up supervisor
ADD ./files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN \
  mkdir -p /var/run/sshd /var/log/supervisor

# Set permissions for supervisor
RUN \
  chown -R peleus:peleus /home/peleus

# Add 32 bit support
RUN \
  dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install libstdc++6:i386 libgcc1:i386 zlib1g:i386 libncurses5:i386 -y

# Reinstall capstone for angr
RUN \
  apt-get install libcapstone-dev -y


EXPOSE 22
CMD ["/usr/bin/supervisord"]
