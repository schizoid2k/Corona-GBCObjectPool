--------------------------------------------------------------------------------------
-- GBC Object Pool Demo
-- Written by John Schumacher
-- Copyright 2017 John Schumacher, Games By Candlelight
-- http://gamesbycandlelight.com
--
-- This scene demonstrates using multiple pools with GBC Object Pool.
-- In this scene, we create a "game" that uses 3 pools: enemy, bullets, and explosions.
--------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local GBCObjectPool = require "plugin.GBCObjectPool"
local widget = require "widget"
local physics = require "physics"

local explosionPool, bulletPool, enemyPool          -- id of pools
local imageSheet                                    -- explosion image sheet
local Walls = {}                                    -- screen boundries
local touchScreen                                   -- invisible rect that handles touch input
local titleText, infoText                           -- title and info
local btnBack, btnFire                              -- buttons
local player                                        -- white square in center of screen
local enemyTimer                                    -- enemy spawn timer
local sndExplode                                    -- explosion sound
local groupSceneGroup                               -- pointer to sceneGroup

-- forward function declarations
local createEnemy, returnEnemy
local createExplosion, returnExplosion
local createBullet, returnBullet
local onFire, onButtonPress
local onBulletCollision
local spriteListener
local movePlayer, moveEnemy

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
function onButtonPress(event)
    if event.target.id == "back" then composer.gotoScene("top") end   
end

-- This fuction is required by GBC Object Pool
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
-- This function creates the enemy object, adds physics, and inserts it into the scene
function createEnemy()
    local enemy = display.newCircle(-100, -100, 8)
    enemy:setFillColor(1,0,0)
    enemy.objectid = "enemy"
    
    physics.addBody(enemy, "kinematic", {
        radius = 8,
        filter = {
            categoryBits = 2,
            maskBits = 1,
        }
    })

    groupSceneGroup:insert(enemy)
    
    return enemy
end

-- Optional function used by GBC Object Pool.
-- This function resets any changes made to the enemy object.
-- Here, we cancel any transitions.
-- Note that GBC Object Pool will attempt to cancel transitions, so this function is not required.
function returnEnemy(enemy)
    transition.cancel(enemy)
end

-- This fuction is required by GBC Object Pool
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
-- This function creates the bullet object, adds physics, and inserts it into the scene
function createBullet()
    local bullet = display.newCircle(-100, -100, 4)
    bullet:setFillColor(1,0,0)
    bullet.objectid = "bullet"
    bullet.collision = onBulletCollision
    bullet:addEventListener("collision")
    
    physics.addBody(bullet, "dynamic", {
        radius = 4,
        filter = {
            categoryBits = 1,
            maskBits = 6, 
        },
    })

    bullet.isBullet = true
    bullet.isSensor = true
    
    groupSceneGroup:insert(bullet)

    return bullet
end

-- Optional function used by GBC Object Pool.
-- This function resets any changes made to the bullet object.
-- Here, we stop any bullet movement before returing to the pool.
function returnBullet(bullet)
    bullet:setLinearVelocity(0,0)
end

-- This fuction is required by GBC Object Pool
-- Function creates a single instance of the object you wish to pool.
-- Create the object, set any parmeters, and return it.
-- This function creates the explosion object, and inserts it into the scene
function createExplosion()
    local explosion = display.newSprite(imageSheet, ExplosionSequence)
    explosion:setSequence("explosion")
    explosion.x = -100
    explosion.y = -100
    explosion:addEventListener("sprite", spriteListener)
    groupSceneGroup:insert(explosion)
    return explosion
end

-- Optional function used by GBC Object Pool.
-- This function resets any changes made to the explosion object.
-- Here, we remove the listener used to determine when the sprite is done playing.
function returnExplosion(explosion)
    explosion:removeEventListener("sprite", spriteListener)
end

-- Function to continuously move the player left and right.
function movePlayer()
    local xPos
    
    if player.x > Screen.CenterX then
        xPos = Screen.Left + 25
    else
        xPos = Screen.Right - 25
    end
    
    player.transitionID = transition.moveTo(player, {
        time = 4000, 
        x = xPos,
        onComplete = movePlayer,
    })
