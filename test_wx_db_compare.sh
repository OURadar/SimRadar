#!/bin/bash
np=500
# Weather only
radarsim -vvv -p ${np} > test_sp_wx.txt
# Weather + Debris
radarsim -vvv -p ${np} -d 20000 > test_sp_wxdb.txt
# Debris only
radarsim -vvv -c T -p ${np} -d 20000 > test_sp_db.txt

