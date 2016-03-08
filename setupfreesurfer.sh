#!/bin/bash
#Updated:	2009-10-01
#
#License:
#Copyright 2009 Alex Schlegel (schlegel@gmail.com).  This work is licensed under
#a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  See
#http://creativecommons.org/licenses/by-nc-sa/3.0/ for more information.

PrintUsage()
{
	echo " Description:	sets up a freesurfer session"
	echo " "
	echo " Usage:	$0"
	echo " "
	echo " Options:"
	echo "	"
	echo " Input:"
	echo "	"
	echo " Assumptions:	assumes mount_vision has already been run"
}

#add path to freesurfer scripts
	#source addpath -s $VISION_DIR/code/fmri/freesurfer

#freesurfer home directory
	#if [ -z $FREESURFER_HOME ]; then
		export FREESURFER_HOME=/home/susanatech/Programs/freesurfer
	#fi

#subject directory
	#if [ -z $SUBJECTS_DIR ]; then
		export SUBJECTS_DIR=$VISION_DIR/Macknik/studies/_fmri_anatomical/_freesurfer
	#fi

#disable fsfast
	export NO_FSFAST=1

#call the configuration script
	source $FREESURFER_HOME/FreeSurferEnv.sh