end

-- Function to get an enemy from the pool, randomly place it on the screen, and move it.
-- A new enemy will spawn every 0.5 seconds.
function moveEnemy()     
    local function showEnemy()
        local dest
        local enemy = GBCObjectPool.get(enemyPool)
        
        if enemy ~= nil then
            local pos = math.random(1,4)
            
            if pos == 1 then
                enemy.x = Screen.Left - 25
                enemy.y = math.random(Screen.Top + 25, Screen.CenterY - 25)
                
            elseif pos == 2 then
                enemy.x = Screen.Right + 25
                enemy.y = math.random(Screen.Top + 25, Screen.CenterY - 25) 
                
            elseif pos == 3 then
                enemy.x = Screen.Left - 25
                enemy.y = math.random(Screen.CenterY + 25, Screen.Bottom - 25) 
                
            elseif pos == 4 then
                enemy.x = Screen.Right + 25
                enemy.y = math.random(Screen.CenterY + 25, Screen.Bottom - 25) 
            end
            
            if enemy.x > Screen.CenterX then
                dest = Screen.Left - 25
            else
                dest = Screen.Right + 25
            end 
            
            -- if the enemy avoids getting hit, and gets to the other side of the screen,
            -- it is returned to the pool.
            -- Note that since we created a function called returnEnemy() and passed it
            -- in the pool's initialization, returnEnemy() will be called when enemy is returned
            -- to the pool.
            enemy.transitionID = transition.moveTo(enemy, {
                time = math.random(2000, 3500),
                x = dest,
                onComplete = function() GBCObjectPool.put(enemyPool, enemy) end,
            })
        end
    end
    
    enemyTimer = timer.performWithDelay(500, showEnemy, 0)
end

-- When an explosion is finished playing, it is returned to the pool.
-- Note that since we created a function called returnExplosion() and passed it
-- in the pool's initialization, returnExplosion() will be called when explosion is returned
-- to the pool.
function spriteListener(event)
    if event.phase == "ended" then
        GBCObjectPool.put(explosionPool, event.target)
    end
end

-- Function that will grab 4 bullets from the pool, and fires them in 4 directions.
-- Here, we demonstrate the use of delayed display.
-- Delayed display is not nessessary here, but I added it for demonstration.
-- If you use delayed display, it is up to you to display it (isVisible = true) when you are
-- ready.
function onFire(event)       
    local Rounds = {}

    for i = 1, 4 do
        Rounds[i] = GBCObjectPool.get(bulletPool, true, false)  -- delay display
        
        if Rounds[i] then
            Rounds[i].x = player.x
            Rounds[i].y = player.y
        end
    end
    
    if #Rounds == 4 then
        Rounds[1]:setLinearVelocity(800, 800)
        Rounds[2]:setLinearVelocity(800, -800)
        Rounds[3]:setLinearVelocity(-800, 800)
        Rounds[4]:setLinearVelocity(-800, -800)
        
        -- show it yourself!
        for i = 1, 4 do
            Rounds[i].isVisible = true
        end
    end
end

