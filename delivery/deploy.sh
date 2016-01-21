#!/bin/bash

APP_NAME=SimRadar

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${APP_NAME}.app/Contents/Info.plist)
VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${APP_NAME}.app/Contents/Info.plist)
echo
echo "Deploying as version ${VERSION} ..."
echo


echo "Adding a gatekeeper rule ...";
sudo spctl -a -v ${APP_NAME}.app

if [ ! -f "${APP_NAME}.rw.dmg" ]; then
	size=$(du -hs ${APP_NAME}.app)
	size=${size%%M*}
    size=$(echo "${size} * 2" | bc)
	echo "Creating image of size ${size} MB ..."
    hdiutil create -megabytes ${size} -fs HFS+J -volname ${APP_NAME} -attach ${APP_NAME}.rw.dmg
else
    echo "Mounting disk image ${APP_NAME}.rw.dmg ...";
    hdiutil mount ${APP_NAME}.rw.dmg
fi

while [ ! -d "/Volumes/${APP_NAME}" ]; do
	echo "Waiting for disk image...";
	sleep 1;
done


ln -s /Applications /Volume/${APP_NAME}/Applications

#echo "Code sign with Developer ID Application ...";
#codesign -f -s "Developer ID Application" ${APP_NAME}.app

echo "Updating app ...";
rsync -a --delete ${APP_NAME}.app /Volumes/${APP_NAME}/

echo "Detaching volume...";
hdiutil detach /Volumes/${APP_NAME}
while [ -d "/Volumes/${APP_NAME}" ]; do
	echo "Detaching volume...";
	sleep 1;
done

echo "Converting disk image to a read-only version ..."
if [ -f "${APP_NAME}.dmg" ]; then
	rm ${APP_NAME}.dmg
fi
hdiutil convert ${APP_NAME}.rw.dmg -format UDRO -o ${APP_NAME}.dmg

echo "Archiving application...";
zip -qr ${APP_NAME}.zip ${APP_NAME}.app

echo "Signing applicaiton archive.";
KEY=`ruby sign_update.rb ${APP_NAME}.zip dsa_priv.pem`
echo ${KEY}

echo "Generating AppCast feed...";
TODAY=$(date -u)
FILE_SIZE=$(du -s ${APP_NAME}.app)
FILE_SIZE=${FILE_SIZE%%${APP_NAME}*}
FILE_SIZE=$((FILE_SIZE*512))
# '/' --> '\/' character
KEY=${KEY//\//\\/}
KEY=${KEY//+/\\+}
echo "TODAY=${TODAY}"
echo "KEY=${KEY}"
echo "FILE_SIZE=${FILE_SIZE}"
sed -e s/_APP_NAME_/"${APP_NAME}"/g -e s/_VERSION_/"${VERSION}"/g -e s/_VERSIONSTRING_/"${VERSION_STRING}"/g -e s/_PUB_DATE_/"${TODAY}"/g -e s/_DSA_KEY_/"${KEY}"/g -e s/_FILE_SIZE_/"${FILE_SIZE}"/g versions_template.xml > versions.xml
#cat versions.xml

echo "Uploading files to the ARRC server..."
#rsync -e 'ssh -p 20004' -av ${APP_NAME}.dmg ${APP_NAME}.zip versions.* localhost:~/public_html/${APP_NAME}/
rsync -av ${APP_NAME}.dmg ${APP_NAME}.zip versions.* rwv01.arrc.nor.ou.edu:~/public_html/${APP_NAME}/
