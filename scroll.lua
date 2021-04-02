-- title: Pitfall Remake
-- author: Shuang and Henning
-- desc: The player can walk across the screen  
-- script: lua

UP = 0
DOWN = 1
LEFT = 2
RIGHT = 3

t=0

init=289

-- deep table copy from: https://gist.github.com/tylerneylon/81333721109155b2d244
function copy(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
  
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

function createAnimation(frames,size,fps)
	return {cf=0,frames=frames,size=size,t=1/fps*1000,spf=1/fps*1000}
end

function resetAnimation(anim)
	anim.cf=0 anim.t=anim.spf
end

-- check if pixel coords x,y are on a map type of type in table where table is {[maptile]=boolean}
function isOn(x,y,table)
	return table[mget((x)//8,(y)//8)]
end

-- check if obj at x,y isOn a tile type in any of the directions in directions
function collision(x,y,table,directions)
	local dirToOffset = {[UP]={{0,0},{7,0}},[DOWN]={{0,8},{7,8}},[LEFT]={{0,0},{8,0}},[RIGHT]={{7,0},{8,7}}} --x,y coods to check keyed by direction
	local temp = false
	for idx,dir in pairs(directions) do
		for idx,corner in pairs(dirToOffset[dir]) do
			temp = temp or isOn(x+corner[1],y+corner[2],table)
		end
	end
	return temp
end


function obj_collision(x,y,obj,threshold)
	--print(math.sqrt((x-obj.pos.x)^2+(y-obj.pos.y)^2))
	return math.sqrt((x-obj.pos.x)^2+(y-obj.pos.y)^2)<threshold
end

function drawAnimation(anim,dt,x,y,ts,flip)
	anim.t=anim.t-dt
	if anim.t<=0 then 
		anim.t=anim.t+anim.spf
		anim.cf=anim.cf+1
		if anim.cf>=#anim.frames then
			anim.cf=0
		end
	end
	local f=anim.frames[anim.cf+1]
	for i=0,anim.size do
		for j=0,anim.size do
			if flip==0 then
				spr(f+i+j*16,x+i*8,y+j*8,ts,1,flip)
			else
			 spr(f+i+j*16,x+(anim.size-i)*8,y+j*8,ts,1,flip)
			end
		end
	end
end

 -- log functions
function new_log(x_,y_)
	return {type='log',pos={x=x_,y=y_},spr=280,update_func=log_update,collide_effect=log_collide}
end

function log_update(log)
	log.pos.x = log.pos.x-1
	if log.pos.x < 0 then
		log.pos.x = 232
	end
end

function log_collide()
	p.vx=p.vx/4
	p.vy = p.vy/4
end

function new_scene(scene_num)
	interactables = copy(scenes[scene_num],{})
end

function init()
	solids={[121]=true,[106]=true}--121 and 106 are the two type of sprite that the character can stand on
	ladders={[90]=true}
	laddertop={[138]=true}
	p={x=120,y=64,vx=0,vy=0,climbing=false} --player
	pt=time()
	dt=0
	flip=0
	big=createAnimation({256,258,260,258},1,10)
	anim=big
	-- scenes is a table of obsticles and their relative x,y positions in a given scene
	scenes = {{new_log(100,72),new_log(150,72)},{new_log(100,72)}}
	interactables = copy(scenes[1],{}) -- interactables are the current objects in the scene the player is in
	scene = 1
end

function sign(n) 
return n>0 and 1 or n<0 and -1 or 0 end
function lerp(a,b,t) 
return (1-t)*a + t*b end

init()
function TIC()
	cls(0)		
	t=t+3
	p.x=p.x+p.vx
    p.y=p.y+p.vy

    local n_scene = (p.x//232)+1
    if n_scene ~= scene then
    	scene = n_scene
    	new_scene(scene)
    end


	--map [x=0 y=0] [w=30 h=17] [sx=0 sy=0] [colorkey=-1] [scale=1] [remap=nil]
	map(((p.x//232)*30),0,30,17,0,0)
	print(p.x .. " " .. p.y .. " " .. p.vx .. " " .. p.vy .." " .. (p.x//232)*30,10,10)

	-- calculate delta time
	dt=time()-pt
	pt=time()
	
	-- change the animation state and direction based on controls
	state=0
	if btn(LEFT) then 
		state=1 
		flip=1 
		p.vx=-1 
    elseif btn(RIGHT) then
     	state=1 
		flip=0 
    	p.vx=1
    else 
    	p.vx=0
    end

    -- dont fall when standing on ground
    if collision(p.x+p.vx,p.y+p.vy,solids,{DOWN}) then
        p.vy=0
    else
        p.vy=p.vy+0.25		
    end
    
    -- jump
    if p.vy==0 and btnp(4) then 
    	p.vy=-2.5 

    end  

    -- check upper collision
    if p.vy<0 and collision(p.x+p.vx,p.y+p.vy,solids,{UP}) then
        p.vy=0
    end 

    -- ladder logic
    --if isOn(p.x+8+p.vx,p.y+p.vy,ladders) then
    if collision(p.x+p.vx,p.y+p.vy,ladders,{DOWN}) or collision(p.x+p.vx,p.y+p.vy,laddertop,{UP}) then

    	if not collision(p.x+p.vx,p.y+p.vy,solids,{DOWN}) then
    		p.vy = .25 --set falling speed on ladder when not climbing
    	end

    	if btn(UP) then
    		p.climbing = true
    	end

    	if p.climbing then
    		print('t')
    		if btn(UP) then
    			--p.y=p.y-0.5
    			p.vy = -0.5
    		elseif btn(DOWN) and not collision(p.x+p.vx,p.y+p.vy,solids,{DOWN}) then
    			--p.y = p.y+0.5
    			p.vy = 0.5
    		else
    			p.vy = 0
    		end
    	end
    end

    if p.climbing and collision(p.x+p.vx,p.y+p.vy,laddertop,{UP,DOWN}) then
    	    	if btn(LEFT) then
    		p.vy=-3.5
    		p.vx=-1
    		p.climbing = false
    	elseif btn(RIGHT) then
    		p.vy=-2.5
    		p.vx=1
    		p.climbing = false
    	end
    end
	
	-- clear screen
	-- reset the current animation when no btns pressed
	if state==0 then resetAnimation(anim) end
	-- draw the screen
	drawAnimation(anim,dt,p.x%232,p.y,0,flip)

	for i,obs in pairs(interactables) do
		obs.update_func(obs)
		if obj_collision(p.x%232+4,p.y+8,obs,9) then --center
			--print('ow',0,30)
			obs.collide_effect()
		end
		--print(i..' '..obs.pos.x..' '..obs.pos.y,10+50*i,30)
		spr(obs.spr,obs.pos.x,obs.pos.y,0)
	end

end
