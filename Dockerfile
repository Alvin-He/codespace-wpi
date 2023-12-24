FROM ubuntu:22.04

# update OS 
RUN apt-get update -y
RUN apt-get update --fix-missing -y
RUN apt-get upgrade -y 

# install libraries
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

#upload internal scripts 
ARG _script_path=/usr/share/wpi_codespace
RUN mkdir ${_script_path} && chmod 755 ${_script_path}
# env files for internal scripts
ADD --chmod=755 ./.env ${_script_path}/.env
ADD --chmod=755 ./config.conf ${_script_path}/config.conf
# internal scripts
ADD --chmod=755 ./java_install.bash ${_script_path}/java_install.bash
ADD --chmod=755 ./configure_mounting.bash ${_script_path}/configure_mounting.bash
ADD --chmod=777 ./downloader.bash ${_script_path}/downloader.bash
ADD --chmod=777 ./start_up.bash ${_script_path}/start_up.bash

# the home directory of the main user will be the install directory
WORKDIR ${_home_dir}
# working under user account now
USER system 

# prep directories
RUN mkdir wpilib vscode 
RUN mkdir ./wpilib/2023


# java 17 install 
# install script need to be ran with root
USER 0 
RUN ${_script_path}/java_install.bash
USER system
# ENV JAVA_HOME=/home/system/wpilib/2023/jdk
ENV PATH=/home/system/wpilib/2023/jdk/bin:${PATH}

# set up symlinks to shared_cache volume
RUN ${_script_path}/configure_mounting.bash

# download vscode cli 
RUN ${_script_path}/downloader.bash vscode ./vscode/bin/
ENV PATH=/home/system/vscode/bin:${PATH}
ENV DONT_PROMPT_WSL_INSTALL=true 

WORKDIR ${_home_dir}/vscode
RUN mkdir user_data server_data extensions 
# ADD ./sources/wpilib/2023/vsCodeExtensions ./wpilib/vsVodeExtensions
ADD --chown=system --chmod=777 ./sources/extensions ./extensions
ADD --chown=system --chmod=777 ./sources/vscode_userSettings/settings.json ./server_data/data/Machine/settings.json

USER 0
WORKDIR /home/system/
CMD /usr/share/wpi_codespace/start_up.bash
# CMD bash
# EXPOSE 22
# #EXPOSE 3389
# EXPOSE 8000