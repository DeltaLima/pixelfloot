#!/bin/bash

# pixelfloot - a pixelflut client written in bash
# work on this script started at 37c3

# pixelflut.la10cy.net - 130.185.104.31
# my small pixelflut test server, feel free to have fun with it! :)
# You can watch the board by VNC at port 5900, max connections are 2
test -z "$IPFLOOT" && IPFLOOT="130.185.104.31"
test -z "$FLOOTPORT" && FLOOTPORT="1234"

########################################################################
IMGFILE="$2"
# remove file extension 
FNAME="${2%.*}"
# remove everything before the slash, so we get the filename without
# path and extension
FNAME="${FNAME##*/}"
PIXLIST="/tmp/$FNAME.pixlist"
ANIFILE="/tmp/$FNAME"
SHUFMODE="$3"

FLOOTSRUNNING=0

test -z "$FLOOTFORKS" && FLOOTFORKS="1"

test -z $X_MAX && X_MAX=800
test -z $Y_MAX && Y_MAX=600
test -z $X && X=0
test -z $Y && Y=0

## bounce
XDIR=0
YDIR=0
test -z "$BOUNCESTEP" && BOUNCESTEP=2
## end bounce

OFFSET_SHM="/dev/shm/pxlflt-offset-${FNAME}"

## ANIMATION
# convert -coalesce animation.gif target.png -> produces target1.png, target2.png, ..
# /dev/shm/foo to store frame counter
# 
# GifFileFormat - gif, jpg, png  || detect which fileformat IMGFILE is
#test -z "$ANIMATION" && ANIMATION="false"
# 
# loadLOL loads every single frame into an array field WHEN ANIMATION is true
# loadLOL sets No of frames in LOLFIELDS
#
# flootworker looks in while loop which value in /dev/shm/frametick is.
# /dev/shm/frametick contains which frame from LOL to draw.
# function frametick() gets started in background when ANIMATION is true
# and gets started before the flootworker get started
# frametick writes the no of frame to draw into /dev/shm/frametick
# to not draw too fast, there is a sleep in frametick which waits for
# FRAMETICKTIME seconds. Values are float, down to lowest value 0.001
# Only one of ANIMATION or LARGE can be true, not both.
FRAMETOPICK_SHM="/dev/shm/pxlflt-frametopick-${FNAME}"
## END ANIMATION

declare -a LOL
declare -a LOLPID

## TODOS
# 
# DONE - Put OFFSET into /dev/shm/ so each worker do not have to count OFFSET
#   for itself and we prevent worker from drifting apart when drawing. 
# - get dimensions of pic with "identify" (imagemagick part)
# - get dimensions of the pixelflut board 


# colors for colored output 8)
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

function message() {
     case $1 in
     warn)
       MESSAGE_TYPE="${YELLOW}WARN${ENDCOLOR}"
     ;;
     error)
       MESSAGE_TYPE="${RED}ERROR${ENDCOLOR}"
     ;;
     info|*)
       MESSAGE_TYPE="${GREEN}INFO${ENDCOLOR}"
     ;;
     esac

     if [ "$1" == "info" ] || [ "$1" == "warn" ] || [ "$1" == "error" ]
     then
       MESSAGE=$2
     else
       MESSAGE=$1
     fi

     echo -e "[${MESSAGE_TYPE}] $MESSAGE"
}

error () 
{
  message error "${RED}ERROR!!${ENDCOLOR}"
  exit 1
}

gen_field() {

test -z $W && W=640
test -z $H && H=480
test -z $COLOR && COLOR="666999"
message "drawing ${YELLOW}$W x $H - $COLOR${ENDCOLOR}" >&2
for x in  $(seq 0 $W) 
	do
	for y in $(seq 0 $H)
	do
		echo "PX $x $y $COLOR"
	done
done

}


convertimg() {
  if [ -z "$1" ] 
  then
    CONVERTFILE="$IMGFILE"
  else
    CONVERTFILE="$1"
  fi
  
  convert $CONVERTFILE $BORDER $RESIZE txt:  | tail -n +2  | awk '{print $1 $3}' | sed -e 's/\,/ /' -e 's/\:/ /' -e 's/\#//' -e 's/^/PX /'
}


