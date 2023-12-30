#!/bin/bash

IPFLOOT="151.217.15.90"
COLOR="FFFFFF"
PPMFILE="$2.ppm"
HEXPPM="$2.hexppm"
PIXLIST="$2.pixlist"
ALPHACOLOR="$3"
FNAME="$2"

declare -a PIXMAP
declare -a LOL
declare -a LOLPID

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

gen_field() {

for i in  $(seq 0 160) 
	do
	for j in $(seq 180 330)
	do
		echo "PX $i $j $COLOR"
	done
done

}

draw_pixmap() {
	y=1
	while read -r LINE
	do
		for x in $(seq 1 200)
		do
			if [[ "$(echo $LINE | cut -d ' ' -f$x)" != "FF00FE" ]]
			then
				echo "please wait"
				echo "PX $((x*2)) $((y*2)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				echo "PX $((x*2+1)) $((y*2)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				echo "PX $((x*2)) $((y*2+1)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST
				echo "PX $((x*2+1)) $((y*2+1)) $(echo $LINE | cut -d ' ' -f$x)" >> $PIXLIST			
			else
				
				if [ "$y" -lt 40 ]
				then
					RAINBOWCOLOR="$(hex 0 0 255)"
				elif [ "$y" -lt 80 ]
				then
					RAINBOWCOLOR="$(hex 0 255 255)"
				elif [ "$y" -lt 120 ]
				then
					RAINBOWCOLOR="$(hex 0 255 0)"
				elif [ "$y" -lt 160 ]
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

sx=0
sy=0
shuf_xy() {
	#echo "OFFSET $(shuf -i 0-1760 -n 1) $(shuf -i 0-919 -n 1)"
	#echo "OFFSET $(shuf -i 0-1760 -n 1) 919"
	echo "OFFSET 1200 420"
	#echo > /dev/null
	
	#~ echo "OFFSET $sx $sy"
	#~ sx=$((sx+1))
	#~ sy=$((sy+1))
	
	#~ test $sx -gt 1760 && sx=0
	#~ test $sy -gt 920 && sy=0
}

floot() {
	#~ for i in 1 2
	#~ do
	  #LOL[$i]="OFFSET 1 200"
	  #LOL[$i]="OFFSET $(shuf -i 0-1760 -n 1) $(shuf -i 0-920 -n 1)"
#	  LOL[$i]="$(shuf_xy)"
	  #~ LOL[$i]="$(shuf_xy)
#~ $(cat $PIXLIST | shuf)"
	
	#~ if [ -z "$ALPHACOLOR" ]
	#~ then 
		#~ LOL[$i]="$(cat $PIXLIST | shuf)"
	#~ else
		#~ LOL[$i]="$(grep -v $ALPHACOLOR $PIXLIST | shuf)"
	#~ fi
	
	#~ done
	
	LOL[1]="$(cat ${FNAME}1.pixlist | shuf)"
	LOL[2]="$(cat ${FNAME}2.pixlist | shuf )"
	#LOL[3]="$(cat $FNAME-mc.pixlist.2 | shuf)"
	
	while true
	do
		for i in 1 2
		do
			if [ -z ${LOLPID[$i]} ] || ! ps -p ${LOLPID[$i]} > /dev/null
			then
				echo "$(shuf_xy)
${LOL[$i]}" > /dev/tcp/$IPFLOOT/1337 &
				#echo "${LOL[$i]}" > /dev/tcp/127.0.0.1/1337 &
				LOLPID[$i]=$!
			fi
		done
	done
}

case $1 in

	draw_pixmap) draw_pixmap
	;;
	
	gen_pixmap) gen_pixmap
	;;
	
	floot) floot
	;;
	*)
		echo "lol: draw_pixmap, gen_pixmap, floot"
		exit 1
		;;
	esac
