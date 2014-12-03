#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Downloading node-webkit"

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
  echo "Downloading node-webkit"
  nw_url=$node_webkit_domain/$node_webkit_version/$node_webkit_zip
  cd /tmp && { curl -O $nw_url ; cd - ; }
else
  echo "node-webkit is already present"
fi


#
# Cleanup old extracts
#
if [ -e /tmp/$node_webkit_filename ]
then
  echo "Removing old node-webkit extract"
  rm -rf /tmp/$node_webkit_filename
fi

#
# Unzip download
#
unzip /tmp/$node_webkit_zip -d /tmp/

#
# Cleanup old apps and move new one to the desktop
#
if [ -e ~/Desktop/c2c ]
then
  echo "Removing old c2c app"
  rm -rf ~/Desktop/c2c
fi

#
# Create app files and folders.
#
echo "Setting up the c2c app"

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

app_nw=~/Desktop/$app_name/${app_name}.app/Contents/Resources/app.nw/
mkdir $app_nw
cp $DIR/assets/nw/package.json $app_nw

#
# Delayed startup script
# We use this to wait for Meteor to launch before the node-webkit browser
#
cp $DIR/assets/nw/start-c2c.sh ~/Desktop/$app_name/
chmod +x ~/Desktop/$app_name/start-c2c.sh

cp $DIR/assets/logo/nw.icns ~/Desktop/$app_name/${app_name}.app/Contents/Resources/


#
# Set the application icon
#
iconSource=$DIR/assets/logo/nw.icns
iconDestination=~/Desktop/$app_name/${app_name}.app
icon=/tmp/`basename $iconSource`
rsrc=/tmp/icon.rsrc

# Create icon from the iconSource
cp $iconSource $icon

# Add icon to image file, meaning use itself as the icon
sips -i $icon

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
