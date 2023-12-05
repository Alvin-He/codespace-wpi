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

# file copy prep and copy from host
RUN mkdir wpilib vscode 

#wpilib java copy 
ADD --chown=system ./sources/wpilib/2023/jdk ./wpilib/2023/jdk
ENV JAVA_HOME=/home/system/wpilib/2023/jdk
ENV PATH=/home/system/wpilib/2023/jdk/bin:${PATH}

#wpilib toolchain copy 
ADD --chown=system ./sources/wpilib/2023/roborio/ ./wpilib/2023/roborio

# decompresses to code 
# ADD --chown=system ./sources/vscode_cli_alpine_x64_cli.tar.gz ./vscode/bin/
ADD --chown=system ./sources/vscode_cli_alpine_x64_arm64.tar.gz ./vscode/bin/
ENV PATH=/home/system/vscode/bin:${PATH}
ENV DONT_PROMPT_WSL_INSTALL=true 

WORKDIR ${_home_dir}/vscode
RUN mkdir ./bin/cli user_data server_data extensions 
# ADD ./sources/wpilib/2023/vsCodeExtensions ./wpilib/vsVodeExtensions
ADD --chown=system ./sources/extensions ./extensions
ADD --chown=system ./sources/vscode_userSettings/settings.json ./server_data/data/Machine/settings.json

USER 0
ADD ./start_up.bash /usr/sbin/start_up.bash
RUN chmod 777 /usr/sbin/start_up.bash
CMD /usr/sbin/start_up.bash

EXPOSE 22
#EXPOSE 3389
EXPOSE 8000