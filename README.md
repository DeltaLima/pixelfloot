# pixelfloot

Origin: https://git.la10cy.net/DeltaLima/pixelfloot

an very simple and dirty pixelflut client to draw images, written in bash.
pixelfloot was built during the 37c3. in its actual state, its just a mess. I hope i will find time to put it in a more usable and readable format. 

## examples

- Display image: `./pixelfloot_bash.sh floot images/lucky-cat.jpg`
  - set position: `W=1337 H=420 ./pixelfloot_bash.sh floot images/lucky-cat.jpg`
- image random position: `./pixelfloot_bash.sh floot images/lucky-cat.jpg chaos`
  - wider "chaos-radio": `W=1000 H=600 ./pixelfloot_bash.sh floot images/lucky-cat.jpg chaos`
- image shake position: `./pixelfloot_bash.sh floot images/lucky-cat.jpg shake`
  - set the position  : `W=420 H=420 ./pixelfloot_bash.sh floot images/lucky-cat.jpg shake`
- move image with your cursor (needs `xdotool`): `./pixelfloot_bash.sh floot images/lucky-cat.jpg cursor`
- Use a color as "alpha" (remove background): `ALPHACOLOR=FF00FF ./pixelfloot_bash.sh floot images/cursor.ppm cursor`
- write text: `TEXT="pixelflut makes a lot of fun! :)" ./pixelfloot_bash.sh floot text`
  - set the size of the Textbox and the textcolor: `COLOR=FF00FF SIZE=240 TEXT="colors, yeah!" ./pixelfloot_bash.sh floot text`
  - you can also use ALPHACOLOR here, or set your: `ALPHACOLOR=000000 TEXT="colors, yeah!" ./pixelfloot_bash.sh floot text`
  - define your own background color: `BGCOLOR=0000FF SIZE=240 TEXT="colors, yeah!" ./pixelfloot_bash.sh floot text`
- increase No of concurrent connections: `FLOOTFORKS=8 ./pixelfloot_bash.sh floot images/lucky-cat.jpg`
- specify IP and PORT: `IPFLOOT=127.0.0.1 FLOOTPORT=1337 ./pixelfloot_bash.sh floot images/lucky-cat.jpg`

```shell
$ ./pixelfloot_bash.sh help
./pixelfloot_bash.sh [floot|convertimg] [FILENAME|fill|text] ([MODE])
MODE: static (env $H and $W for position)
      chaos (env $H and $W for position range)
      shake (env $H and $W for position range)
      cursor
      bounce (env $Y_MAX and $X_MAX for max bounce range)

available env vars to configure:
RESIZE(int), ALPHACOLOR(hex), FLOOTFORKS(int), H(int), W(int)
SIZE(int), TEXT(string), TEXTSIZE(int), BGCOLOR(hex), COLOR(hex)
X_MAX(int), Y_MAX(int)
IPFLOOT(string), FLOOTPORT(string), USECACHE(bool)
```

Running on my Ryzen 4700G with [wellenbrecher](https://github.com/bits0rcerer/wellenbrecher) 1280x720 and three workers,
i get around 1,5Gbit/s localhost traffic.

![pixelfloot screenshot](demo/screenshot_pixelfloot.png)

## try it out

you can use my pixelflut server [pixelflut.la10cy.net](http://pixelflut.la10cy.net) and watch the board on the homepage, every 5s refreshed or connect by VNC to [pixelflut.la10cy.net:5900](vnc://pixelflut.la10cy.net:5900)
