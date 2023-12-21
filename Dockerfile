FROM ubuntu:22.04

# update OS 
RUN apt-get update -y
RUN apt-get update --fix-missing -y
RUN apt-get upgrade -y 

# # install libraries
# technically build-essential is not needed, but libc-bin will error if we don't pre install it from build-essential first
RUN apt install build-essential -y
RUN apt install sudo -y

# only built on gui versions
# RUN apt install xfce4 -y
# RUN apt install xrdp -y

RUN apt install ssh -y 
RUN apt install git -y 

# create the main operating user to use with codespace !!!Hide passwd later!!!
ARG _home_dir=/home/system
ARG PASSWD=frc4669
RUN _system_user_passwd=$(perl -e 'print crypt($ARGV[0], "password")' ${PASSWD}) &&\
    useradd system -p ${_system_user_passwd} -d ${_home_dir} -m -G sudo -s /bin/bash

# the home directory of the main user will be the install directory
WORKDIR ${_home_dir}
# working under user account now
USER system 

# prep directories
RUN mkdir wpilib vscode 
RUN mkdir ./wpilib/2023
# #wpilib java copy 
# ADD --chown=system --chmod=777 ./sources/wpilib/2023/jdk ./wpilib/2023/jdk
# ENV JAVA_HOME=/home/system/wpilib/2023/jdk
# ENV PATH=/home/system/wpilib/2023/jdk/bin:${PATH}

# java 17 install 

ADD --chown=system --chmod=777 ./java_install.bash ./java_install.bash
# install script need to be ran with root
USER 0 
RUN ./java_install.bash
USER system
# ENV JAVA_HOME=/home/system/wpilib/2023/jdk
ENV PATH=/home/system/wpilib/2023/jdk/bin:${PATH}

# #wpilib toolchain copy 
# ADD --chown=system --chmod=777 ./sources/wpilib/2023/roborio/ ./wpilib/2023/roborio

#wpilib toolchain install
# RUN git clone https://github.com/wpilibsuite/GradleRIO.git -b v2023.4.3
# WORKDIR ${_home_dir}/GradleRIO
# RUN ./gradlew installRoboRioToolchain

# set up the shared wpilib toolchain directory
RUN mkdir -p ./wpilib/2023/ && ln -s /mnt/shared_caches/roborio ./wpilib/2023/

# decompresses to code 
# ADD --chown=system ./sources/vscode_cli_alpine_x64_cli.tar.gz ./vscode/bin/
ADD --chown=system --chmod=777 ./sources/vscode_cli_alpine_arm64_cli.tar.gz ./vscode/bin/
ENV PATH=/home/system/vscode/bin:${PATH}
ENV DONT_PROMPT_WSL_INSTALL=true 

WORKDIR ${_home_dir}/vscode
RUN mkdir ./bin/cli user_data server_data extensions 
# ADD ./sources/wpilib/2023/vsCodeExtensions ./wpilib/vsVodeExtensions
ADD --chown=system --chmod=777 ./sources/extensions ./extensions
ADD --chown=system --chmod=777 ./sources/vscode_userSettings/settings.json ./server_data/data/Machine/settings.json

RUN echo cache invalidate
USER 0
ADD ./start_up.bash /usr/sbin/start_up.bash
RUN chmod 777 /usr/sbin/start_up.bash
CMD /usr/sbin/start_up.bash

# EXPOSE 22
# #EXPOSE 3389
# EXPOSE 8000