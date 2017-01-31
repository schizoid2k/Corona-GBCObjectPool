--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene demonstrates the use of spritesheets with GBC Object Pool
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local GBCObjectPool = require "plugin.GBCObjectPool"
local widget = require "widget"

local explosionPool             -- id of explosion pool
local imageSheet                -- explosion image sheet
local touchScreen               -- invisible rect that handles touch input
local sndExplode                -- explosion sound effect
local titleText, infoText       -- title and info
local btnBack                   -- button to return

-- screen shortcuts
local Screen = {
    Top = display.screenOriginY,
    Left = display.screenOriginX,  
    Right = display.viewableContentWidth + math.abs(display.screenOriginX),
    Bottom = display.viewableContentHeight + math.abs(display.screenOriginY),        
    Width = math.floor(display.actualContentWidth + 0.5),
    Height = math.floor(display.actualContentHeight + 0.5),
    CenterX = display.contentCenterX,
    CenterY = display.contentCenterY,
}

-- explosion parameters
local ExplosionOptions = {
    width = 64,
    height = 64,
    numFrames = 48,
    sheetContentWidth = 512,
    sheetContentHeight = 384,
}

-- explosion sequence parameters
local ExplosionSequence = {
    name = "explosion",
    start = 1,
    count = 48,
    time = 1000,
    loopCount = 1,
    loopDirection = "forward",
}

-- back button event handler
local function onButtonPress(event)
    if event.target.id == "back" then composer.gotoScene("top") end    
end

-- This fuction is required by GBC Object Pool
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
local function CreateExplosion()
    local explosion = display.newSprite(imageSheet, ExplosionSequence)
    explosion:setSequence("explosion")
    return explosion
end

-- Function will grab an unused explosion object from the pool,
-- plays it, and then returns it to the pool.
local function onScreenTouch(event)
    -- Executes when the explosion animation is complete.
    -- Notice, we remove the event listener we created to watch for completion.
    -- This could be added in the CreateExplosion() function if you wish. 
    local function spriteListener(event)
        if event.phase == "ended" then
            event.target:removeEventListener("sprite", spriteListener)
            GBCObjectPool.put(explosionPool, event.target)
        end
    end
    
    -- Get an explosion object from the pool, check if one was returned,
    -- and play it.
    
    local explosion = GBCObjectPool.get(explosionPool)
    
    if explosion then
        explosion.x = event.x
        explosion.y = event.y
        explosion:addEventListener("sprite", spriteListener)
        explosion:play()
        audio.play(sndExplode)
    end
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    
    touchScreen = display.newRect(sceneGroup, Screen.CenterX, Screen.CenterY, Screen.Width, Screen.Height)
    touchScreen.isVisible = false
    touchScreen.isHitTestable = true
    
    imageSheet = graphics.newImageSheet("explosion.png", ExplosionOptions) 
    
    titleText = display.newText({
        parent = sceneGroup,
        text = "Example 3 - Image Sheets",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "You can use image sheets to change the image.\n"..
            "or animate sprites. Click on the screen to see\n"..
            "an animated explosion",
        x = Screen.Left + 10,
        y = Screen.Top + 50,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    })

    btnBack = widget.newButton({
        x = Screen.Left + 150,
        y = Screen.Bottom - 50,
        width = 75,
        height = 30,
        fontSize = 12,
        id = "back",
        label = "Back",
        shape = "rect",
        onRelease = onButtonPress,       
    })

    titleText.anchorX = 0
    infoText.anchorX = 0

    sceneGroup:insert(btnBack)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        
        -- Init and create a pool.  This can be done in scene:create() if you want to
        -- keep it around.  I want to unload all objects when user leaves this scene
        -- so I placed it here.
        explosionPool = GBCObjectPool.init(CreateExplosion)
        GBCObjectPool.create(explosionPool, 10, 0, false) 
        
        touchScreen:addEventListener("tap", onScreenTouch)
        sndExplode = audio.loadSound("explosion.mp3")
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        -- remove the pool when the user leaves the scene
        GBCObjectPool.delete(explosionPool)
        
        touchScreen:removeEventListener("tap", onScreenTouch)
        audio.dispose(sndExplode)
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

    btnBack = nil
    infoText = nil
    titleText = nil
    touchScreen = nil
    sndExplode = nil
    imageSheet = nil
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene