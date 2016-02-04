#/bin/bash

#started with info from
# source iterm2.zsh
# iTerm2 window/tab color commands
#   Requires iTerm2 >= Build 1.0.0.20110804
#   http://code.google.com/p/iterm2/wiki/ProprietaryEscapeCodes

#Written by Matt Pippitt to change iTerm2 look and feel from the command line

#variables
#annoying block to look where the script is, then set that directory to search for presets and colors
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
RDIR="$( dirname "$SOURCE" )"
ITPDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
#end annoying block

#Set variables, look in ~ first then $ITPDIR
#TODO maybe set something if neither exist to change the script behavior, like not show menu options
if [ -f ~/itp_presets ] ; then
  PRESETSFILE=~/itp_presets
elif [ -f $ITPDIR/itp_presets ] ; then
  PRESETSFILE=$ITPDIR/itp_presets
else
  PRESETSFILE=notset
fi

if [ -f ~/itp_colors.list ] ; then
  COLORSFILE=~/itp_colors.list
elif [ -f $ITPDIR/itp_colors.list ] ; then
  COLORSFILE=$ITPDIR/itp_colors.list
else
  COLORSFILE=notset
fi

showhelp() {
    echo "Usage: $0 [OPTION(S)]"
    echo "Options: "
    echo "  -P [preset name]"
    echo "  -p [profile name]"
    echo "  -t [colon separate RGB values] i.e 255:0:0 for red"
    echo "  -R yes   Will reset profile and tab color to defaults "
}

tab-color() {
    echo -ne "\033]6;1;bg;red;brightness;$1\a"
    echo -ne "\033]6;1;bg;green;brightness;$2\a"
    echo -ne "\033]6;1;bg;blue;brightness;$3\a"
}

tab-color-picker() {
  clear
  echo -n "**** Tab Colors *****
0.  From file list
1.  Red
2.  Orange
3.  Yellow
4.  Green
5.  Blue
6.  Indigo
7.  Violet
8.  White
9.  Custom
x.  Exit

Enter selection or x to quit:  "
  RETURN=$1
  read answer
  case $answer in
    0)
        #fancy nested list from file
        tab-color-from-nested-file
        ;;
    1)
        #red
        tab-color 255 0 0
        ;;
    2)
        #orange
        tab-color 255 165 0
        ;;
    3)
        #yellow
        tab-color 255 255 0
        ;;
    4)
        #green
        tab-color 0 128 0
        ;;
    5)
        #blue
        tab-color 0 0 255
        ;;
    6)
        #indigo
        tab-color 75 0 130
        ;;
    7)
        #violet
        tab-color 238 130 238
        ;;
    8)
        #white
        tab-color 255 255 255
        ;;
    9)
        echo See http://en.wikipedia.org/wiki/Web_colors#X11_color_names
        echo -n "Amount Red 0-255:"
        read RED
        echo -n "Amount Green 0-255:"
        read GREEN
        echo -n "Amount Blue 0-255:"
        read BLUE
        tab-color $RED $GREEN $BLUE
        ;;
    x|q|X|Q)
        exit
        ;;
    *)
        echo "easy tiger, exiting"
        exit
        ;;
    esac
 
}

tab-color-from-nested-file() {
  if [ -s $COLORSFILE ] ; then
    Number=0
    clear
    echo "**** Defined Color Groups *****"
    declare -a CGARRAY=(`grep colors$ $COLORSFILE | awk '{print $1}'|tr '\n' ' '`);
    for CG in `echo ${CGARRAY[@]}` ; do
      echo $Number. $CG
      Number=`expr $Number + 1`
    done
    LASTCHOICE=`expr $Number - 1`
    echo -n  "x. Exit

Enter selection or x to quit:  "
    read answer
    echo 0-$LASTCHOICE
    case $answer in
       #for now there can only be 100 color groups
      [0-9]|[0-9][0-9])
          if [ "$answer" -gt "$LASTCHOICE" ] ; then
              echo "Not a valid choice, should be between 0 and $LASTCHOICE"
              read junk
          fi
          COLORGROUP=${CGARRAY[$answer]}
          ;;
      x|q|X|Q)
          exit
          ;;
      *)
          echo "Not a valid choice, should be between 0 and $LASTCHOICE, exiting"
          exit
          ;;
      esac
#now we have the group get the color list in that group
    Number=0
    clear
    echo "**** Defined $COLORGROUP colors *****"
    declare -a CGARRAY=(`sed -e '/./{H;$!d;}' -e 'x;/'${COLORGROUP}' colors/!d' $COLORSFILE |grep :|awk '{print $1}'|tr '\n' ' '`);
    for PRESET in `echo ${CGARRAY[@]}` ; do
      echo $Number. $PRESET
      Number=`expr $Number + 1`
    done
    LASTCHOICE=`expr $Number - 1`
    echo -n  "x. Exit

Enter selection or x to quit:  "
    read answer
    echo 0-$LASTCHOICE
    case $answer in
       #for now there can only be 100 presets
      [0-9]|[0-9][0-9])
          if [ "$answer" -gt "$LASTCHOICE" ] ; then
              echo "Not a valid choice, should be between 0 and $LASTCHOICE"
              read junk
          fi
          COLOR=${CGARRAY[$answer]}
          TC=`grep -w ^$COLOR $COLORSFILE|awk '{print $2}'|tr ':' ' '`
          tab-color $TC
          if [ ! -z "$ECHOCMD" ] ; then
              echo COMMAND NOTES:
              echo $ECHOCMD
              read junk
          fi
          echo "For faster tab color run:"
          echo `basename $0` -t `echo $TC|tr ' ' ':'`
          read junk
          ;;
      x|q|X|Q)
          exit
          ;;
      *)
          echo "Not a valid choice, should be between 0 and $LASTCHOICE, exiting"
          exit
          ;;
      esac
 
   else
      echo "No presets defined check $COLORSFILE"
      read junk
   fi
}

