--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--------------------------------------------------------------------------------------

The applications in this folder are for you to test GBC Object Pool prior to purchase.
I've included both a Windows and Mac desktop app.  You can also build and deploy on your device.

About Performace Testing

Please note that the demo provides performance data for both traditional and pooling methods, but it
it does so in a somewhat "sterile" environment. The demo does not take into account "normal" game 
experiences. For example, your game will most likely consist of a game loop, event handlers, 
Runtime events, transitions, physics functions, and anything else that will make your game function. 
These other game events will no doubt impact performance, and this is where object pooling is beneficial.
Creating and destroying game objects while other game events (and some times, other device events 
outside of your game) are occuring will impact performance, and you may experience stutter.  
This is where object pooling is beneficial.

I welcome you to check out my blog and Youtube channel for updates. I plan on providing
updates, articles, and videos around object pooling.
