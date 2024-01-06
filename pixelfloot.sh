#!/bin/bash

# pixelfloot - a pixelflut client written in bash
# this script was made during the 37c3

# pixelflut.la10cy.net - 130.185.104.31
# my small pixelflut test server, feel free to have fun with it! :)
# You can watch the board by VNC at port 5900, max connections are 2
test -z "$IPFLOOT" && IPFLOOT="130.185.104.31"
test -z "$FLOOTPORT" && FLOOTPORT="1234"

########################################################################
FNAME="$(echo $2 | sed -e 's/\..*$//' -e 's/^images\///')"
IMGFILE="$2"
PPMFILE="$FNAME.ppm"
HEXPPM="images/$FNAME.hexppm"
PIXLIST="/tmp/$FNAME.pixlist"
SHUFMODE="$3"

FLOOTSRUNNING=0

test -z "$FLOOTFORKS" && FLOOTFORKS="2"

test -z $X_MAX && X_MAX=800
test -z $Y_MAX && Y_MAX=600
test -z $X && X=0
test -z $Y && Y=0

## bounce
XDIR=0
YDIR=0
test -z "$BOUNCESTEP" && BOUNCESTEP=2
## end bounce

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
FRAMETICK_SHM="/dev/shm/frametick"
## END ANIMATION


## old crap
declare -a PIXMAP
## end old crap

declare -a LOL
declare -a LOLPID


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


######  OLDFOOO ######
# https://gist.github.com/nberlette/e3e303a81f2c41927bf4fe90fb89d97f
function hex() {
    printf "%02X%02X%02X" ${*//','/' '}
}

gen_pixmap() {
	y=0
	while read -r LINE
	do
		if [ "$y" -gt 2 ]
		then
			for x in $(seq 1 $x_ppm)
			do
				REDindex=$((x*3-2))
				GREENindex=$((x*3+1-2))
				BLUEindex=$((x*3+2-2))
				
				REDvalue="$(echo $LINE| cut -d ' ' -f${REDindex})"
				GREENvalue="$(echo $LINE| cut -d ' ' -f${GREENindex})"
				BLUEvalue="$(echo $LINE| cut -d ' ' -f${BLUEindex})"
				
				PIXELcolor="$(hex ${REDvalue} $GREENvalue $BLUEvalue)"
				PIXMAP[$y]="${PIXMAP[$y]} $PIXELcolor"
				
			done
			echo "please wait"
			echo ${PIXMAP[$y]} >> $HEXPPM
		elif [ "$y" -eq 1 ]
			then
			x_ppm="$(echo "$LINE"|cut -d ' ' -f1)"
		fi
		y=$((y+1)) 
		#~ for col in $LINE
		#~ do
			#~ case $count in
			#~ 0) RED="$(hex $col)"
			#~ ;;
			#~ 1) GREEN="$(hex $col)"
			#~ ;;
			#~ 2) BLUE="$(hex $col)"
			#~ ;;
			#~ esac
			#~ count=$((count+1))
			#~ test $count -ge 2 && count=0
		#~ done
	done < "$PPMFILE"
	
}

draw_pixmap() {
	y=1
	test -z $x_ppm && echo "x_ppm missing" && exit 1
	while read -r LINE
	do
		for x in $(seq 1 $x_ppm)
		do
			# when Color is FF00FE draw rainbow background
			if [[ "$(echo $LINE | cut -d ' ' -f$x)" != "FF00FE" ]]
			then
				echo "please wait"
				echo "PX $x $y $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST

				# magnify double size
				#echo "PX $((x*2)) $((y*2)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				#echo "PX $((x*2+1)) $((y*2)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				#echo "PX $((x*2)) $((y*2+1)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				#echo "PX $((x*2+1)) $((y*2+1)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST			
			else
				
				if [ "$y" -lt 32 ]
				then
					RAINBOWCOLOR="$(hex 0 0 255)"
				elif [ "$y" -lt 64 ]
				then
					RAINBOWCOLOR="$(hex 0 255 255)"
				elif [ "$y" -lt 94 ]
				then
					RAINBOWCOLOR="$(hex 0 255 0)"
				elif [ "$y" -lt 126 ]
				then
					RAINBOWCOLOR="$(hex 255 255 0)"
				else
					RAINBOWCOLOR="$(hex 255 0 0)"
				
				fi
				
				 
								
				#~ if [ "$y" -lt 16 ]
				#~ then
					#~ RAINBOWCOLOR="$(hex 0 0 $(((y+1)*16)))"
				#~ elif [ "$y" -lt 32 ]
				#~ then
					#~ RAINBOWCOLOR="$(hex 0 $(((y-16)*16)) 255)"
				#~ elif [ "$y" -lt 48 ]
				#~ then
					#~ RAINBOWCOLOR="$(hex 0 $((y*16)) $((16-(y-32)*16)))"
				#~ elif [ "$y" -lt 64 ]
				#~ then
					#~ RAINBOWCOLOR="$(hex $((y*16)) $((y*16)) 0)"
				#~ else
					#~ RAINBOWCOLOR="$(hex $((y*16)) 0 0)"
				
				#~ fi
			    
			
				echo "please wait for rainbow"
				echo "PX $((x*2)) $((y*2)) $RAINBOWCOLOR" >> $PIXLIST
				echo "PX $((x*2+1)) $((y*2)) $RAINBOWCOLOR" >> $PIXLIST
				echo "PX $((x*2)) $((y*2+1)) $RAINBOWCOLOR" >> $PIXLIST
				echo "PX $((x*2+1)) $((y*2+1)) $RAINBOWCOLOR" >> $PIXLIST			
			fi
		done
		y=$((y+1)) 

	done < "$HEXPPM"
	
}


###### END OLDFOOO ######


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
  
  if [ -n "$RESIZE" ]
  then
    RESIZE="-resize $RESIZE"
    
  fi
  
  convert $IMGFILE $BORDER $RESIZE txt:  | tail -n +2  | awk '{print $1 $3}' | sed -e 's/\,/ /' -e 's/\:/ /' -e 's/\#//' -e 's/^/PX /'
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
  while true
  do
    echo lol
    exit 1
  done
  
}

