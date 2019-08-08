#!/bin/bash
np=500
# Weather only
simradar -vvv -p ${np} > test_sp_wx.txt
# Weather + Debris
simradar -vvv -p ${np} -d 20000 > test_sp_wxdb.txt
# Debris only
simradar -vvv -c T -p ${np} -d 20000 > test_sp_db.txt

