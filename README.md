# Docker image for stand-alone/offline vscode/zephyr development

Much of the zephyr/vscode installation and updates system incorporates a lot of pulling information 
from various repositories from the internet in order to complete a full build setup. 

On systems where hardware is being developed with security in mind, air gaps, or limited 
internet access hand severely hinder being able to setup a proper build environment without 
having all repositories available.

Instead of having to transfer a full Virtual Machine, or attempt a full installation on a 
non internet connected system (welcome to dependency hell), this zephyr docker image 
intends to enable building and debugging a zephyr application without requiring an internet 
connection.

Includes a vscode-server instance with pre-installed plugins for debugging with openocd via
STLink on the nucleo dev boards.

## Requirements (Tested working with)

 * Windows or Ubuntu Host machine with USB Passthrough for STMicro device.
   * Virtual Box VM
     * Ubuntu 18:04/20:04 LTS
     * Docker
     * Docker Compose

NOTE: Not recommended to run under Windows 10 bare-metal with Docker, the USB device passthrough isn't
working properly.

## Docker Compose Installation

To install Docker Compose on linux, run:

```sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose```

And then apply executable permissions to the binary:

```sudo chmod +x /usr/local/bin/docker-compose```

## Running the Development Environment
To run the image, execute:

```docker-compose up```

If you don't want logs and to be attached to the image, execute:

```docker-compose up -d```

To gain a terminal to the container, run:

```docker ps```

And then run:

```docker exec -it <insert container id> bash```

Which will give you a terminal with West and other required tools installed. Alternatively, you can use Visual Studio Code's terminal by hitting:

```ctrl + I```

## A note about permissions

The docker-compose needs your host's ID for file write back, otherwise it will write back as root. To do this, create workdir and map it to /workdir (as shown in the docker-compose.yaml file) using the user you want to model permissions from.

## Running Zephyr builds

The intended operation is that on your local machine you would have a Zephyr application 
or working directory, this would be the <local path to zephyr working dir> and would be 
mapped using the command below to /workdir in the docker container. 
All compiles/builds would then be kept persistent in your local
machine environment and the build environment would remain unchanged.

Then, follow the steps below to build a sample application:

```
cd samples/hello_world
mkdir build
cd build
cmake -DBOARD=nucleo_f746zg ..
make run
```

We can also run based off west tool as per zephyr's getting started:

```
west build -p auto -b nucleo_f746zg /zephyrproject/zephyr/samples/basic/blinky
west flash
```

## Toolchain variants

We have two toolchains installed as a part of this image:
- Zephyr SDK
- GNU Arm Embedded Toolchain

To switch, set ZEPHYR_TOOLCHAIN_VARIANT, [zephyr|gnuarmemb]

## VSCode access

Launch a host system web browser to 

```http://localhost:8080```

Which will allow you to begin using the vscode environment, if you want to 
enable debugging, you will need to follow the next steps.

## Programming/Debugging/Flashing

Firstly, copy all the files from the vscode_default directory to the .vscode directory
in your workspace, this will configure the debuggers for the environment. Assuming you
start Docker with connection to your Zephyr app mapped to /workdir, the following
should do the trick.

```
cd /home/user
cp ./vscode_default/ /workdir/.vscode/
```

1. Programming with 

```west flash```

To ensure this works you will likely require adding an appropriate udev rules file that will give
docker permissions to access the device, also requiring the --privileged docker run option.

An example for an ST-Link V2 exists as 66-stlink-rule.rules and can be installed/added by:

```sudo cp 66-stlink-rule.rules /etc/udev/rules.d/```

on your host machine.

2. Monitoring

Using the following command you can view the stdout of the STLink/F7 from Zephyr

```minicom -b 115200 -D /dev/ttyACM0```

3. Debugging

After performing a clean flash, debugging can be started from within VSCODE by 
clicking the debugging icon on the left and selecting the "start" arrow to trigger the 
debugger.

Debugging with other tools can be triggered by (with default project under /workdir/build)

Start OpenOCD with gdb connection service on 50000
```/opt/toolchains/zephyr-sdk-0.11.2/sysroots/x86_64-pokysdk-linux/usr/bin/openocd -c "gdb_port 50000" -s /workdir -f /zephyrproject/zephyr/boards/arm/nucleo_f746zg/support/openocd.cfg```

Via a second terminal:
```docker exec -ti "container name" bash```

Connect gdbgui (accessible on host via web browser on localhost:5000)
```python3 -m gdbgui -g /opt/toolchains/zephyr-sdk-0.11.2/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb --host 0.0.0.0 --project /workdir/build```

## Moving the Docker image

To export:
```docker save -o ./zephyr-build-xxx.tar zephyr_doc:v1```

Can be gzipped quite effectively!
```gzip zephyr-build-xxx.tar```

Move via whatever method you like

To import:
```docker load -i zephyr-build-xxx.tar```

