--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene demonstrates pooling text objects with GBC Object Pool.
-- Generica text objects are created, and at run time, the text and colors change.
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local GBCObjectPool = require "plugin.GBCObjectPool"
local widget = require "widget"
 
local textPool                      -- id of text pool
local btnStart, btnBack             -- UI buttons
local isRunning                     -- flag
local myTimer                       -- timer used to display objects                 
local titleText, infoText           -- title and info

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

-- table of possible colors to display
local Colors = {
    {color={1, 0, 0}, text="red"},
    {color={0, 1, 0}, text="green"},
    {color={0, 0, 1}, text="blue"},
    {color={1, 1, 0}, text="yellow"},
}

-- This fuction is required by GBC Object Pool.
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
local function CreateTextObject()
    local obj = display.newText({
        text = "",
        x = -100,
        y = -100,
        font = native.systemFont,
        fontSize = 20,
        align = "left",
    })

    obj:setFillColor(1,1,1)

    return obj
end

-- When the start button is pressed, a new text object will be taken from the pool every
-- quarter-second. The text object is then randomly changed to display the name of a color
-- from the color table. The text color is changed to reflect the text.
local function StartDemo()  
    -- Grabs the text object from the event params and returns it to the pool.
    -- Since the text and colors change every time we grab a text object, we do not
    -- need to reset anything.
    local function removeText(event)
        local params = event.source.params
        GBCObjectPool.put(textPool, params.obj)
    end
    
    local function displayText(event)
        local t = GBCObjectPool.get(textPool)
 
        if t ~= nil then
            local index = math.random(1, #Colors)
            
            t:setFillColor(unpack(Colors[index].color))
            t.text = Colors[index].text
            t.x = math.random(Screen.Left + 50, Screen.Right - 50)
            t.y = math.random(Screen.Top + 50, Screen.Bottom - 50)
            
            -- create a timer to remove the text.
            -- pass a reference to the object to remove, so 
            -- removeText() can return it to the pool.
            local myTimer = timer.performWithDelay(250, removeText)
            myTimer.params = {obj = t}
        end       
    end
    
    if isRunning then
        timer.cancel(myTimer)
        btnStart:setLabel("Start")
        isRunning = false
    else  
        btnStart:setLabel("Stop")
        isRunning = true
        myTimer = timer.performWithDelay(250, displayText, -1)
    end
end

-- button event handler
local function onButtonPress(event)
    if event.target.id == "back" then composer.gotoScene("top") end
    if event.target.id == "start" then StartDemo() end
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    
    math.randomseed(os.time()) 
    
    titleText = display.newText({
        parent = sceneGroup,
        text = "Example 2 - Text Objects",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "Any display object can be added to the pool.\n"..
            "Here, we create some text objects, change them at runtime,\n"..
            "and put them back in the pool when done.",
        x = Screen.Left + 10,
        y = Screen.Top + 50,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    })    
    
    btnStart = widget.newButton({
        x = Screen.Left + 50,
        y = Screen.Bottom - 50,
        width = 75,
        height = 30,
        fontSize = 12,
        id = "start",
        label = "Start",
        shape = "rect",
        onRelease = onButtonPress,       
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

    sceneGroup:insert(btnStart)
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
        textPool = GBCObjectPool.init(CreateTextObject)
        GBCObjectPool.create(textPool, 10, 0, false)        
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        isRunning = false
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
        
        GBCObjectPool.delete(textPool)
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
    GBCObjectPool.delete(textPool)
    
    btnStart = nil
    btnBack = nil
    titleText = nil
    infoText = nil
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