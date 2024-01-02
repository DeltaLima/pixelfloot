# pixelfloot

Origin: https://git.la10cy.net/DeltaLima/pixelfloot

an very simple and dirty pixelflut client to draw images, written in bash.
pixelfloot was built during the 37c3. in its actual state, its just a mess. I hope i will find time to put it in a more usable and readable format. 

## image format

you need an uncompress ppm image at first. it is not allowed to be larger then 200px.

convert it like so: `convert lol.jpg -compress none -resize 200x200 lol.ppm`

after you have converted it to ppm, you need to convert it to a "pixel-list". 
do it with `./pixelfloot_bash.sh convertimg lol`

Have a look to the example .pixlist files


## examples

Display image: `./pixelfloot_bash.sh floot lol`

image random position: `./pixelfloot_bash.sh floot images/lucky-cat.jpg chaos`

image shake position: `SHUFMODE=shake ./pixelfloot_bash.sh floot images/lucky-cat.jpg shake`

move image with your cursor (needs `xdotool`): `./pixelfloot_bash.sh floot images/lucky-cat.jpg cursor`

Use a color as "alpha" (remove background): `ALPHACOLOR=FF00FF ./pixelfloot_bash.sh floot images/cursor.ppm cursor`


