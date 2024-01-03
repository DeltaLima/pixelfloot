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

declare -a PIXMAP
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
  command -v convert || message error "${YELLOW}convert${ENDCOLOR} not found"
  if [ -n "$RESIZE" ]
  then
    RESIZE="-resize $RESIZE"
    
  fi
  
  while read -r LINE
  do
    echo "PX $LINE"
  done < <(convert $IMGFILE $RESIZE txt:  | tail -n +2  | awk '{print $1 $3}' | sed -e 's/\,/ /' -e 's/\:/ /' -e 's/\#//')
}

sx=0
sy=0
shuf_xy() {
  
	case $SHUFMODE in
	chaos) test -z $H && H=640
        test -z $W && W=480
        echo "OFFSET $(shuf -i 0-$W -n 1) $(shuf -i 0-$H -n 1)"
	;;
	
	shake) test -z $H && H=0
        test -z $W && W=0
        echo "OFFSET $(shuf -i $W-$(($W+10)) -n 1) $(shuf -i $H-$(($H+10)) -n 1)"
	;;
	
	cursor) command -v xdotool || message error "${YELLOW}xdotool${ENDCOLOR} not found"
          echo "OFFSET $(xdotool getmouselocation | tr ':' ' '|awk '{print $2 " " $4}')"
	;;

	static|*) test -z $H && H=0
        test -z $W && W=0
        echo "OFFSET $W $H"
	;;	
	esac
	#
	#
	#echo "OFFSET $(shuf -i 0-1760 -n 1) 919"
	
	#echo > /dev/null
	
	#~ echo "OFFSET $sx $sy"
	#~ sx=$((sx+1))
	#~ sy=$((sy+1))
	
	#~ test $sx -gt 1760 && sx=0
	#~ test $sy -gt 920 && sy=0
}

flootworker()
{
  while true
	do
		#FLOOTSRUNNING=$((FLOOTSRUNNING+1))
    #test $FLOOTSRUNNING -le $FLOOTFORKS && 
    echo "$(shuf_xy)
${LOL[$i]}" > /dev/tcp/$IPFLOOT/$FLOOTPORT || message warn "transmission in worker ${YELLOW}$1${ENDCOLOR} ${RED}failed${ENDCOLOR} - maybe you need to decrease ${YELLOW}FLOOTFORKS${ENDCOLOR} or expand/tune your uplink"
    #FLOOTSRUNNING=$((FLOOTSRUNNING-1))
				#echo "${LOL[$i]}" > /dev/tcp/127.0.0.1/1337 &
				
        #echo "worker $i PID ${LOLPID[$i]}"

	done
}

checkfile() {

   if [ ! -f $1 ]
   then
	   message error "file ${YELLOW}$1${ENDCOLOR} does not exist."
	   exit 1
   fi

}

floot() {
	# small stupid animation, two alternating images
	if [ "$FNAME" == "winketuxS" ]
	then
    message "drawing winketuxS animation"
		LOL[1]="$(cat pixlists/${FNAME}1.pixlist | shuf)"
		LOL[2]="$(cat pixlists/${FNAME}2.pixlist | shuf )"
		LOL[3]="$(cat pixlists/${FNAME}2.pixlist | shuf )"
		#LOL[3]="$(cat $FNAME-mc.pixlist.2 | shuf)"
	elif [ "$FNAME" == "fill" ]
	then
    message "generating color field with ${YELLOW}$FLOOTFORKS${ENDCOLOR} workers"
    LOL_org="$(gen_field)"
		for i in $(seq 1 $FLOOTFORKS)
		do
			LOL[$i]="$LOL_org"
		done
	else
    # generate a tmp file, as i have trouble atm to figure out
    # why free space get lost when i generate the pixlist directly
    # in ram
    if [ $USECACHE ]
    then
	   checkfile $PIXLIST
	   message "using cache from ${YELLOW}$PIXLIST${ENDCOLOR}"
    else
	   checkfile $IMGFILE
	   message "generating tmp file ${YELLOW}$PIXLIST${ENDCOLOR}"
	   convertimg > $PIXLIST
    fi
    message "shuffle pixels from ${YELLOW}$PIXLIST${ENDCOLOR} for ${YELLOW}$FLOOTFORKS${ENDCOLOR} workers"
		for i in $(seq 1 $FLOOTFORKS)
		do
		  #LOL[$i]="OFFSET 1 200"
		  #LOL[$i]="OFFSET $(shuf -i 0-1760 -n 1) $(shuf -i 0-920 -n 1)"
	#	  LOL[$i]="$(shuf_xy)"
		  #LOL[$i]="$(cat $PIXLIST | shuf)"
      
      message "prepare worker ${YELLOW}$i${ENDCOLOR} .."
		
      if [ -z "$ALPHACOLOR" ]
      then 
        LOL[$i]="$(cat $PIXLIST | shuf)"
        #LOL[$i]="$(convertimg | shuf)"
      else
        LOL[$i]="$(grep -v $ALPHACOLOR $PIXLIST | shuf)"
        #LOL[$i]="$(convertimg | grep -v $ALPHACOLOR | shuf)"
      fi
      message "${GREEN}DONE!${ENDCOLOR}"
		done
	fi
	
  message "starting $FLOOTFORKS workers"
  while true
  do
    for i in $(seq $FLOOTFORKS) 
      do
        #echo "check worker $i PID ${LOLPID[$i]} if running "
        if [ -z ${LOLPID[$i]} ] || ! ps -p ${LOLPID[$i]} > /dev/null
        then
          message "worker ${YELLOW}$i${ENDCOLOR} is not running, starting it"
          #if [ "$FLOOTSRUNNING" -le "$FLOOTFORKS" ]
          #then
            flootworker $i &
            LOLPID[$i]=$!
          #fi
          
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
    convertimg > $PIXLIST
    message "file ${YELLOW}$PIXLIST${ENDCOLOR}" generated
	;;
		
	floot) message "flooting ${YELLOW}${IPFLOOT}:${FLOOTPORT}${ENDCOLOR}"
		if [ "$SHUFMODE" == "static" ] && ([ -z "$W" ] && [ -z "$H" ])
         then
           echo "please specify coords with e.g. 'W=420 H=420 SHUFMODE=static $0 floot $FNAME" >&2
           exit 1
         fi
         
         floot
	;;
	*)
		echo "$0 [floot|convertimg] [FILENAME|fill] ([MODE])"
    echo "MODE: static (env \$H and \$W for position)"
    echo "      chaos (env \$H and \$W for position range)"
		echo "      shake (env \$H and \$W for position range)"
    echo "      cursor"
    echo ""
    echo "available env vars to configure:"
    echo "RESIZE(int), ALPHACOLOR(hex), FLOOTFORKS(int), H(int), W(int)"
    echo "IPFLOOT(string), FLOOTPORT(string), USECACHE(bool)"
    exit 1
		;;
	esac
