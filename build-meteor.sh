#!/bin/sh

#
# Setup
#
if [ $# -lt 2 ]; then
  echo 1>&2 "
You must specify the waw component id. Like:
  ./build-waw.sh sd-waw torrey-pines"
  exit 2
elif [ $# -gt 2 ]; then
  echo 1>&2 "$0: too many arguments.
You should only specify the waw component id. Like:
  ./build-waw.sh sd-waw torrey-pines"
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source_name=$1
waw_id=$2

echo
echo "--------------------------------------------------------------------------------"
echo "Get application source"
echo "--------------------------------------------------------------------------------"
if [ -e ~/Desktop/${source_name} ]
then
  echo "There's already a source file at ~/Desktop/${source_name}."
  echo "So, I'm going to skip this step."
  echo "You'll need to mannually check and see if your local source is up to date and correct."
else
  echo "Downloading source for ${source_name}"
  cd ~/Desktop/ && { git clone https://github.com/scimusmn/${source_name}.git ; cd - ; }
fi

echo
echo "--------------------------------------------------------------------------------"
echo "Get node-webkit"
echo "--------------------------------------------------------------------------------"

node_webkit_domain="http://dl.node-webkit.org"
node_webkit_version="v0.11.2"
node_webkit_name="node-webkit"
node_webkit_os="osx"
node_webkit_arch="x64"

node_webkit_filename=$node_webkit_name-$node_webkit_version-$node_webkit_os-${node_webkit_arch}
node_webkit_zip=${node_webkit_filename}.zip

app_name=c2c

#
# Get the binary if we need to
#
if [ ! -e /tmp/$node_webkit_zip ]
then
  echo "Downloading node-webkit binary."
  nw_url=$node_webkit_domain/$node_webkit_version/$node_webkit_zip
  cd /tmp && { curl -O $nw_url ; cd - ; }
else
  echo "There is already a node-webkit download. We'll use that."
fi

#
# Cleanup old extracts
#
if [ -e /tmp/$node_webkit_filename ]
then
  echo "Removing old node-webkit extract."
  rm -rf /tmp/$node_webkit_filename
fi

#
# Unzip download
#
unzip -q /tmp/$node_webkit_zip -d /tmp/

echo
echo "--------------------------------------------------------------------------------"
echo "Setup node-webkit with our customizations"
echo "--------------------------------------------------------------------------------"

#
# Cleanup old apps and move new one to the desktop
#
if [ -e ~/Desktop/c2c ]
then
  echo "Removing old c2c app."
  rm -rf ~/Desktop/c2c
fi

#
# Create app files and folders.
#
echo "Moving node-webkit to the Desktop and setting it up as c2c.app."

#
# Node webkit config
#
# * Rename the app
# * Remove cruft
# * Tell node-webkit to go fullscreen and focus on localhost:3000 for Meteor
#
mv /tmp/$node_webkit_filename ~/Desktop/$app_name

# Removing a file that doesn't need to be distributed with our app
# Per the node-webkit docs:
# https://github.com/rogerwang/node-webkit/wiki/How-to-package-and-distribute-your-apps#preparing-extra-files
rm -rf ~/Desktop/$app_name/nwsnapshot

mv ~/Desktop/$app_name/node-webkit.app ~/Desktop/$app_name/${app_name}.app

echo "Configure node-webkit with our package.json."
app_nw=~/Desktop/$app_name/${app_name}.app/Contents/Resources/app.nw/
mkdir $app_nw
# TODO This should get some error testing
cp $DIR/assets/nw/package-${waw_id}.json $app_nw/package.json

#
# Delayed startup script
# We use this to wait for Meteor to launch before the node-webkit browser
#
cp $DIR/assets/nw/start-c2c.sh ~/Desktop/$app_name/
chmod +x ~/Desktop/$app_name/start-c2c.sh

#
# Set the application icon
# Credit for most of this icon operation goes to Gregory Vincic on
# Stack Overflow for this solution:
# http://stackoverflow.com/questions/8371790/how-to-set-icon-on-file-or-directory-using-cli-on-os-x/8375093#8375093
#
cp $DIR/assets/logo/nw.icns ~/Desktop/$app_name/${app_name}.app/Contents/Resources/
iconSource=$DIR/assets/logo/nw.icns
iconDestination=~/Desktop/$app_name/${app_name}.app
icon=/tmp/`basename $iconSource`
rsrc=/tmp/icon.rsrc
# Create icon from the iconSource
cp $iconSource $icon
# Add icon to image file, meaning use itself as the icon
# Send noisy output to /dev/null for neatness
sips -i $icon >> /dev/null
# Take that icon and put it into a rsrc file
DeRez -only icns $icon > $rsrc
# Apply the rsrc file to
SetFile -a C $iconDestination
if [ -f $iconDestination ]; then
    # Destination is a file
    Rez -append $rsrc -o $iconDestination
elif [ -d $iconDestination ]; then
    # Destination is a directory
    # Create the magical Icon\r file
    touch $iconDestination/$'Icon\r'
    Rez -append $rsrc -o $iconDestination/Icon?
    SetFile -a V $iconDestination/Icon?
fi

echo
echo "--------------------------------------------------------------------------------"
echo "Setup system startup items"
echo "--------------------------------------------------------------------------------"
# Install LaunchAgents to start everything up when the computer boots
echo "Install LaunchAgents."
cp $DIR/assets/launchd/* ~/Library/LaunchAgents/

echo
echo "--------------------------------------------------------------------------------"
echo "NOTES"
echo "--------------------------------------------------------------------------------"
echo "
There are two manual steps that are required after running this build script.

# Meteor setup
The first time you download a meteor application it needs to be run once
manually with an internet connection, so that it can download and setup the
included 3rd party modules.

Once you've run this build script you should manually start and stop Meteor
using this proceedure:

  1. cd ~/Desktop/${source_name}
  2. meteor
  3. Wait until it says "App running at..."
  4. Press ctrl+c to end the Meteor process.

Meteor should now start up properly when you reboot.

# Meteor settings
Our Meteor apps need some custom configuration, to handle screensavers and
Google Analytics. These values are manually configured in a JSON file:

  1. cd ~/Desktop/${source_name}/config
  2. cp settings.default.json settings.json
  3. Edit settings.json, adding you Google Analytics ID and the home page
     for the appropriate kiosk.

Reboot the machine to test.
"
