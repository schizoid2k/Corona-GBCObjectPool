--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene demonstrates a way to handle complex physics objects.
-- The easiest method is to create multiple pools of object and combine
-- them with physics joints when needed.
-- Return objects to their specific pool when you are done with them.
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local physics = require "physics"
local widget = require "widget"
local GBCObjectPool = require "plugin.GBCObjectPool"

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

-- variables

-- UI 
local screenRect                -- make screen a touch point
local titleText, infoText       -- information
local btnBack                   -- back button

-- pools
local squarePool                -- main object in the multipool example
local circlePool                -- satellite objects in the multipool example

-- forward function declarations
local createMainObject          -- create a single instance of main object (square)
local returnMainObject          -- removes a single instance of main object (square) 
local createSatellite           -- create a single instance of satellite object (circle)
local returnSatellite           -- removes a single instance of a satellite object (circle)
local onSquareTap               -- listener for object. removes object when clicked
local onScreenTap               -- handles putting a complex object on the screen

--------------------------------------------------------
-- Multi-Pool example
-- The multi-pool example create a an complex object
-- using mulitple pools.  One pool for the main object
-- (square) and one pool for the satellites (circles)
--------------------------------------------------------

-- Creates a single instance of the center (square) object
function createMainObject()
    local square = display.newRect(scene.view, -100, -100, 50, 50)
    square:setFillColor(0,0,1)
    physics.addBody(square, "static")
    return square
end

-- Creates a single instance of a circle
function createSatellite()
   local circle = display.newCircle(scene.view, -100, -100, 25)
   circle:setFillColor(1,0,0)
   physics.addBody(circle, {radius = 25, density = 0.5, bounce = 0.5})
   return circle
end

-- When a square is returned to the pool, I clean up a bit by
-- moving the object out of screen view, so we do not see inactive physics
-- objects when they are returned to the screen.
function returnMainObject(square)
    square.x = -100
    square.y = -100
end

-- When a circle is returned to the pool, I clean up a bit by
-- moving the object out of screen view, so we do not see inactive physics
-- objects when they are returned to the screen.
function returnSatellite(satellite)
    satellite.x = -100
    satellite.y = -100
end

-- When you tap on the square object, the entire complex object
-- is returned to the proper pools.
-- Note that since we are not destroying objects (we are pooling them)
-- we have to manually remove and nil all physics joints, since we created them
-- when we created this complex object.
function onSquareTap(event)
    local object = event.target
    
    -- remove the physics joints
    for i = #object.joints, 1, -1 do
        display.remove(object.joints[i])
        object.joints[i] = nil
    end
    
    -- put the circles back into the pool
    for i = #object.satellites, 1, -1 do
        GBCObjectPool.put(circlePool, object.satellites[i])
    end
    
    -- nil out the joint and circle variables
    object.satellites = nil
    object.joints = nil
    
    -- remove listener from square
    object:removeEventListener("tap", onSquareTap)
    
    -- place square into pool
    GBCObjectPool.put(squarePool, object) 
    
    return true
end

-- This creates a complex object using multiple pools.
-- We grab 1 object from the square pool, and 3 objects from the 
-- circle pool.
-- Notice, we then create the proper joints, and event listeners.
-- We also have to save a reference to the joints and the circles so that
-- they can be returned to the pool later.
function onScreenTap(event)
    local Circles = {}
    local Joints = {}
    
    local square = GBCObjectPool.get(squarePool)
    
    for i = 1, 3 do
        Circles[i] = GBCObjectPool.get(circlePool)
    end
    
    square.x = event.x
    square.y = event.y
    Circles[1].x = square.x - 70
    Circles[1].y = square.y
    Circles[2].x = square.x + 70
    Circles[2].y = square.y
    Circles[3].x = square.x + 5
    Circles[3].y = square.y + 70
    
    Joints[1] = physics.newJoint("rope", square, Circles[1], 0, 0, 0, 0)
    Joints[2] = physics.newJoint("rope", square, Circles[2], 0, 0, 0, 0)
    Joints[3] = physics.newJoint("rope", square, Circles[3], 0, 0, 0, 0)
    
    -- Save a reference to all the joints and circles in the square object
    -- We will need this later when placeing back into the pool
    square.satellites = Circles
    square.joints = Joints    
    
    square:addEventListener("tap", onSquareTap)
    
    return true
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
       
    screenRect = display.newRect(sceneGroup, Screen.CenterX, Screen.CenterY, 
        Screen.Width, Screen.Bottom - 150)
    
    screenRect:setFillColor(0,0,0)
    screenRect.isVisible = false
    screenRect.isHitTestable = true    
    
    titleText = display.newText({
        parent = sceneGroup,
        text = "Complex Objects",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "This example demonstrates pooling complex objects",
        x = Screen.Left + 10,
        y = Screen.Top + 40,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    }) 

    titleText.anchorX = 0
    infoText.anchorX = 0    

    btnBack = widget.newButton({
        x = Screen.Right - 50,
        y = Screen.Bottom - 25,
        width = 75,
        height = 30,
        fontSize = 12,
        id = "back",
        label = "Back",
        shape = "rect",
        onRelease = function() composer.gotoScene("top") end,
    }) 

    sceneGroup:insert(btnBack)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        
        physics.start()
        physics.setDrawMode("hybrid")   -- hybrid so you can see the joints
        
        squarePool = GBCObjectPool.init(createMainObject, returnMainObject)
        GBCObjectPool.create(squarePool, 10, 0, true) 
        
        circlePool = GBCObjectPool.init(createSatellite, returnSatellite)
        GBCObjectPool.create(circlePool, 100, 0, true)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        
        screenRect:addEventListener("tap", onScreenTap)
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        
        screenRect:removeEventListener("tap", onScreenTap)
        GBCObjectPool.delete(squarePool)
        GBCObjectPool.delete(circlePool)
        physics.stop()
        
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        -- TODO: Remove all items from the screen    
        
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
    
    display.remove(titleText)
    display.remove(infoText)
    display.remove(btnBack)
    display.remove(screenRect)
    
    titleText = nil
    infoText = nil
    btnBack = nil
    screenRect = nil
    squarePool = nil
    circlePool = nil
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