xymode() {
	case $SHUFMODE in
	chaos) OFFSET="OFFSET $(shuf -i 0-$X_MAX -n 1) $(shuf -i 0-$Y_MAX -n 1)"
	;;
	
	shake) OFFSET="OFFSET $(shuf -i $X-$(($X+10)) -n 1) $(shuf -i $Y-$(($Y+10)) -n 1)"
	;;
	
	cursor) OFFSET="OFFSET $(xdotool getmouselocation | tr ':' ' '|awk '{print $2 " " $4}')"
	;;
  
  bounce)       
        # every call is a run in a loop
        # in every run we count x or y alternativ one up or down
        # we decide with with var 'xory', 0 is x , 1 is y
        # up or down ist set with 'xdir' and 'ydir'
        # 0 means up, 1 means down
        # 
        # handled outsite, in the flootworker()

        
        if [ $XDIR == 0 ]
          then
            X=$(($X+$BOUNCESTEP))
            test $X -ge $X_MAX && XDIR=1
          else
            X=$(($X-$BOUNCESTEP))
            test $X -eq 0 && XDIR=0
        fi
        
        if [ $YDIR == 0 ]
          then
            Y=$(($Y+$BOUNCESTEP))
            test $Y -ge $Y_MAX && YDIR=1
          else
            Y=$(($Y-$BOUNCESTEP))
            test $Y -eq 0 && YDIR=0
        fi
        OFFSET="OFFSET $X $Y"
  ;;

	static|*) test -z $X && X=0
        test -z $Y && Y=0
        OFFSET="OFFSET $X $Y"
	;;	
	esac

}

frametick() {
  test -z "$FRAMETICKTIME" && FRAMETICKTIME=0.1
  #LOLFIELDS=12
  i=0
  while true
  do
    if [ "$i" -lt $LOLFIELDS ]
    then
      echo "$i"  > $FRAMETOPICK_SHM
      i=$(($i+1))
    else
      i=0
    fi
    sleep $FRAMETICKTIME
  done
  
}

pipectrl() {

  
  if [ $THROTTLE ]
  then
    pv $(test -z $PIPEVIEW && echo "-q") -c -N "[worker ${iFLOOTWORKER}]" -L "$THROTTLE" || return 1
  else
    if [ $PIPEVIEW ]
    then
      pv -c -N "[worker ${iFLOOTWORKER}]" || return 1
    else
      cat - || return 1
    fi
  fi
  
}

flootworker()
{  
  if [ $ANIMATION ] && [ $iFLOOTWORKER -gt 1 ]
  then
    message "[worker ${YELLOW}$iFLOOTWORKER${ENDCOLOR}] shuffle pixels again to maximize coverage" >&2
    i=0
    while  [ $i -lt $LOLFIELDS ]
    do
      LOL[$i]="$(echo "${LOL[$i]}" | shuf)"
      i=$(($i+1))
    done
    message "[worker ${YELLOW}$iFLOOTWORKER${ENDCOLOR}] shuffle ${GREEN}done${ENDCOLOR}" >&2
  fi
  
  while true
	do
    # set offset
    if [ $SYNCFLOOTWORKER ]
    then
      if [ $iFLOOTWORKER == 1 ]
      then
        xymode
        echo "$OFFSET" | tee $OFFSET_SHM
        
      else
        
        test -f $OFFSET_SHM && OFFSET="$(<${OFFSET_SHM})"
        # little hack, otherwise on fast machines with small images we
        # get an empty string back. 
        while [ "$(echo $OFFSET | wc -c )" -lt 10 ]
        do
          test $VERBOSE && message warn "[worker ${YELLOW}$iFLOOTWORKER${ENDCOLOR}] [${RED}VERBOSE${ENDCOLOR}] TOO FAST, cannot fetch OFFSET! I got '${YELLOW}${OFFSET}${ENDCOLOR}' from ${YELLOW}${OFFSET_SHM}${ENDCOLOR}" >&2
          OFFSET="$(<${OFFSET_SHM})"
        done

        echo "$OFFSET"
        
      fi

    else
      xymode
      echo "$OFFSET"
    fi
    
    if [ $LARGE ] 
    then
      for i in $(seq 0 $1 | shuf)
      do
        echo "${LOL[$i]}"     
      done
    elif [ $ANIMATION ]
    then

      echo "${LOL[$(< ${FRAMETOPICK_SHM})]}"

    else
      echo "${LOL[$1]}"
    fi
	done | pipectrl >  /dev/tcp/$IPFLOOT/$FLOOTPORT || message warn "[worker ${YELLOW}${iFLOOTWORKER}${ENDCOLOR}] transmission ${RED}failed${ENDCOLOR} - maybe you need to decrease ${YELLOW}FLOOTFORKS${ENDCOLOR} or expand/tune your uplink"
  #~ echo  "${LOL[$(< ${FRAMETOPICK_SHM})]}" > /dev/shm/lol123_${i}
  #~ echo  "${OFFSET}" > /dev/shm/lol123.offset_${i}
  #~ read
}

