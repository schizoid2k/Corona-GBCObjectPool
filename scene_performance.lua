--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene compares the performance of pooling and non-pooling objects.
-- Several options exists (scaling, color, physics) that generally add to the
-- time needed to create an object.
--
-- Note that we compare both the creation of shapes (newRect) and the creation of
-- images (newImageRect). Performance of shapes using newRect seem to be very similar,
-- but generally, pooling provides better performance. Creating imagages via newImageRect
-- definately shows performance via pooling. Stutter is also virtually eliminated.
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local widget = require "widget"
local physics = require "physics"
local GBCObjectPool = require "plugin.GBCObjectPool"
 
--------------------------------------------------------------------------------------
-- Feel free to change these vairables so you can perform your own metrics tests
--------------------------------------------------------------------------------------
local ITERATIONS = 200                      -- Number of cycles to execute
local SQUARES_PER_ITERATION = 100           -- Number of items to display in each cycle
--------------------------------------------------------------------------------------

-- UI
local optionsGroup, statusGroup                     -- groups to hold UI
local radioShape, radioImage                        -- widget UI
local checkPhysics, checkColor, checkScaling        -- widget UI
local txtPhysics, txtColor, txtScaling              -- UI text
local titleText, infoText                           -- UI text
local txtImage, txtShape                            -- UI text
local btnStart, btnBack                             -- UI buttons
local timeTraditional, timePooling                  -- UI result text
local isPhysics, isColor, isScaling, isShapes       -- widget UI

local shapePool, imagePool                          -- id of pools
local startTimeTraditional, endTimeTraditional      -- start/end times
local startTimePooling, endTimePooling              -- start/end times  

-- forward function declarations
local CreateShapeObject, CreateImageObject, ReturnObject
local StartTraditional, StartPooling
local onButtonPress

-- screen shotrcuts
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

-- Function to handle the display of images/shapes via traditional create/destroy.
function StartTraditional(event)
    local DisplayObject = {}
    local cntFrame = 0
    local iterations = 0
    
    local function onEnterFrame(event)
        if cntFrame % 2 ==0 then
            for i = 1, SQUARES_PER_ITERATION do
                if isShapes then
                    DisplayObject[i] = display.newRect(-100, -100, 50, 50)
                else
                    DisplayObject[i] = display.newImageRect("star.png", 50, 50)
                end
                
                if isColor then
                    DisplayObject[i]:setFillColor(math.random(), math.random(), math.random())
                end
                
                if isPhysics then
                    physics.addBody(DisplayObject[i], "kinematic")
                end
                
                DisplayObject[i].x = math.random(Screen.Left + 50, Screen.Right - 50)
                DisplayObject[i].y = math.random(Screen.Top + 50, Screen.Bottom - 50)
                
                if isScaling then
                    local s = math.random() + 0.5
                    DisplayObject[i]:scale(s,s)
                end
            end
        else
            -- remove all objects
            for i = #DisplayObject, 1, -1 do
                if isPhysics then
                    physics.removeBody(DisplayObject[i])
                end
                
                display.remove(DisplayObject[i])
                DisplayObject[i] = nil
            end
            
            iterations = iterations + 1
            if iterations >= ITERATIONS then
                Runtime:removeEventListener("enterFrame", onEnterFrame)
                
                endTimeTraditional = system.getTimer()
                
                timeTraditional.text = "Create/Destroy Time: "..
                    os.difftime(endTimeTraditional, startTimeTraditional).." milliseconds"
                    
                timer.performWithDelay(500, StartPooling)
            end
        end
        
        cntFrame = cntFrame + 1
    end
    
    btnStart.isVisible = false
    btnBack.isVisible = false
    
    startTimeTraditional = system.getTimer()
    Runtime:addEventListener("enterFrame", onEnterFrame)
end

-- Function to handle the display of images/shapes via object pooling.
function StartPooling(event)
    local DisplayObject = {}
    local cntFrame = 0
    local iterations = 0
    local pool
    
    local function onEnterFrame(event)
        if cntFrame % 2 ==0 then
            for i = 1, SQUARES_PER_ITERATION do                
                DisplayObject[i] = GBCObjectPool.get(pool)
                
                if DisplayObject[i] then
                    if isColor then
                        DisplayObject[i]:setFillColor(math.random(), math.random(), math.random())
                    end
                    
                    if isPhysics then
                        DisplayObject[i].isBodyActive = true
                    end                
                    
                    DisplayObject[i].x = math.random(Screen.Left + 50, Screen.Right - 50)
                    DisplayObject[i].y = math.random(Screen.Top + 50, Screen.Bottom - 50)
                    
                    if isScaling then
                        local s = math.random() + 0.5
                        DisplayObject[i]:scale(s,s)
                        DisplayObject[i].scaleSize = s
                    end
                end
            end
        else
            for i = #DisplayObject, 1, -1 do
                GBCObjectPool.put(pool, DisplayObject[i])
            end
            
            iterations = iterations + 1
            if iterations >= ITERATIONS then
                Runtime:removeEventListener("enterFrame", onEnterFrame)
                
                endTimePooling = system.getTimer()
                
                timePooling.text = "Pooling Time: "..
                    os.difftime(endTimePooling, startTimePooling).." milliseconds" 
                    
                btnStart.isVisible = true
                btnBack.isVisible = true
            end
        end
        
        cntFrame = cntFrame + 1
    end
    
    if isShapes then pool = shapePool else pool = imagePool end
 
    startTimePooling = system.getTimer()
    Runtime:addEventListener("enterFrame", onEnterFrame)
end


-- This fuction is required by GBC Object Pool.
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
function CreateShapeObject()
    local object = display.newRect(-100, -100, 50, 50)
    object:setFillColor(1,1,1)
    physics.addBody(object, "kinematic")
    return object
