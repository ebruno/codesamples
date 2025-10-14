# codesamples #
Coding samples in various languages

## git client-side hooks ##
The repository has git client-side hooks defined if .githooks/hooks.

	To enable them copy them to
	   cp .githooks/* .git/hooks
	or
	   git config core.hooksPath .githooks

## Installing Runners ##
For experimentation it be useful to use gitlab and github runners
That are hosted in a local environment.

To add the capability to run podman or docker containers under the runner you will
need to install podman or docker.

**Only install podman or docker-ce not both.**
### Installing podman ###
Install podman before gitlab-runner or github runner.

 * RHEL10 | Fedora Server 42 | Fedora Workstation 42
	   sudo dnf -y install podman podman-docker cockpit-podman

 * Debian 13 | Ubuntu 24.04
	   sudo apt-get -y podman  podman-docker cockpit-podman


### Installing docker-ce ###
Install dockered before gitlab-runner or github runner

Validate installation instructions at: [Installing Docker CE](https://docs.docker.com/engine/install/)

#### Debian 13 ####

	 # Add Docker's official GPG key:
	 sudo apt-get update
	 sudo apt-get install ca-certificates curl
	 sudo install -m 0755 -d /etc/apt/keyrings
	 sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	 sudo chmod a+r /etc/apt/keyrings/docker.asc

	 # Add the repository to Apt sources:
	 echo \
	   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
	   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	 sudo apt-get update


### Gitlab Runner ###
Current instructions can be found here [Installing Gitlab Runner](https://docs.gitlab.com/runner/install/)

For the examples here both the AWS and GCP cli's should be installed for so then can be access
by the shell runner.

#### Installing AWS cli ####

 * Linux systems

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install

#### Installing GCP cli ####

 * Debian systems

sudo apt-get install apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get -y install google-cloud-cli

#### Installing on Debian 13 ####
It is recommend that gitlab OS specific repositories be used to install gitlab runner.

	 curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
	 sudo apt-get -y install gitlab-runner

Next go to your gitlab server and add a new linux runner

#### Shell runner ####
When registering the runner select docker as the runner type.
sample runner tags: debian13_shell,libvirt

	  sudo gitlab-runner register  --url https://gitlab01.brunoe.net  --token <valid gitlab token>
	  Runtime platform                                    arch=amd64 os=linux pid=14832 revision=139a0ac0 version=18.4.0
	  Running in system-mode.

	  Enter the GitLab instance URL (for example, https://gitlab.com/):
	  [https://gitlab01.brunoe.net]:
	  Verifying runner... is valid                        correlation_id=<valid correlation_id> runner=aXZA2LsmF
	  Enter a name for the runner. This is stored only in the local config.toml file:
	  [fqdn current system]: debian13_shell_libvirt
	  Enter an executor: parallels, docker-windows, instance, shell, virtualbox, docker, docker+machine, kubernetes, docker-autoscaler, custom, ssh:
	  shell
	  Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

	  Configuration (with the authentication token) was saved in "/etc/gitlab-runner/config.toml"
	  ebruno@shuttle01:~/Downloads$ sudo gitlab-runner list
	  Runtime platform                                    arch=amd64 os=linux pid=14897 revision=139a0ac0 version=18.4.0
	  Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml
	  debian_13_docker                                    Executor=docker Token=glrt-KSw54TTwPHFgCS60JHHwaG86MQp0OjEKdToyCw.01.120pear34 URL=https://gitlab01.brunoe.net
	  debian13_shell_libvirt                              Executor=shell Token=glrt-aXZA2LsmFFzbDTHPZM95tm86MQp0OjEKdToyCw.01.120jhqfft URL=https://gitlab01.brunoe.net

#### Configure to work with Docker ####
When registering the runner select docker as the runner type.
sample runner tag: debian13_docker

	 sudo gitlab-runner register  --url https://gitlab01.brunoe.net  --token <valid gitlab token>
	 Runtime platform                                    arch=amd64 os=linux pid=10105 revision=139a0ac0 version=18.4.0
	 Running in system-mode.

	 Enter the GitLab instance URL (for example, https://gitlab.com/):
	 [https://gitlab01.brunoe.net]:
	 Verifying runner... is valid                        correlation_id=<correlation_id> runner=KSw54TTwP
	 Enter a name for the runner. This is stored only in the local config.toml file:
	 [fqdn current system]: debian_13_docker
	 Enter an executor: docker+machine, docker-autoscaler, instance, ssh, virtualbox, kubernetes, custom, shell, parallels, docker, docker-windows:
	 docker
	 Enter the default Docker image (for example, ruby:3.3):
	 optionfactory/debian13:205
	 Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

	 Configuration (with the authentication token) was saved in "/etc/gitlab-runner/config.toml"

#### Configure to work with Podman ####


It is necessary to manually edit the config.toml file

Once gitlab-runner is installed you need to do some some addition podman setup.
Make sure you have the following line in your sudoers file:

 <your user name> ALL=(ALL)  NOPASSWD: ALL
 or
 <your user name> ALL=(gitlab-runner)  NOPASSWD: ALL

	sudo loginctl enable-linger gitlab-runner

	# Note the gitlab-runner shell providing podman
	# needs to have /etc/subuid and /etc/setgid configured.
	# Check if values exist if not add them.
	# Newer version of linux do not automatically configure sub uids and gids
	# for system accounts. gitlab-runner is installed with a system account
	# UID/GID on system distributions.
	# UID and GID ranges for users should not overlap.
	GLR_SUBUID=$(($(tail -1 /etc/subuid |awk -F ":" '{print $2}')+65536))
	GLR_SUBGID=$(($(tail -1 /etc/subgid |awk -F ":" '{print $2}')+65536))
	#
	sudo usermod \
	--add-subuids ${GLR_SUBUID}-$((${GLR_SUBUID}+65535)) \
	--add-subgids ${GLR_SUBGID}-$((${GLR_SUBGID}+65535)) gitlab-runner;
	# You may need to login to the gitlab-runner
	# account, set a passwd for the account if needed,
	# and run the following command:
	# podman system migrate
	# If does not build correctly when logged in to gitlab-runner account
	# it will not work under the runner

	sudo systemctl --machine=gitlab-runner@.host --user --now enable podman.socket
	sudo systemctl --machine=gitlab-runner@.host status --user podman.socket

	  * podman.socket - Podman API Socket
	   Loaded: loaded (/usr/lib/systemd/user/podman.socket; enabled; preset: disabled)
	   Active: active (listening) since Mon 2025-09-08 15:40:05 PDT; 6h left
	 Invocation: 09a020fc81e24207bac806dc84bec9a1
	 Triggers: * podman.service
		 Docs: man:podman-system-service(1)
	   Listen: /run/user/975/podman/podman.sock (Stream) # This goes in the config.toml file.
	   CGroup: /user.slice/user-975.slice/user@975.service/app.slice/podman.socket

	loginctl enable-linger gitlab-runner # Replace 'gitlab-runner' with your runner user if different




#### Sample config.tmpl ####

Check /etc/passwd for gitlab-runner uid this needs
to been the configuration file.

On Debian 13 this located in /etc/gitlab-runner
Items to note 975 is gitlab-runner uid.
Add a docker runner to you configuration
Add this to the config.toml file.


	 [[runners]]
	   name = "debian13podman"
	   url = "<your gitlab server>"
	   id = <numeric id based on gitlab server>
	   token = "<a runner token>"
	   token_obtained_at = 2025-09-06T21:05:05Z
	   token_expires_at = 0001-01-01T00:00:00Z
	   executor = "docker"
	   [runners.cache]
		 MaxUploadedArchiveSize = 0
		 [runners.cache.s3]
		 [runners.cache.gcs]
		 [runners.cache.azure]
	   [runners.docker]
		 host = "unix:///run/user/975/podman/podman.sock"
		 tls_verify = false
		 image = "docker.io/library/redhat/ubi10:latest"
		 privileged = false
		 disable_entrypoint_overwrite = false
		 oom_kill_disable = false
		 pull_policy = ["if-not-present"]
		 disable_cache = false
		 volumes = ["/var/cache/gitlab-runner/cache:/cache", "/run/user/975/podman/podman.sock:/var/run/podman/podman.sock"]
		 network_mode = "bridge"
		 shm_size = 0
		 network_mtu = 0

Restart the gitlab-runner service.

	 sudo systemctl restart gitlab-runner

Check the status of the service you many need to increase:

  * concurrency in the global section.
  * request_concurrency for the each runner

Verify the runners.

	  sudo gitlab-runner list
	  Runtime platform                                    arch=amd64 os=linux pid=7344 revision=5a021a1c version=18.3.1
	  Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml
	  debian13server                                        Executor=shell Token=<a token> URL=https://gitlab01.brunoe.net
	  debian13podman                                        Executor=docker Token=<a token> URL=https://gitlab01.brunoe.net



Sample complete config.toml with shell runner and podman runner

	 concurrent = 3
	 check_interval = 0
	 connection_max_age = "15m0s"
	 shutdown_timeout = 0

	 [session_server]
	   session_timeout = 1800

	 [[runners]]
	   name = "debian13server"
	   url = <your gitlab server url>"
	   id = 31
	   token = "<a runner token>"
	   token_obtained_at = 2025-09-02T21:59:17Z
	   token_expires_at = 0001-01-01T00:00:00Z
	   executor = "shell"
	   request_concurrency = 2
	   [runners.cache]
		 MaxUploadedArchiveSize = 0
		 [runners.cache.s3]
		 [runners.cache.gcs]
		 [runners.cache.azure]

	 [[runners]]
	   name = "debian13podman"
	   url = <your gitlab server url>"
	   id = 38 # this will need to changed to match your environment.
	   token = "<a runner token"
	   token_obtained_at = 2025-09-06T21:05:05Z
	   token_expires_at = 0001-01-01T00:00:00Z
	   executor = "docker"
	   request_concurrency = 2
	   [runners.cache]
		 MaxUploadedArchiveSize = 0
		 [runners.cache.s3]
		 [runners.cache.gcs]
		 [runners.cache.azure]
	   [runners.docker]
		 host = "unix:///run/user/975/podman/podman.sock"
		 tls_verify = false
		 image = "docker.io/library/redhat/ubi10:latest"
		 privileged = false
		 disable_entrypoint_overwrite = false
		 oom_kill_disable = false
		 pull_policy = ["if-not-present"]
		 disable_cache = false
		 volumes = ["/var/cache/gitlab-runner/cache:/cache", "/run/user/975/podman/podman.sock:/var/run/podman/podman.sock"]
		 network_mode = "bridge"
		 shm_size = 0
		 network_mtu = 0


### Github Runner ###

Login to github and choose the repository that
self-hosted runner is to be added to.

Goto Settings->Actions->Runners

On the upper right click New self-hosted runner
In this example select Linux x64
Then follow the instructions

It is possbile to install under a specific user id

	sudo useradd -m -c "github runner" github-runner


(what is shown below is be consider an example):
I perfer to install it in /opt

	 # Create a folder
	 sudo mkdir /opt/actions-runner && cd /opt/actions-runner
	 # Download the latest runner package
	 sudo curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz
	 # Optional: Validate the hash
	 echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | shasum -a 256 -c
	 # Extract the installer
	 sudo tar xzf ./actions-runner-linux-x64-2.328.0.tar.gz
	 sudo chown -r github-runner:github-runner /opt/github-runner
	 sudo -u github-runner ./config.sh --unattended --url https://github.com/ebruno/codesamples --token <valid github token> --labels debian13,libvirt
	 sudo ./svc.sh install github-runner
	 Creating launch runner in /etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service
	 Run as user: github-runner
	 Run as uid: 1001
	 gid: 1002
	 Created symlink '/etc/systemd/system/multi-user.target.wants/actions.runner.ebruno-codesamples.shuttle01.service' → '/etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service'
	 sudo ./svc.sh status

	 /etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service
	 ○ actions.runner.ebruno-codesamples.shuttle01.service - GitHub Actions Runner (ebruno-codesamples.shuttle01)
		  Loaded: loaded (/etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service; enabled; preset: enabled)
		  Active: inactive (dead)
	 sudo ./svc.sh start

	 /etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service
	 ● actions.runner.ebruno-codesamples.shuttle01.service - GitHub Actions Runner (ebruno-codesamples.shuttle01)
		  Loaded: loaded (/etc/systemd/system/actions.runner.ebruno-codesamples.shuttle01.service; enabled; preset: enabled)
		  Active: active (running) since Wed 2025-10-08 13:22:03 PDT; 7ms ago
	  Invocation: 2a9c46a0ebc44b5889091759195aad38
		Main PID: 20308 ((unsvc.sh))
		   Tasks: 1 (limit: 154300)
		  Memory: 1.7M (peak: 1.7M)
			 CPU: 4ms
		  CGroup: /system.slice/actions.runner.ebruno-codesamples.shuttle01.service
				  └─20308 "(unsvc.sh)"

	 Oct 08 13:22:03 fqdn current system systemd[1]: Started actions.runner.ebruno-codesamples.shuttle01.service - GitHub Actions Runner (ebruno-codesamples.shuttle01).

Under the runners page the new runner and tags should be displayed.

	Runners
	 shuttle01 self-hosted Linux X64 debian13 libvirt  Idle