checkfile() {

   if [ ! -f $1 ] || [ -z $1 ] || [ -d $1 ]
   then
	   message error "file ${YELLOW}$1${ENDCOLOR} is not a valid file or does not exist."
	   exit 1
   fi

}

loadLOL() {
   
  # when LARGE true, then we slize the large pixlist into smaller pieces
  # max 64k each one
  if [ $LARGE ] 
  then
    LOL_org="$(echo "$LOL_org" | shuf)"
    test -z "$LOLFIELDSIZE" && LOLFIELDSIZE=64000
    # line counter
    L=1    
    LINES="$(echo "$LOL_org" | wc -l )"
    LOLFIELDS="$(( ( $LINES / $LOLFIELDSIZE ) ))"
    message "LARGE mode: slicing ${YELLOW}${IMGFILE}${ENDCOLOR} - ${YELLOW}${LINES}${ENDCOLOR} into ${YELLOW}$((${LOLFIELDS}+1))${ENDCOLOR} fields"
    
    i=0
    while [ $i -le $LOLFIELDS ]
    do
      LN=$(($L+$LOLFIELDSIZE+1))
      message "field ${YELLOW}${i}/${LOLFIELDS}${ENDCOLOR}, lines ${YELLOW}${L}${ENDCOLOR} - ${YELLOW}${LN}${ENDCOLOR}"
      LOL[$i]="$(echo "$LOL_org" | sed -n "${L},$(($LN-1))p;${LN}q" )"
      L=$LN
      
      i=$(($i+1))
    done
  
  elif [ $ANIMATION ]
  then
    
    i=0
    while  [ $i -lt $LOLFIELDS ]
    do
      if [ -z "$ALPHACOLOR" ]
      then
        message "load and shuffle pixels for frame ${YELLOW}$((${i}+1))/${LOLFIELDS}${ENDCOLOR}"
        LOL[$i]="$(convertimg ${ANIFILE}-${i}.png | shuf)"
      else
        message "load and shuffle pixels for frame ${YELLOW}$((${i}+1))/${LOLFIELDS}${ENDCOLOR}, remove aplha color ${YELLOW}${ALPHACOLOR}${ENDCOLOR}"
        LOL[$i]="$(convertimg ${ANIFILE}-${i}.png | grep -v $ALPHACOLOR | shuf)"
      fi

      #echo "${LOL[$i]}" | head
      i=$(($i+1))
    done
    # ani
    #~ echo ani ani
    #~ exit 1
    
  else
    for i in $(seq 1 $FLOOTFORKS)
      do
        if [ -z "$ALPHACOLOR" ]
        then 
          message "shuffle pixels for [worker ${YELLOW}${i}${ENDCOLOR}]"
          LOL[$i]="$(echo "$LOL_org" | shuf)"
        else
          message "remove aplha color ${YELLOW}${ALPHACOLOR}${ENDCOLOR} and shuffle pixels for [worker ${YELLOW}${i}${ENDCOLOR}]"
          LOL[$i]="$(echo "$LOL_org" | grep -v $ALPHACOLOR | shuf)"
        fi
      done 
      
  fi

}

