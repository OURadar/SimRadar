#!/bin/bash
np=100
radarsim -vvv -p ${np} -W 1000 > test_wx.txt
radarsim -vvv -p ${np} -W 1000 -d 20000 > test_wxdb.txt
