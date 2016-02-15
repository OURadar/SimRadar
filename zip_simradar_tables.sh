#!/bin/bash

echo "Compression files ..."
zip -r tables.zip tables -x *.DS_Store -x .\* -x */_\*

echo "Uploading zip archive ..."
scp -p tables.zip rwv01.arrc.nor.ou.edu:~/public_html/simradar/
