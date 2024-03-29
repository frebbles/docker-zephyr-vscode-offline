#!/usr/bin/env sh

# The directory to inherit permissions from
WHO=/workdir

# Work out if the folder exists
stat $WHO > /dev/null || (echo You must mount a file to "$WHO" in order to properly assume user && exit 1)

# Infer the USERID and GROUPID of the host
USERID=$(stat -c %u $WHO)
GROUPID=$(stat -c %g $WHO)
USERNAME=user

echo $USERNAME $USERID $GROUPID

# Create the user
deluser $USERNAME --remove-home > /dev/null 2>&1
addgroup --gid $GROUPID $USERNAME
adduser -u $USERID $USERNAME --gid $GROUPID --disabled-password --gecos 'Temporary User,,,,'

# Add the user to the zephyr and vscode group for runtime access to files and executables
usermod -a -G zephyr $USERNAME
usermod -a -G vscode $USERNAME
usermod -a -G sudo $USERNAME

# Add vscode default config to workdir if it doesnt exist.
if [ ! -d "/workdir/.vscode" ]; then
  cp -r /opt/vscode/vscode_default /workdir/.vscode
  chown $USERID:$GROUPID -R /workdir/.vscode
fi

# Add the user to the sudo list without a need for a password
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers

gosu $USERNAME "$@"
