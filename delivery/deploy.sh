#!/bin/bash

app_name="SimRadar"


cmd="${app_name}.app/Contents/MacOS/${app_name} -v"
version=`eval $cmd`
version=${version%% (*}

sub_folder=`echo ${app_name} | tr '[:upper:]' '[:lower:]'`

echo
echo "Deploying SimRadar $version ..."
echo

echo "Adding a gatekeeper rule ...";
sudo spctl -a -v ${app_name}.app

echo "Mounting disk image...";
open ${app_name}.dmg
sleep 1;
while [ ! -d "/Volumes/${app_name}" ]; do
	echo "Waiting for disk image...";
	sleep 1;
done

echo "Code sign with Developer ID Application ...";
codesign --deep -f -s "Developer ID Application" ${app_name}.app

echo "Updating app...";
rsync -a --delete ${app_name}.app /Volumes/${app_name}/

echo "Unmounting volume...";
umount /Volumes/${app_name}

echo "Archiving application...";
zip -qr ${app_name}.zip ${app_name}.app

echo "Signing applicaiton archive.";
cmd="ruby sign_update.rb ${app_name}.zip dsa_priv.pem"
key=`eval $cmd`
echo $key

echo "Generating AppCast feed...";
curr_date=`date -u`
key=${key//\//\\/}
key=${key//+/\\+}
echo $key
file_size=`ls -l ${app_name}.zip | awk '{ print $5 }'`
sed -e s/_APP_NAME_/"$app_name"/g -e s/_SUB_FOLDER_/"$sub_folder"/g -e s/_PUB_DATE_/"$curr_date"/g -e s/_VERSION_/"$version"/g -e s/_DSA_KEY_/"$key"/g -e s/_FILE_SIZE_/"$file_size"/g versions_template.xml > versions.xml
#cat versions.xml

echo "Uploading files to the ARRC server...";
rsync -av ${app_name}.dmg ${app_name}.zip versions.* rayleigh:~/public_html/${sub_folder}/

