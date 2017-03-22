--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene demonstrates the use of parameters within your Create and Return functions.
-- This is useful when you want to create multiple pools of similar (but slightly)
-- different objects.
--
-- The example here shows a way to share a common Create and Return function, instead
-- of creating a separate Create and Return function for each object pool.  This should
-- simplify your code.
--
-- To use parameters, pass a table of parameters into GBCObjectPool.create().
-- GBCObjectPool will store these parameters in case you need to create more
-- objects (via autoexpand), or when you need to return an object to the pool.
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local GBCObjectPool = require "plugin.GBCObjectPool"
local widget = require "widget"

local starPool, heartPool
local titleText, infoText
local btnBack

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

-- forward declarations
local CreateObject
local ReturnObject
local displayImages
local onButtonPress

function onButtonPress(event)
    if event.phase == "ended" then composer.gotoScene("top") end
end

-- Shared Create function.
-- Notice that we are utilizing the parameters you passed into GBCObjectPool.create().
-- In this example, we are create a pool of images passed via parameters, as well as
-- adding a new field (id).
function CreateObject(myParams) 
    if myParams ~= nil then
        local obj = display.newImageRect(myParams.image, 50, 50) 
        obj.id = myParams.id
        return obj
    else
        return nil
    end
end
 
-- Shared Return function
-- Notice that we are utilizing the parameters you passed into GBCObjectPool.create().
-- In this example, we are resetting the color for all objects (no parameters).
-- We are also resetting the id to the inital value passed when creating the object.
function ReturnObject(obj, myParams)
    obj:setFillColor(1,1,1)
    
    if myParams ~= nil then
        obj.id = myParams.id
    end
end

function displayImages()
    local star = GBCObjectPool.get(starPool)
    star.x = Screen.CenterX
    star.y = 150
    star:setFillColor(math.random(), math.random(), math.random())
    
    local heart = GBCObjectPool.get(heartPool)
    heart.x = Screen.CenterX
    heart.y = 250
    heart:setFillColor(math.random(), math.random(), math.random()) 
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
    titleText = display.newText({
        parent = sceneGroup,
        text = "Example 6 - Parameters",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "This example demonstrates passing parameters to your\n"..
            "create and return functions.  This allows you to\n"..
            "share functions for simialr objects",
        x = Screen.Left + 10,
        y = Screen.Top + 50,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    })

    btnBack = widget.newButton({
        x = Screen.CenterX,
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
    
    sceneGroup:insert(titleText)
    sceneGroup:insert(infoText)
    sceneGroup:insert(btnBack)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        
        -- Example of parameter table.
        -- This can be any "key/value" combinatrion and will be stored 
        -- in the pool for future reference.
        local myStarParams = {
            image = "star.png",
            id = "star",
        }
        
        local myHeartParams = {
            image = "heart.png",
            id = "heart",            
        }
        
        GBCObjectPool.setDebugMode(true)
        
        starPool = GBCObjectPool.init(CreateObject, ReturnObject)
        GBCObjectPool.create(starPool, 10, 0, false, myStarParams)
           
        heartPool = GBCObjectPool.init(CreateObject, ReturnObject)      
        GBCObjectPool.create(heartPool, 10, 0, false, myHeartParams)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        
        displayImages()
 
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
        
        GBCObjectPool.delete(heartPool)
        GBCObjectPool.delete(starPool)
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

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