floot() {
  if [ -n "$BORDERCOLOR" ]
  then
    BORDER="-bordercolor #${BORDERCOLOR} -border 2x2"
  else
    BORDER=""
  fi
  if [ -n "$RESIZE" ]
  then
    message "resizing to ${YELLOW}${RESIZE}px${ENDCOLOR}"
    RESIZE="-resize $RESIZE"
  fi
  
  case $FNAME in
  fill)
    message "generating color field with ${YELLOW}${FLOOTFORKS}${ENDCOLOR} worker"
    LOL_org="$(gen_field)"
		loadLOL
  ;;
  
  ""|text)
    test -z "$TEXT" && TEXT="$0"
    test -z "$FONTSIZE" && FONTSIZE=42
    test -z "$COLOR" && COLOR="000000"
    test -z "$BGCOLOR" && BGCOLOR="FFFFFF"
    
    if [ -n "$SIZE" ]
    then
      SIZE="-size $SIZE"
    
    fi
    

    #convert -fill lightgreen  -background white -pointsize 40 caption:"KARTTUR" -quality 72  DstImage.png
    message "generating text, size $FONTSIZE for ${YELLOW}$FLOOTFORKS${ENDCOLOR} worker"
    message "TEXT: ${YELLOW}${TEXT}${ENDCOLOR}"
    LOL_org="$(convert ${SIZE} ${BORDER} +antialias -depth 8 -fill \#${COLOR}  -background \#${BGCOLOR} -pointsize ${FONTSIZE} caption:"${TEXT}" -quality 72  txt: | tail -n +2  | awk '{print $1 $3}' | sed -e 's/\,/ /' -e 's/\:/ /' -e 's/\#//' -e 's/^/PX /')"
    
    loadLOL
  ;;
  
  *)
    
    if [ $ANIMATION ]
    then
      checkfile $IMGFILE
      message "ANIMATION mode, checking if ${YELLOW}${IMGFILE}${ENDCOLOR} is an GIF"
      if [ "$(file $IMGFILE |awk '{print $2}')" == "GIF" ]
      then
        LOLFIELDS="$(identify $IMGFILE | wc -l )"
        message "splitting ${YELLOW}${IMGFILE}${ENDCOLOR} up into ${YELLOW}${LOLFIELDS}${ENDCOLOR} frame images"
        convert -coalesce $IMGFILE ${ANIFILE}.png || error
      else
        message error "Other filetypes then ${YELLOW}GIF${ENDCOLOR} are not supported at the moment for ${YELLOW}ANIMATION${ENDCOLOR}"
        exit 1
      fi
    else 
      if [ $USECACHE ]
      then
       checkfile $PIXLIST
       message "using cache from ${YELLOW}$PIXLIST${ENDCOLOR}"
       LOL_org="$(< $PIXLIST)"
      else
       checkfile $IMGFILE
       message "convertimg image file ${YELLOW}${IMGFILE}${ENDCOLOR}"
       LOL_org="$(convertimg)"
       #convertimg > $PIXLIST
      fi
    fi
    message "prepare worker .."
    #set -x 
    loadLOL
    #set +x 
    message "${GREEN}Done!${ENDCOLOR}"
  ;;
  esac
	
  
  if [ $ANIMATION ]
  then
    frametick &
  fi
  
  
  message "starting ${YELLOW}${FLOOTFORKS}${ENDCOLOR} worker"
  if [ -n "$SYNCFLOOTWORKER" ] && [ $FLOOTFORKS -gt 1 ]
  then
    message "SYNCFLOOTWORKER is enabled, all worker use OFFSET from [worker ${YELLOW}1${ENDCOLOR}]"
  fi
  
  while true
  do
    for iFLOOTWORKER in $(seq $FLOOTFORKS) 
      do
        if [ -z ${LOLPID[$iFLOOTWORKER]} ] || ! ps -p ${LOLPID[$iFLOOTWORKER]} > /dev/null
        then
          message "[worker ${YELLOW}$iFLOOTWORKER${ENDCOLOR}] not running, starting it"
            if [ $LARGE ] || [ $ANIMATION ]
            then
              flootworker $LOLFIELDS &
              LOLPID[$iFLOOTWORKER]=$!              
            else
              flootworker $iFLOOTWORKER &
              LOLPID[$iFLOOTWORKER]=$!
            fi
          message "[worker ${YELLOW}$iFLOOTWORKER${ENDCOLOR}] PID ${YELLOW}${LOLPID[$iFLOOTWORKER]}${ENDCOLOR} ${GREEN}started${ENDCOLOR}"
        fi
    done
  done

}

