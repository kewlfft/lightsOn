#!/bin/bash
# lightsOn.sh

# Copyright (c) 2011 iye.cba at gmail com
# url: https://github.com/iye/lightsOn
# This script is licensed under GNU GPL version 2.0 or above

# Description: Bash script that prevents the screensaver and display power
# management (DPMS) to be activated when you are watching Flash Videos
# fullscreen on Firefox and Chromium.
# Can detect mplayer and VLC when they are fullscreen too but I have disabled
# this by default.
# lightsOn.sh needs xscreensaver or kscreensaver to work.

# HOW TO USE: Start the script with the number of seconds you want the checks
# for fullscreen to be done. Example:
# "./lightsOn.sh 120 &" will Check every 120 seconds if Mplayer,
# VLC, Firefox or Chromium are fullscreen and delay screensaver and Power Management if so.
# You want the number of seconds to be ~10 seconds less than the time it takes
# your screensaver or Power Management to activate.
# If you don't pass an argument, the checks are done every 50 seconds.


# Modify these variables if you want this script to detect if Mplayer,
# VLC or Firefox Flash Video are Fullscreen and disable
# xscreensaver/kscreensaver and PowerManagement.
mplayer_detection=0
vlc_detection=0
firefox_flash_detection=1
chromium_flash_detection=1


# YOU SHOULD NOT NEED TO MODIFY ANYTHING BELOW THIS LINE


# enumerate all the attached screens
displays=""
while read id
do
    displays="$displays $id"
done< <(xvinfo | sed -n 's/^screen #\([0-9]\+\)$/\1/p')

# Detect screensaver been used (xscreensaver, kscreensaver or none)
screensaver=`pgrep -l xscreensaver | grep -wc xscreensaver`
if [ $screensaver -ge 1 ]; then
    screensaver=xscreensaver
else
    screensaver=`pgrep -l kscreensaver | grep -wc kscreensaver`
    if [ $screensaver -ge 1 ]; then
        screensaver=kscreensaver
    else
        screensaver=None
        echo "No screensaver detected" 
    fi       
fi


checkFullscreen()
{
    # loop through every display looking for a fullscreen window
    for display in $displays
    do
        #get id of active window and clean output
        activ_win_id=`DISPLAY=:0.${display} xprop -root _NET_ACTIVE_WINDOW`
        activ_win_id=${activ_win_id#*# }
        # Skip invalid window ids
        if [ "$activ_win_id" = "0x0" ]; then
             continue
        fi
        # Check if Active Window (the foremost window) is in fullscreen state
        isActivWinFullscreen=`DISPLAY=:0.${display} xprop -id $activ_win_id | grep _NET_WM_STATE_FULLSCREEN`
            if [[ "$isActivWinFullscreen" = *NET_WM_STATE_FULLSCREEN* ]];then
                isAppRunning
                var=$?
                if [[ $var -eq 1 ]];then
                    delayScreensaver
                fi
            fi
    done
}



    

# check if active windows is mplayer, vlc or firefox
#TODO only window name in the variable activ_win_id, not whole line. 
#Then change IFs to detect more specifically the apps "<vlc>" and if process name exist

isAppRunning()
{    
    #Get title of active window
    activ_win_title=`xprop -id $activ_win_id | grep "WM_CLASS(STRING)"`   # I used WM_NAME(STRING) before, WM_CLASS more accurate.



    # Check if user want to detect Video fullscreen on Firefox, modify variable firefox_flash_detection if you dont want Firefox detection
    if [ $firefox_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *unknown* || "$activ_win_title" = *plugin-container* ]];then
        # Check if plugin-container process is running
            flash_process=`pgrep -l plugin-containe | grep -wc plugin-containe`
            #(why was I using this line avobe? delete if pgrep -lc works ok)
            #flash_process=`pgrep -lc plugin-containe`
            if [[ $flash_process -ge 1 ]];then
                return 1
            fi
        fi
    fi

    
    # Check if user want to detect Video fullscreen on Chromium, modify variable chromium_flash_detection if you dont want Chromium detection
    if [ $chromium_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *exe* ]];then   
        # Check if Chromium Flash process is running
            flash_process=`pgrep -lfc "chromium-browser --type=plugin --plugin-path=/usr/lib/adobe-flashplugin"`
            if [[ $flash_process -ge 1 ]];then
                return 1
            fi
        fi
    fi

    
    #check if user want to detect mplayer fullscreen, modify variable mplayer_detection
    if [ $mplayer_detection == 1 ];then  
        if [[ "$activ_win_title" = *mplayer* || "$activ_win_title" = *MPlayer* ]];then
            #check if mplayer is running.
            #mplayer_process=`pgrep -l mplayer | grep -wc mplayer`
            mplayer_process=`pgrep -lc mplayer`
            if [ $mplayer_process -ge 1 ]; then
                return 1
            fi
        fi
    fi
    
    
    # Check if user want to detect vlc fullscreen, modify variable vlc_detection
    if [ $vlc_detection == 1 ];then  
        if [[ "$activ_win_title" = *vlc* ]];then
            #check if vlc is running.
            #vlc_process=`pgrep -l vlc | grep -wc vlc`
            vlc_process=`pgrep -lc vlc`
            if [ $vlc_process -ge 1 ]; then
                return 1
            fi
        fi
    fi    
    

return 0
}


delayScreensaver()
{

    # reset inactivity time counter so screensaver is not started
    if [ "$screensaver" == "xscreensaver" ]; then
    	xscreensaver-command -deactivate > /dev/null
    elif [ "$screensaver" == "kscreensaver" ]; then
    	qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    fi


    #Check if DPMS is on. If it is, deactivate and reactivate again. If it is not, do nothing.    
    dpmsStatus=`xset -q | grep -ce 'DPMS is Enabled'`
    if [ $dpmsStatus == 1 ];then
        	xset -dpms
        	xset dpms
	fi
	
}



delay=$1


# If argument empty, use 50 seconds as default.
if [ -z "$1" ];then
    delay=50
fi


# If argument is not integer quit.
if [[ $1 = *[^0-9]* ]]; then
    echo "The Argument \"$1\" is not valid, not an integer"
    echo "Please use the time in seconds you want the checks to repeat."
    echo "You want it to be ~10 seconds less than the time it takes your screensaver or DPMS to activate"
    exit 1
fi


while true
do
    checkFullscreen
    sleep $delay
done


exit 0    