end

-- This fuction is required by GBC Object Pool.
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
function CreateImageObject()
    local object = display.newImageRect("star.png", 50, 50)
    physics.addBody(object, "kinematic")
    return object
end

-- Optional function used by GBC Object Pool.
-- This function resets any changes made to objects.
-- This function is used by both the shape pool and the image pool since the
-- reset items are the same.
function ReturnObject(object)
    if isColor then object:setFillColor(1,1,1) end
    
    if isScaling then 
        local s = 1 / object.scaleSize
        object:scale(s, s)
    end
end

-- Button event listeners
function onButtonPress(event)
    if event.phase == "ended" then
        if event.target.id == "start" then
            timeTraditional.text = ""
            timePooling.text = ""
            
            isPhysics = checkPhysics.isOn
            isColor = checkColor.isOn
            isScaling = checkScaling.isOn
            isShapes = radioShape.isOn
            
            StartTraditional()
        elseif event.target.id == "back" then
            composer.gotoScene("top")
        end
    end
end

 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    
    physics.start()
    
    optionsGroup = display.newGroup()
    statusGroup = display.newGroup()
    
    titleText = display.newText({
        parent = sceneGroup,
        text = "Example 1 - Performance",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "This example will allow you to compare the performance\n"..
            "of creating objects using new/destroy and using\n"..
            "object pools",
        x = Screen.Left + 10,
        y = Screen.Top + 50,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    })

    radioShape = widget.newSwitch({
        x = Screen.Left + 50,
        y = Screen.Top + 100,
        initialSwitchState = true,
        id = "shape",
        style = "radio",
    })

    radioImage = widget.newSwitch({
        x = Screen.Left + 50,
        y = Screen.Top + 130,
        initialSwitchState = false,
        id = "image",
        style = "radio",
    })

    txtShape = display.newText({
        parent = sceneGroup,
        text = "Squares",
        x = radioShape.x + 20,
        y = radioShape.y,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    txtImage = display.newText({
        parent = sceneGroup,
        text = "Images",
        x = radioImage.x + 20,
        y = radioImage.y,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    checkPhysics = widget.newSwitch({
        x = Screen.Left + 175,
        y = Screen.Top + 100,
        initialSwitchState = false,
        id = "physics",
        style = "checkbox",
    })

    checkColor = widget.newSwitch({
        x = Screen.Left + 175,
        y = Screen.Top + 130,
        initialSwitchState = false,
        id = "color",
        style = "checkbox",
    })

    checkScaling = widget.newSwitch({
        x = Screen.Left + 175,
        y = Screen.Top + 160,
        initialSwitchState = false,
        id = "scaling",
        style = "checkbox",
    })

    txtPhysics = display.newText({
        parent = optionsGroup,
        text = "Use Physics",
        x = checkPhysics.x + 20,
        y = checkPhysics.y,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    txtColor = display.newText({
        parent = optionsGroup,
        text = "Add Color",
        x = checkColor.x + 20,
        y = checkColor.y,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    txtScaling = display.newText({
        parent = optionsGroup,
        text = "Add Scaling",
        x = checkScaling.x + 20,
        y = checkScaling.y,
        font = native.systemFont,
        fontSize = 14,
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

    timeTraditional = display.newText({
        parent = statusGroup,
        text = "",
        x = Screen.Left + 40,
        y = Screen.Bottom - 150,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    timePooling = display.newText({
        parent = statusGroup,
        text = "",
        x = Screen.Left + 40,
        y = Screen.Bottom - 100,
        font = native.systemFont,
        fontSize = 14,
        align = "left",
    })

    titleText.anchorX = 0
    infoText.anchorX = 0
    
    timeTraditional.anchorX = 0
    timePooling.anchorX = 0

    txtImage.anchorX = 0
    txtShape.anchorX = 0
    txtColor.anchorX = 0
    txtPhysics.anchorX = 0
    txtScaling.anchorX = 0

    optionsGroup:insert(radioShape)
    optionsGroup:insert(radioImage)
    optionsGroup:insert(txtImage)
    optionsGroup:insert(txtShape)
    optionsGroup:insert(checkPhysics)
    optionsGroup:insert(checkColor)
    optionsGroup:insert(checkScaling)
    optionsGroup:insert(btnStart)
    optionsGroup:insert(btnBack)
    
    statusGroup:insert(timeTraditional)
    statusGroup:insert(timePooling)     
    
    sceneGroup:insert(optionsGroup)
    sceneGroup:insert(statusGroup)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        
        -- Init and create 2 pools.  This can be done in scene:create() if you want to
        -- keep it around.  I want to unload all objects when user leaves this scene
        -- so I placed it here.        
        shapePool = GBCObjectPool.init(CreateShapeObject, ReturnObject)
        GBCObjectPool.create(shapePool, SQUARES_PER_ITERATION + 1, 0, false)  
        
        imagePool = GBCObjectPool.init(CreateImageObject, ReturnObject)
        GBCObjectPool.create(imagePool, SQUARES_PER_ITERATION + 1, 0, false)        
 
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
        
        GBCObjectPool.delete(shapePool)
        GBCObjectPool.delete(imagePool)        
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view  

    GBCObjectPool.delete(shapePool)
    GBCObjectPool.delete(imagePool)
    
    titleText = nil
    infoText = nil
    timeTraditional = nil
    timePooling = nil
    radioShape = nil
    radioImage = nil
    checkPhysics = nil
    checkColor = nil
    checkScaling = nil
    txtPhysics = nil
    txtColor = nil
    txtScaling = nil
    txtImage = nil
    txtShape = nil
    btnStart = nil
    btnBack = nil
   
    optionsGroup = nil
    statusGroup = nil
    
    physics.stop()
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