tab-reset() {
    echo -ne "\033]6;1;bg;*;default\a"
}
 
presets() {
  if [ -s $PRESETSFILE ] ; then
    Number=0
    clear
    echo "**** Defined Presets *****"
    declare -a PRESETARRAY=(`awk -F, '{print $1}' $PRESETSFILE|grep -v ^# |tr '\n' ' '`);
    for PRESET in `echo ${PRESETARRAY[@]}` ; do
      echo $Number. $PRESET
      Number=`expr $Number + 1`
    done
    LASTCHOICE=`expr $Number - 1`
    echo -n  "x. Exit

Enter selection or x to quit:  "
    read answer
    echo 0-$LASTCHOICE
    case $answer in
       #for now there can only be 100 presets
      [0-9]|[0-9][0-9])
          if [ "$answer" -gt "$LASTCHOICE" ] ; then
              echo "Not a valid choice, should be between 0 and $LASTCHOICE"
              read junk
          fi
          PRESET=${PRESETARRAY[$answer]}
          TC=`grep ^$PRESET $PRESETSFILE|awk -F, '{print $2}'|tr ':' ' '`
          PROFILE=`grep ^$PRESET $PRESETSFILE|awk -F, '{print $3}'`
          ECHOCMD=`grep ^$PRESET $PRESETSFILE|awk -F, '{print $4}'`
          tab-color $TC
          profiles $PROFILE
          if [ ! -z "$ECHOCMD" ] ; then
              echo COMMAND NOTES:
              echo $ECHOCMD
              read junk
          fi
          echo "For faster preset run:"
          echo `basename $0` -P $PRESET
          read junk
          ;;
      x|q|X|Q)
          exit
          ;;
      *)
          echo "Not a valid choice, should be between 0 and $LASTCHOICE, exiting"
          exit
          ;;
      esac
   else
      echo "No presets defined check $PRESETSFILE"
      read junk
   fi
}

profiles() {
    echo -ne "\033]50;SetProfile=$1\a"
#default
#    echo -ne "\033]50;SetProfile\a"
  
}

profile-picker() {
  clear
  Number=0
  declare -a PROFARRAY=(`plutil -p ~/Library/Preferences/com.googlecode.iterm2.plist  |grep \"Name\"|awk '{print $3}'|tr -d '\n'|sed s/\"/\ /g`);
  echo "**** Select Profile *****"
for PROFILE in `echo ${PROFARRAY[@]}` ; do
  echo $Number. $PROFILE
  Number=`expr $Number + 1`
done
  echo -n  "x. Exit

Enter selection or x to quit:  "
  read answer
  case $answer in
    [0-9])
        profiles ${PROFARRAY[$answer]}
        ;;
    x|q|X|Q)
        exit
        ;;
    *)
        echo "easy tiger, exiting"
        exit
        ;;
    esac
}

##############################################################
#menu
menu() {
  while  true  ; do
    clear
    #pippitt
    echo -n "**** Iterm settings menu *****
1. Presets
2. Profiles
3. Tab colors
4. Tab reset
x. Exit

Enter selection or x to quit:  "
    RETURN=$1
    read answer
    case $answer in
      1)
        presets
        ;;
      2)
        profile-picker
        ;;
      3)
        tab-color-picker
        ;;
      4)
        tab-reset
        ;;
      x|q|X|Q)
        exit
        ;;
      *)
        echo "Not a valid choice, exiting"
        exit
        ;;
      esac
  done
}

while getopts ":P:p:t:R:" opt; do
    case $opt in
        P)
            if [ -s $PRESETSFILE ] ; then
                PRESET=$OPTARG
                #verify preset exists
                if grep -q ^$PRESET, $PRESETSFILE ; then
                    TC=`grep ^$PRESET, $PRESETSFILE|awk -F, '{print $2}'|tr ':' ' '`
                    PROFILE=`grep ^$PRESET, $PRESETSFILE|awk -F, '{print $3}'`
                    ECHOCMD=`grep ^$PRESET, $PRESETSFILE|awk -F, '{print $4}'`
                    tab-color $TC
                    profiles $PROFILE
                    if [ ! -z "$ECHOCMD" ] ; then
                        echo COMMAND NOTES:
                        echo $ECHOCMD
                        read junk
                    fi
                else
                    echo "Preset $PRESET not found in $PRESETSFILE"
                    echo -n "Current presets are: "
                    grep -v ^# $PRESETSFILE |awk -F, '{printf"%s ", $1}'
                    echo
                fi
             else
                 echo "No presets defined, check $PRESETSFILE"
                 read junk
             fi
          ;;
        p)
          #should error check
          PROFILE=$OPTARG
          profiles $PROFILE
          ;;
        t)
          TABCOLOR=$OPTARG
          tab-color `echo $TABCOLOR|tr ':' ' '`
          ;;
        R)
          #RESET
          tab-reset
          echo -ne "\033]50;SetProfile\a"
          exit
          ;;
        h|\?|*)
          showhelp
          exit 1
          ;;
    esac
done

if [ -z "$PRESET" ] && [ -z "$PROFILE" ] && [ -z "$TABCOLOR" ] && [ -z "$RESET" ] ; then
    menu
fi