case $1 in

	convertimg)
    checkfile $IMGFILE
    message "generating pixlist cachefile from ${YELLOW}${IMGFILE}${ENDCOLOR}"
    convertimg > $PIXLIST
    message "file ${YELLOW}${PIXLIST}${ENDCOLOR} generated, you can use it with ${GREEN}USECACHE=true $0 floot ${IMGFILE}${YELLOW}"
	;;
		
	floot) message "flooting ${YELLOW}${IPFLOOT}:${FLOOTPORT}${ENDCOLOR}"

         ##~ WIP - get the size of the board from server
         #~ message "request board size from ${YELLOW}${IPFLOOT}:${FLOOTPORT}${ENDCOLOR}"
         #~ exec 5<>/dev/tcp/$IPFLOOT/$FLOOTPORT
         #~ echo "SIZE" >&5
         #~ #sleep 1
         #~ BOARDSIZE="$(cat <&5)" &
         #~ cat <&5 &
         #~ sleep 1
         
         #~ exec 5<&-
         #~ message "$BOARSIZE"
         ##~ END WIP
         
         case $SHUFMODE in 
         cursor)
          if ! command -v xdotool > /dev/null
          then
          message error "command ${YELLOW}xdotool${ENDCOLOR} not found" 
          exit 1
          fi
          ;;
         *)
          
          ;;
        esac
        
        for imgmgckCMD in convert identify
        do
          if ! command -v $imgmgckCMD > /dev/null
          then
            message error "imagemagick command ${YELLOW}${imgmgckCMD}${ENDCOLOR} not found"
            exit 1
          fi
        done
        
        if [ $PIPEVIEW ] || [ $THROTTLE ]
        then
          if ! command -v pv > /dev/null
          then
            message error "command ${YELLOW}pv${ENDCOLOR} not found"
            exit 1
          fi
        fi
        if [ $LARGE ] && [ $ANIMATION ]
        then
          message error "${YELLOW}LARGE${ENDCOLOR} and ${YELLOW}ANIMATION${ENDCOLOR} cannot be used at the same time. Please use only one of them."
          exit 1
        fi
        
        message "all requirements satisfied ${GREEN}:)${ENDCOLOR}"
        floot
	;;
	*)
		echo "$0 [floot|convertimg] [FILENAME|fill|text] ([MODE])"
    echo ""
    echo "floot: flooting the target specified with IPFLOOT"
    echo "convertimg: converts an image to a command list file in /tmp"
    echo "            to use it, start 'USECACHE=true $0 floot [FILENAME]', where FILENAME"
    echo "            is the original image file."
    echo ""
    echo "FILENAME: path to any picture imagemagick can handle (env X, Y, RESIZE, "
    echo "          BORDERCOLOR, ALPHACOLOR)"
    echo "fill: create a filled area with (env COLOR, W (width), H (height), X, Y)"
    echo "text: create a textbox (env TEXT, FONTSIZE, SIZE, COLOR, BGCOLOR, BORDERCOLOR"
    echo "      ALPHACOLOR)"
    echo ""
    echo "MODE: static (env X and Y for position)"
    echo "      chaos (env X_MAX and Y_MAX for position range)"
		echo "      shake (env X and Y for position)"
    echo "      cursor"
    echo "      bounce (env Y_MAX and X_MAX for max bounce range, BOUNCESTEP for step size)"
    echo ""
    echo "available env vars to configure:"
    echo "IPFLOOT(string), FLOOTPORT(int), USECACHE(bool), FLOOTFORKS(int)"
    echo "SIZE(int), TEXT(string), FONTSIZE(int), BGCOLOR(hex), COLOR(hex)"
    echo "BORDERCOLOR(hex), X(int), Y(int), X_MAX(int), Y_MAX(int), H(int), W(int)"
    echo "RESIZE(int), ALPHACOLOR(hex), BOUNCESTEP(int), LARGE(bool), LOLFIELDSIZE(int)"
    echo "ANIMATION(bool), FRAMETICKTIME(float), SYNCFLOOTWORKER(bool), THROTTLE(string)"
    echo "PIPEVIEW(bool), VERBOSE(bool)"
    
    exit 1
		;;
	esac
