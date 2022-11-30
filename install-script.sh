#!/bin/bash
#                     _      _____  ______
#   ___  ___  ___ ___| | /| / / _ \/_  __/
#  / _ \/ _ \/ -_) _ \ |/ |/ / , _/ / /   
#  \___/ .__/\__/_//_/__/|__/_/|_| /_/    
#     /_/                             
#                                      
# OpenWRT build script for ASUS RT-N12+ by & for chickendrop89
# it jus works

# Build Configuration
wrt_branch="openwrt-22.03"

# Patch/Bugfix version ex. 22.03.2 <-
wrt_patch_ver="2"

# Must be an absolute path! ex. /home/example/(wrt-dir)
wrt_directory="$HOME/$wrt_branch"

# End of Build Configuration



# (C)olorful echo command with time
cecho() {
   echo -e "${colorPurple} [$(date "+%H:%M:%S")]: $1 ${colorNone}" 
};

# (W)arning echo command
wecho() {
   echo -e "${colorRed} (!) $1 ${colorNone}"
};

if [ "$(id -u)" -eq 0 ]; then
  wecho "Running as root is not allowed!" >&2; exit;
fi;

# Throw error if binaries (used in this script) are missing
if ! [[ -x "$(command -v make)" && -x "$(command -v git)" && -x "$(command -v wget)" && -x "$(command -v sed)" ]]; then
  wecho "Essential build utilities missing! install required dependencies first" >&2;
  wecho "https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem"
  exit;
fi;

if ! [ -x "$(command -v tftp)" ]; then
  wecho "[Optional] TFTP client is not installed, it is required for flashing the image!"
fi;

colorNone="\033[0m"
colorRed="\033[1;31m"
colorPurple="\033[1;35m"

ethConnectionName=$(nmcli -g name connection show | head -1)
ethInterface=$(ip -br l | awk '$1 !~ "lo|vir|wl" {print $1}')

# Trap SIGINT signal to exit process on CTRL-C
trap "exit 0" SIGINT



# Show a prompt if firmware image already exists, if not -> go ahead and build
function BuildExistsPrompt() {
  if [ $(ls ${wrt_directory}/bin/targets/ramips/mt7620/*.bin 2> /dev/null | wc -l) != "0" ]; 
   then
     if [[ "$(read -e -p 'Built Firmware image already exists, do you want to flash it? (y, n)'; echo $REPLY)" == [Yy]* ]]; then
      flashFirmware
     else 
      BuildOpenWRT; 
     fi;
   else 
    BuildOpenWRT 
  fi;
};



function BuildOpenWRT() {                

  # Ping 8.8.8.8 to check internet connection before building
  if ! [ : >/dev/tcp/8.8.8.8/53 ]; then
    wecho "You need Internet connection to build! Quitting" >&2; exit;
  fi;

  # Clone the desired branch  
  cecho "Cloning ${wrt_branch} branch into ${wrt_directory}"
  git clone https://www.github.com/openwrt/openwrt ${wrt_directory} --depth 1 -b ${wrt_branch}

  # Change directory to $wrt_dire..
  cd ${wrt_directory}

  # Git-pull latest sources/commits
  cecho "Git pull-ing new sources"
  git pull

  # Stop if error occurs
  set -e

  # Download official config & feeds
  cecho "Downloading Official configs & feeds"
  wget https://downloads.openwrt.org/releases/${wrt_branch#*openwrt-}.${wrt_patch_ver}/targets/ramips/mt7620/feeds.buildinfo -nv -O feeds.conf.default
  wget https://downloads.openwrt.org/releases/${wrt_branch#*openwrt-}.${wrt_patch_ver}/targets/ramips/mt7620/config.buildinfo -nv -O .config

  # Disable 'Multi-Profile / All-Profiles' and change target to ASUS RT-N12+
  cecho "Changing target to ASUS RT-N12+"
  sed -i "s/CONFIG_TARGET_MULTI_PROFILE=y/CONFIG_TARGET_ramips_mt7620_DEVICE_asus_rt-n12p=y/g" .config
  sed -i "s/CONFIG_TARGET_ALL_PROFILES=y/CONFIG_TARGET_ALL_PROFILES=n/g" .config

  # Update feeds
  cecho "Updating feeds"
  ./scripts/feeds update -a

  # Install all packages
  cecho "Installing all feeds/packages"
  ./scripts/feeds install -a

  # Run nconfig to make changes .config file
  cecho "Running 'make nconfig'"
  make nconfig

  # Will produce a general configuration of the build system
  cecho "Running 'make defconfig'"
  make defconfig

  # Make diffconfig with changes
  cecho "Creating a diffconfig with your changes"
  ./scripts/diffconfig.sh > diffconfig

  # Download dependency source files & resources
  cecho "Downloading dependency source files"
  make download V=s

  # Track time and cecho it at the end of building
  SECONDS=0

  cecho "BUILDING FIRMWARE IMAGE"
  make clean world -j$(nproc) V=s || wecho "Failed building firmware!"
  cecho "Build Ended in $((SECONDS/60)) minute/s and $((SECONDS%60)) seconds"
};



function flashFirmware() {
 
  # One liner if/then to save space
  if ! [ -x "$(command -v tftp)" ];  then wecho "ERROR: TFTP client is not installed" >&2; exit; fi;
  if ! [ -x "$(command -v nmcli)" ]; then wecho "ERROR: NetworkManager is not installed (nmcli is missing)" >&2; exit; fi;

  function networkManagerEthError(){ 
    wecho "Failed! is there a ethernet interface? Quitting" >&2; 
  };

  function restoreInternetAccess(){
    cecho "Attempting to restore Internet access on the ${ethInterface} interface"
   
    # Remove the old IP address and bounce connection
    function nmcliRemoveAndBounce(){
      nmcli con mod "${ethConnectionName}" -ipv4.addresses "192.168.1.75/24"
      nmcli con down "${ethConnectionName}" && nmcli con up "${ethConnectionName}"
    }
    
    nmcliRemoveAndBounce 1> /dev/null || wecho "Failed! You might want to try it manually" >&2;
  };

  function printAndConnect() {

    # Trap exit signal to execute 'restoreInternetAccess' function
    trap restoreInternetAccess EXIT

    cecho "Success! Connecting to router via TFTP (192.168.1.1)"
    cecho "https://openwrt.org/docs/guide-user/installation/generic.flashing.tftp"

    tftp 192.168.1.1  
  };

  cecho "Changing IP address to 192.168.1.75/24 through NetworkManager"
  nmcli dev mod ${ethInterface} ipv4.method manual ipv4.addr "192.168.1.75/24" ipv4.gateway "192.168.1.1" > /dev/null && printAndConnect || networkManagerEthError
};

BuildExistsPrompt
