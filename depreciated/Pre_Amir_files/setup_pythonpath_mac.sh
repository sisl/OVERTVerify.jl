#!/bin/bash

# in order to get bash to change the originating terminal window, run this like:
# source ./my_script
# the source makes it run in the originating process and not a new one

basepath=/Users/Chelsea

export PYTHONPATH=$basepath/Dropbox/AAHAA/src
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/rllab:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/gym:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/RNNs4Marabou:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/OverApprox:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/OverApprox/MarabouMC:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/Marabou:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/Marabou/maraboupy:$PYTHONPATH
export PYTHONPATH=$basepath/Dropbox/AAHAA/src/NNet:$PYTHONPATH
