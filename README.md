# Sci2 Docker container with VNC

Sci2 in a Docker container accessed via VNC (over HTTP)

This Github repository contains resources for building Docker image based on Ubuntu containing Sci2, Gephi and VNC. If you are a Sci2/Gephi user, you don't need to build an image yourself. The associated image is already available on [Docker Hub][docker-hub-repo] and can directly be run using `docker run` command. The details are provided in the **[Running Sci2 container in background](##Running-Sci2-container-in-background)** section.

Running a container bundled with Sci2 and Gephi in background so that the users don't have to install these softwares on their local system is the primary use-case for building this image. The container, once run, can be used directly from any modern web browser over VNC.

The image contains the following components:
- light-weight desktop environment
- Sci2 and Gephi applications accessible through Desktop links
- popular text editor vim
- lite but advanced graphical editor mousepad

## Running Sci2 container in background

Docker is required for running the container. Steps to install and get Docker running on Windows systems are available [here][install-docker-for-win]. For Mac users, they are available [here][install-docker-for-mac].

Once Docker is running, open terminal and execute the following command.
```
docker run -d -p 6901:6901 -v ~/Downloads:/home/headless/Dropbox -t cnsiu/sci2-vnc
```
The command will download the container image from Docker's image repository, and run the container in background. It also run an HTML5 client on TCP port **6901** and exposes it to be accessed by a browser on the host system. In addition, it mounts `~/Downloads` directory in the host system to a volume (also visible as a directory) `/home/headless/Dropbox` in the container OS. Mounting basically creates a bridge between the host's file system and the container's file system, so the files in `~/Downloads` are accessible via volume `/home/headless/Dropbox` in the container. You can change these mapped directories to other locations in the command to suit your needs.

You can see all the containers running in background using `docker ps` command.

![running the container][running-container]

To be able to use the container over VNC, any modern web browser needs to be used. Chrome, Firefox, Safari or Microsoft Edge are supported browsers.

Open a browser and navigate to `http://localhost:6901/vnc.html?password=headless` and click on `Connect` button to access the container's desktop environment. If you are not using your local system, specify NAS path of the host system instead of localhost.

![container-desktop][container-desktop]

Click the slider visible nearby Gephi icon in the above image. noNVC configuration options should be accessible now. Click on `Settings` and change the `Scaling mode:` to `Remote Resizing`. This will maximize the GUI window to fill up all the space in the browser window. There is also a button to toggle FullScreen mode.

## Stopping the container
Execute `docker ps` to list all the running containers. Stop the container with `docker stop` command using the first 4 characters of the CONTAINER_ID associated with image `cnsiu/sci2-vnc` as shown in the image below.
![stopping-container][stopping-container]


## Credits
Dockerfile used for building Sci2 image has been adapted from [accetto][accetto-ubuntu-vnc-xfce]'s Dockerfile for building a base image with VNC server. Thanks to [accetto][accetto-ubuntu-vnc-xfce] for making his code available to public!

[accetto-ubuntu-vnc-xfce]: https://github.com/accetto/ubuntu-vnc-xfce

[running-container]:https://github.com/CIShell/sci2-docker-vnc/blob/master/docs/running-container.png
[stopping-container]:https://github.com/CIShell/sci2-docker-vnc/blob/master/docs/stopping-container.png
[container-desktop]: https://github.com/CIShell/sci2-docker-vnc/blob/master/docs/desktop.png


[docker-hub-repo]: https://cloud.docker.com/u/cnsiu/repository/docker/cnsiu/sci2-vnc
[install-docker-for-mac]: https://docs.docker.com/docker-for-mac/install/
[install-docker-for-win]: https://docs.docker.com/docker-for-windows/install/