-- If a bullet hits a wall or an ememy, then return it to the pool.
-- Note that since we created a function called returnBullet() and passed it
-- in the pool's initialization, returnBullet() will be called when a bullet is returned
-- to the pool.
function onBulletCollision(self, event)   
    if event.phase == "began" then
        -- Bullet hit wall?  Just return it.
        if event.other.objectid == "wall" then
            timer.performWithDelay(1, function() GBCObjectPool.put(bulletPool, self) end)
        
        -- Bullet hit enemy?  Play an explosion animation, and return the bullet to the pool
        elseif event.other.objectid == "enemy" then
            local explosion = GBCObjectPool.get(explosionPool)
            
            if explosion then
                explosion.x = self.x
                explosion.y = self.y
                
                timer.performWithDelay(1, function() GBCObjectPool.put(enemyPool, event.other) end)
                timer.performWithDelay(1, function() GBCObjectPool.put(bulletPool, self) end)
                
                explosion:play()
                audio.play(sndExplode)
            end
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
    physics.setGravity(0,0)
    
    groupSceneGroup = sceneGroup
 
    touchScreen = display.newRect(sceneGroup, Screen.CenterX, Screen.CenterY, Screen.Width, 60)
    touchScreen:setFillColor(1,1,1,0.5)
    
    imageSheet = graphics.newImageSheet("explosion.png", ExplosionOptions) 
    
    player = display.newRect(sceneGroup, Screen.Left + 25, Screen.CenterY, 24, 24)
    
    sndExplode = audio.loadSound("explosion.mp3")
    
    Walls["LeftWall"] = display.newRect(sceneGroup,
        Screen.Left,
        Screen.CenterY,
        10,
        Screen.Height
    )

    Walls["RightWall"] = display.newRect(sceneGroup,
        Screen.Right,
        Screen.CenterY,
        10,
        Screen.Height
    )    
    
    Walls["TopWall"] = display.newRect(sceneGroup,
        Screen.CenterX,
        Screen.Top,
        Walls["RightWall"].x - Walls["LeftWall"].x,
        10
    )
    
    Walls["BottomWall"] = display.newRect(sceneGroup,
        Screen.CenterX,
        Screen.Bottom,
        Walls["RightWall"].x - Walls["LeftWall"].x,
        10
    )
    
    Walls["LeftWall"].objectid = "wall"
    Walls["RightWall"].objectid = "wall"
    Walls["TopWall"].objectid = "wall"
    Walls["BottomWall"].objectid = "wall"
    
    physics.addBody(Walls["LeftWall"], "static", {
        filter = {
            categoryBits = 4,
            maskBits = 1,
        }
    })

    physics.addBody(Walls["RightWall"], "static", {
        filter = {
            categoryBits = 4,
            maskBits = 1,
        }
    })

    physics.addBody(Walls["TopWall"], "static", {
        filter = {
            categoryBits = 4,
            maskBits = 1,
        }
    })

    physics.addBody(Walls["BottomWall"], "static", {
        filter = {
            categoryBits = 4,
            maskBits = 1,
        }
    })
    
    btnBack = widget.newButton({
        x = Screen.Left + 50,
        y = Screen.Bottom - 50,
        width = 75,
        height = 30,
        fontSize = 12,
        id = "back",
        label = "Back",
        shape = "rect",
        onRelease = onButtonPress,       
    })

    btnFire = widget.newButton({
        x = Screen.Right - 50,
        y = Screen.Bottom - 50,
        width = 75,
        height = 30,
        fontSize = 12,
        id = "fire",
        label = "Fire!",
        shape = "rect",
        onPress = onFire,       
    })

    titleText = display.newText({
        parent = sceneGroup,
        text = "Example 4 - Using Multiple Pools",
        x = Screen.Left + 10,
        y = Screen.Top + 15,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
    })
    
    infoText = display.newText({
        parent = sceneGroup,
        text = "A sample game using multiple object pools",
        x = Screen.Left + 10,
        y = Screen.Top + 30,
        font = native.systemFont,
        fontSize = 12,
        align = "left",
    })

    titleText.anchorX = 0
    infoText.anchorX = 0
    
    sceneGroup:insert(btnBack)
    sceneGroup:insert(btnFire)
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        
        -- Init and create 3 pools.  This can be done in scene:create() if you want to
        -- keep it around.  I want to unload all objects when user leaves this scene
        -- so I placed it here.
        enemyPool = GBCObjectPool.init(createEnemy, returnEnemy)
        GBCObjectPool.create(enemyPool, 10, 0, true) 
        
        bulletPool = GBCObjectPool.init(createBullet, returnBullet)
        GBCObjectPool.create(bulletPool, 24, 0, true) 
        
        explosionPool = GBCObjectPool.init(createExplosion)
        GBCObjectPool.create(explosionPool, 10, 0, false)  
        
        movePlayer()
        moveEnemy()
 
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
        
        timer.cancel(enemyTimer)
        transition.cancel(player)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        
        
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
    physics.stop()
    
    btnFire = nil
    btnBack = nil
    sndExplode = nil
    titleText = nil
    infoText = nil
    imageSheet = nil
    Walls = nil
    touchScreen = nil
    player = nil
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