flootworker()
{  
  while true
	do
    if [ $LARGE ] 
    then
      xymode
      echo "$OFFSET"
      for i in $(seq 0 $1 | shuf)
      do
        echo "${LOL[$i]}"     
      done
    else
      xymode
      echo "$OFFSET
${LOL[$1]}"
    fi
	done > /dev/tcp/$IPFLOOT/$FLOOTPORT || message warn "transmission in worker ${YELLOW}$1${ENDCOLOR} ${RED}failed${ENDCOLOR} - maybe you need to decrease ${YELLOW}FLOOTFORKS${ENDCOLOR} or expand/tune your uplink"
}

checkfile() {

   if [ ! -f $1 ] || [ -z $1 ] 
   then
	   message error "file ${YELLOW}$1${ENDCOLOR} does not exist."
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
    message "LARGE mode: slicing ${YELLOW}${IMGFILE}${ENDCOLOR} - ${YELLOW}${LINES}${ENDCOLOR} into ${YELLOW}${LOLFIELDS}${ENDCOLOR} fields"
    
    i=0
    while [ $i -le $LOLFIELDS ]
    do
            LN=$(($L+$LOLFIELDSIZE+1))
            message "field ${YELLOW}${i}${ENDCOLOR}, lines ${YELLOW}${L}${ENDCOLOR} - ${YELLOW}${LN}${ENDCOLOR}"
            LOL[$i]="$(echo "$LOL_org" | sed -n "${L},$(($LN-1))p;${LN}q" )"
            L=$LN
            
            i=$(($i+1))
    done
    
   else
    for i in $(seq 1 $FLOOTFORKS)
      do
        if [ -z "$ALPHACOLOR" ]
        then 
          message "shuffle pixels for worker ${YELLOW}${i}${ENDCOLOR}"
          LOL[$i]="$(echo "$LOL_org" | shuf)"
        else
          message "remove aplha color ${YELLOW}${ALPHACOLOR}${ENDCOLOR} and shuffle pixels for worker ${YELLOW}${i}${ENDCOLOR}"
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
  
  case $FNAME in
  # small stupid animation, two alternating images
  winketuxS) 
    message "drawing winketuxS animation"
		LOL[1]="$(cat pixlists/${FNAME}1.pixlist | shuf)"
		LOL[2]="$(cat pixlists/${FNAME}2.pixlist | shuf )"
		LOL[3]="$(cat pixlists/${FNAME}2.pixlist | shuf )"
		#LOL[3]="$(cat $FNAME-mc.pixlist.2 | shuf)"
  ;;
  
  fill)
    message "generating color field with ${YELLOW}$FLOOTFORKS${ENDCOLOR} workers"
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
    message "generating text, size $FONTSIZE for ${YELLOW}$FLOOTFORKS${ENDCOLOR} workers"
    message "TEXT: ${YELLOW}${TEXT}${ENDCOLOR}"
    LOL_org="$(convert ${SIZE} ${BORDER} +antialias -depth 8 -fill \#${COLOR}  -background \#${BGCOLOR} -pointsize ${FONTSIZE} caption:"${TEXT}" -quality 72  txt: | tail -n +2  | awk '{print $1 $3}' | sed -e 's/\,/ /' -e 's/\:/ /' -e 's/\#//' -e 's/^/PX /')"
    
    loadLOL
  ;;
  
  *)
    # generate a tmp file, as i have trouble atm to figure out
    # why free space get lost when i generate the pixlist directly
    # in ram
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
      
    message "prepare worker ${YELLOW}$i${ENDCOLOR} .."
    #set -x 
    loadLOL
    #set +x 
    message "${GREEN}DONE!${ENDCOLOR}"
  ;;
  esac
	
  
  if [ $ANIMATION ]
  then
    frametick &
  fi
  
  
  message "starting ${YELLOW}${FLOOTFORKS}${ENDCOLOR} workers"
  
  while true
  do
    for i in $(seq $FLOOTFORKS) 
      do
        #echo "check worker $i PID ${LOLPID[$i]} if running "
        if [ -z ${LOLPID[$i]} ] || ! ps -p ${LOLPID[$i]} > /dev/null
        then
          message "worker ${YELLOW}$i${ENDCOLOR} is not running, starting it"
            if [ $LARGE ] || [ $ANIMATION ]
            then
              flootworker $LOLFIELDS &
              LOLPID[$i]=$!
            else
              flootworker $i &
              LOLPID[$i]=$!
            fi          
        fi
    done
  done

}

case $1 in

### DEPRECATED - JUST FOR TESTING
	draw_pixmap) draw_pixmap
	;;
	
	gen_pixmap) gen_pixmap
	;;
### END DEPRECATED - JUST FOR TESTING

	convertimg)
    # old way
		##gen_pixmap
		##draw_pixmap
    
    # convert arbeitsplatz.jpg txt: | tail -n +2  | awk '{print $1 $3}'
    # this is probably better
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
          message error "${YELLOW}xdotool${ENDCOLOR} not found" 
          exit 1
          fi
          ;;
         *)
          
          ;;
        esac
        
        if ! command -v convert > /dev/null
        then
          message error "${YELLOW}convert${ENDCOLOR} not found"
          exit 1
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
    
    exit 1
		;;
	esac
