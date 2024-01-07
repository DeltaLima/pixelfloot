# pixelfloot

Origin: https://git.la10cy.net/DeltaLima/pixelfloot

an very simple and dirty pixelflut client to draw images, written in bash.
pixelfloot was built during the 37c3. in its actual state, its just a mess. I hope i will find time to put it in a more usable and readable format. 

## examples

- Display image: `./pixelfloot.sh floot images/lucky-cat.jpg`
  - set position: `X=1337 Y=420 ./pixelfloot.sh floot images/lucky-cat.jpg`
- image random position: `./pixelfloot.sh floot images/lucky-cat.jpg chaos`
  - wider "chaos-radio": `X_MAX=1000 Y_MAX=600 ./pixelfloot.sh floot images/lucky-cat.jpg chaos`
- image shake position: `./pixelfloot.sh floot images/lucky-cat.jpg shake`
  - set the position  : `X=420 Y=420 ./pixelfloot.sh floot images/lucky-cat.jpg shake`
- image bounce across screen: `./pixelfloot.sh floot images/lucky-cat.jpg bounce`
  - can set the "bounce-radius": `X_MAX=1000 Y_MAX=500 ./pixelfloot.sh floot images/lucky-cat.jpg bounce`
- move image with your cursor (needs `xdotool`): `./pixelfloot.sh floot images/lucky-cat.jpg cursor`
- Use a color as "alpha" (remove background): `ALPHACOLOR=FF00FF ./pixelfloot.sh floot images/cursor.ppm cursor`
- write text: `TEXT="pixelflut makes a lot of fun! :)" ./pixelfloot.sh floot text`
  - set the size of the Textbox and the textcolor: `COLOR=FF00FF SIZE=240 TEXT="colors, yeah!" ./pixelfloot.sh floot text`
  - you can also use ALPHACOLOR here, or set your: `ALPHACOLOR=000000 TEXT="colors, yeah!" ./pixelfloot.sh floot text`
  - define your own background color: `BGCOLOR=0000FF SIZE=240 TEXT="colors, yeah!" ./pixelfloot.sh floot text`
- increase No of concurrent connections: `FLOOTFORKS=8 ./pixelfloot.sh floot images/lucky-cat.jpg`
- specify IP and PORT: `IPFLOOT=127.0.0.1 FLOOTPORT=1337 ./pixelfloot.sh floot images/lucky-cat.jpg`
- for drawing big areas, like 1280x720, use LARGE mode: `LARGE=true ./pixelfloot.sh floot images/xphg.jpg`
  - default field size are 64k lines. You can adjust it with LOLFIELDSIZE:
    `LOLFIELDSIZE=16000 LARGE=true ./pixelfloot.sh floot images/xphg.jpg`
- drawing an gif file with proper animation: `ANIMATION=true ./pixelfloot.sh floot images/dancing_banana.gif`
  - Adjust the speed with FRAMETICKTIME in seconds: `FRAMETICKTIME=0.03 ANIMATION=true ./pixelfloot.sh floot images/shaking_cat.gif`
- with THROTTLE you can adjust your transfer speed: `THROTTLE=4M ANIMATION=true ./pixelfloot.sh floot images/Animated-GIFs-davidope-11.gif`
  - you can use K, M, G as suffix.
- view the network io of the worker with PIPEVIEW: `PIPEVIEW=true ANIMATION=true ./pixelfloot.sh floot images/Tesseract2.gif`

## tuning

You can play around with some env vars to optimize your throughput. Most 
obvious one is FLOOTFORKS whichs defines how many worker fors are 
spawning / tcp sessions you use. Default is 1.

When using more then one worker, it also worth to have a look to
SYNCFLOOTWORKER. This env var (bool) defines if all worker calculate 
their own OFFSET or use all the same from `[worker 1]`.

You can use PIPEVIEW to see how much bandwith a worker uses. With
THROTTLE you can limit the bandwith. Value given in bytes, you can use 
K, M, G as suffix.


```shell
$ ./pixelfloot.sh help
./pixelfloot.sh [floot|convertimg] [FILENAME|fill|text] ([MODE])

floot: flooting the target specified with IPFLOOT
convertimg: converts an image to a command list file in /tmp
            to use it, start 'USECACHE=true ./pixelfloot.sh floot [FILENAME]', where FILENAME
            is the original image file.

FILENAME: path to any picture imagemagick can handle (env X, Y, RESIZE, 
          BORDERCOLOR, ALPHACOLOR)
fill: create a filled area with (env COLOR, W (width), H (height), X, Y)
text: create a textbox (env TEXT, FONTSIZE, SIZE, COLOR, BGCOLOR, BORDERCOLOR
      ALPHACOLOR)

MODE: static (env X and Y for position)
      chaos (env X_MAX and Y_MAX for position range)
      shake (env X and Y for position)
      cursor
      bounce (env Y_MAX and X_MAX for max bounce range, BOUNCESTEP for step size)

available env vars to configure:
IPFLOOT(string), FLOOTPORT(int), USECACHE(bool), FLOOTFORKS(int)
SIZE(int), TEXT(string), FONTSIZE(int), BGCOLOR(hex), COLOR(hex)
BORDERCOLOR(hex), X(int), Y(int), X_MAX(int), Y_MAX(int), H(int), W(int)
RESIZE(int), ALPHACOLOR(hex), BOUNCESTEP(int), LARGE(bool), LOLFIELDSIZE(int)
ANIMATION(bool), FRAMETICKTIME(float), SYNCFLOOTWORKER(bool), THROTTLE(string)
PIPEVIEW(bool), VERBOSE(bool)
```

Running on my Ryzen 4700G with [wellenbrecher](https://github.com/bits0rcerer/wellenbrecher) 1280x720 and three workers,
i get around 1,5Gbit/s localhost traffic.

![pixelfloot screenshot](demo/screenshot_pixelfloot.png)

## try it out

you can use my pixelflut server [pixelflut.la10cy.net](http://pixelflut.la10cy.net) and watch the board on the homepage, every 5s refreshed or connect by VNC to [pixelflut.la10cy.net:5900](vnc://pixelflut.la10cy.net:5900)
