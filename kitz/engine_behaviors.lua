local abs = math.abs
local pi = math.pi
--local floor = math.floor
local ceil = math.ceil
local random = math.random
local sqrt = math.sqrt
--local max = math.max
--local min = math.min
--local tan = math.tan
--local pow = math.pow
--local dbg = minetest.chat_send_all

local abr = tonumber(minetest.get_mapgen_setting('active_block_range')) or 3

local neighbors ={
	{x=1,z=0},
	{x=1,z=1},
	{x=0,z=1},
	{x=-1,z=1},
	{x=-1,z=0},
	{x=-1,z=-1},
	{x=0,z=-1},
	{x=1,z=-1}
	}

function kitz.dir2neighbor(dir)
	dir.y=0
	dir=vector.round(vector.normalize(dir))
	for k,v in ipairs(neighbors) do
		if v.x == dir.x and v.z == dir.z then return k end
	end
	return 1
end

function kitz.neighbor_shift(neighbor,shift)	-- int shift: minus is left, plus is right
	return (8+neighbor+shift-1)%8+1
end

function kitz.is_neighbor_node_reachable(self,neighbor)	-- todo: take either number or pos
	local offset = neighbors[neighbor]
	local pos=kitz.get_stand_pos(self)
	local tpos = kitz.get_node_pos(kitz.pos_shift(pos,offset))
	if minetest.global_exists("petz")
		and not(petz.settings.jump_fences) and kitz.in_group(tpos, "fence") then --don't jump fences
			return
	end
	local recursteps = ceil(self.jump_height)+1
	local height, liquidflag = kitz.get_terrain_height(tpos,recursteps)

	if height and abs(height-pos.y) <= self.jump_height then
		tpos.y = height
		height = height - pos.y

		-- don't cut corners
		if neighbor % 2 == 0 then				-- diagonal neighbors are even
			local n2 = neighbor-1				-- left neighbor never < 0
			offset = neighbors[n2]
			local t2 = kitz.get_node_pos(kitz.pos_shift(pos,offset))
			local h2 = kitz.get_terrain_height(t2,recursteps)
			if h2 and h2 - pos.y > 0.02 then return end
			n2 = (neighbor+1)%8 		-- right neighbor
			offset = neighbors[n2]
			t2 = kitz.get_node_pos(kitz.pos_shift(pos,offset))
			h2 = kitz.get_terrain_height(t2,recursteps)
			if h2 and h2 - pos.y > 0.02 then return end
		end

		-- check headroom
		if tpos.y+self.height-pos.y > 1 then			-- if head in next node above, else no point checking headroom
			local snpos = kitz.get_node_pos(pos)
			local pos1 = {x=pos.x,y=snpos.y+1,z=pos.z}						-- current pos plus node up
			local pos2 = {x=tpos.x,y=tpos.y+self.height,z=tpos.z}			-- target head pos

			local nodes = kitz.get_nodes_in_area(pos1,pos2,true)

			for p,node in pairs(nodes) do
				if snpos.x==p.x and snpos.z==p.z then
					if node.name=='ignore' or node.walkable then return end
				else
					if node.name=='ignore' or
					(node.walkable and kitz.get_node_height(p)>tpos.y+0.001) then return end
				end
			end
		end

		return height, tpos, liquidflag
	else
		return
	end
end

function kitz.get_next_waypoint(self,tpos)
	local pos = kitz.get_stand_pos(self)
	local dir=vector.direction(pos,tpos)
	local neighbor = kitz.dir2neighbor(dir)
	local function update_pos_history(self,pos)
		table.insert(self.pos_history,1,pos)
		if #self.pos_history > 2 then table.remove(self.pos_history,#self.pos_history) end
	end
	local nogopos = self.pos_history[2]

	local height, pos2, liquidflag = kitz.is_neighbor_node_reachable(self,neighbor)
	if height and not liquidflag
	and not (nogopos and kitz.isnear2d(pos2,nogopos,0.1)) then

		local heightl = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,-1))
		if heightl and abs(heightl-height)<0.001 then
			local heightr = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,1))
			if heightr and abs(heightr-height)<0.001 then
				dir.y = 0
				local dirn = vector.normalize(dir)
				local npos = kitz.get_node_pos(kitz.pos_shift(pos,neighbors[neighbor]))
				local factor = abs(dirn.x) > abs(dirn.z) and abs(npos.x-pos.x) or abs(npos.z-pos.z)
				pos2=kitz.pos_shift(pos,{x=dirn.x*factor,z=dirn.z*factor})
			end
		end
		update_pos_history(self,pos2)
		return height, pos2
	else

		for i=1,3 do
			-- scan left
			local height, pos2, liq = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,-i*self.path_dir))
			if height and not liq
			and not (nogopos and kitz.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2
			end
			-- scan right
			height, pos2, liq = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,i*self.path_dir))
			if height and not liq
			and not (nogopos and kitz.isnear2d(pos2,nogopos,0.1)) then
				update_pos_history(self,pos2)
				return height,pos2
			end
		end
		--scan rear
		height, pos2, liquidflag = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,4))
		if height and not liquidflag
		and not (nogopos and kitz.isnear2d(pos2,nogopos,0.1)) then
			update_pos_history(self,pos2)
			return height,pos2
		end
	end
	-- stuck condition here
	table.remove(self.pos_history,2)
	self.path_dir = self.path_dir*-1	-- subtle change in pathfinding
end

function kitz.get_next_waypoint_fast(self,tpos,nogopos)
	local pos = kitz.get_stand_pos(self)
	local dir=vector.direction(pos,tpos)
	local neighbor = kitz.dir2neighbor(dir)
	local height, pos2, liquidflag = kitz.is_neighbor_node_reachable(self,neighbor)

	if height and not liquidflag then
		local fast = false
		local heightl = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,-1))
		if heightl and abs(heightl-height)<0.001 then
			local heightr = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,1))
			if heightr and abs(heightr-height)<0.001 then
				fast = true
				dir.y = 0
				local dirn = vector.normalize(dir)
				local npos = kitz.get_node_pos(kitz.pos_shift(pos,neighbors[neighbor]))
				local factor = abs(dirn.x) > abs(dirn.z) and abs(npos.x-pos.x) or abs(npos.z-pos.z)
				pos2=kitz.pos_shift(pos,{x=dirn.x*factor,z=dirn.z*factor})
			end
		end
		return height, pos2, fast
	else
		local liq
		for i=1,4 do
			-- scan left
			height, pos2, liq = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,-i))
			if height and not liq then return height,pos2 end
			-- scan right
			height, pos2, liq = kitz.is_neighbor_node_reachable(self,kitz.neighbor_shift(neighbor,i))
			if height and not liq then return height,pos2 end
		end
	end
end

function kitz.goto_next_waypoint(self,tpos)
	local height, pos2 = kitz.get_next_waypoint(self,tpos)

	if not height then return false end

	if height <= 0.01 then
		local yaw = self.object:get_yaw()
		local tyaw = minetest.dir_to_yaw(vector.direction(self.object:get_pos(),pos2))
		if abs(tyaw-yaw) > 1 then
			kitz.lq_turn2pos(self,pos2)
		end
		kitz.lq_dumbwalk(self,pos2)
	else
		kitz.lq_turn2pos(self,pos2)
		kitz.lq_dumbjump(self,height)
	end
	return true
end

----------------------------
-- BEHAVIORS
----------------------------
-- LOW LEVEL QUEUE FUNCTIONS
----------------------------

function kitz.lq_turn2pos(self,tpos)
	local func=function(self)
		local pos = self.object:get_pos()
		return kitz.turn2yaw(self,
			minetest.dir_to_yaw(vector.direction(pos,tpos)))
	end
	kitz.queue_low(self,func)
end

function kitz.lq_idle(self,duration,anim)
	anim = anim or 'stand'
	local init = true
	local func=function(self)
		if init then
			kitz.animate(self,anim)
			init=false
		end
		duration = duration-self.dtime
		if duration <= 0 then return true end
	end
	kitz.queue_low(self,func)
end

function kitz.lq_dumbwalk(self,dest,speed_factor)
	local timer = 3			-- failsafe
	speed_factor = speed_factor or 1
	local func=function(self)
		kitz.animate(self,'walk')
		timer = timer - self.dtime
		if timer < 0 then return true end

		local pos = kitz.get_stand_pos(self)
		local y = self.object:get_velocity().y

		if kitz.is_there_yet2d(pos,minetest.yaw_to_dir(self.object:get_yaw()),dest) then
--		if kitz.isnear2d(pos,dest,0.25) then
			if not self.isonground or abs(dest.y-pos.y) > 0.1 then		-- prevent uncontrolled fall when velocity too high
--			if abs(dest.y-pos.y) > 0.1 then	-- isonground too slow for speeds > 4
				self.object:set_velocity({x=0,y=y,z=0})
			end
			return true
		end

		if self.isonground then
			local dir = vector.normalize(vector.direction({x=pos.x,y=0,z=pos.z},
														{x=dest.x,y=0,z=dest.z}))
			dir = vector.multiply(dir,self.max_speed*speed_factor)
--			self.object:set_yaw(minetest.dir_to_yaw(dir))
			kitz.turn2yaw(self,minetest.dir_to_yaw(dir))
			dir.y = y
			self.object:set_velocity(dir)
		end
	end
	kitz.queue_low(self,func)
end

-- initial velocity for jump height h, v= a*sqrt(h*2/a) ,add 20%
function kitz.lq_dumbjump(self,height,anim)
	anim = anim or 'stand'
	local jump = true
	local func=function(self)
	local yaw = self.object:get_yaw()
		if self.isonground then
			if jump then
				kitz.animate(self,anim)
				local dir = minetest.yaw_to_dir(yaw)
				dir.y = -kitz.gravity*sqrt((height+0.35)*2/-kitz.gravity)
				self.object:set_velocity(dir)
				jump = false
			else				-- the eagle has landed
				return true
			end
		else
			local dir = minetest.yaw_to_dir(yaw)
			local vel = self.object:get_velocity()
			if self.lastvelocity.y < 0.9 then
				dir = vector.multiply(dir,3)
			end
			dir.y = vel.y
			self.object:set_velocity(dir)
		end
	end
	kitz.queue_low(self,func)
end

function kitz.lq_jumpout(self)
	local phase = 1
	local func=function(self)
		local vel=self.object:get_velocity()
		if phase == 1 then
			vel.y=vel.y+5
			self.object:set_velocity(vel)
			phase = 2
		else
			if vel.y < 0 then return true end
			local dir = minetest.yaw_to_dir(self.object:get_yaw())
			dir.y=vel.y
			self.object:set_velocity(dir)
		end
	end
	kitz.queue_low(self,func)
end

function kitz.lq_freejump(self)
	local phase = 1
	local func=function(self)
		local vel=self.object:get_velocity()
		if phase == 1 then
			vel.y=vel.y+6
			self.object:set_velocity(vel)
			phase = 2
		else
			if vel.y <= 0.01 then return true end
			local dir = minetest.yaw_to_dir(self.object:get_yaw())
			dir.y=vel.y
			self.object:set_velocity(dir)
		end
	end
	kitz.queue_low(self,func)
end

function kitz.lq_jumpattack(self,height,target)
	local init=true
	--local timer=0.5
	local tgtbox = target:get_properties().collisionbox
	local func=function(self)
		if not kitz.is_alive(target) then return true end
		if self.isonground then
			if init then	-- collision bug workaround
				--local vel = self.object:get_velocity()
				local dir = minetest.yaw_to_dir(self.object:get_yaw())
				dir=vector.multiply(dir,6)
				dir.y = -kitz.gravity*sqrt(height*2/-kitz.gravity)
				self.object:set_velocity(dir)
				kitz.play_sound(self,'charge')
				init=false
			else
				kitz.lq_idle(self,0.3)
				return true
			end
		else
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()
			-- calculate attack spot
			local yaw = self.object:get_yaw()
			local dir = minetest.yaw_to_dir(yaw)
			local apos = kitz.pos_translate2d(pos,yaw,self.attack.range)

			if kitz.is_pos_in_box(apos,tgtpos,tgtbox) then	--bite
				target:punch(self.object,1,self.attack)
					-- bounce off
				local vy = self.object:get_velocity().y
				self.object:set_velocity({x=dir.x*-3,y=vy,z=dir.z*-3})
					-- play attack sound if defined
				kitz.play_sound(self,'attack')
				return true
			end
		end
	end
	kitz.queue_low(self,func)
end

function kitz.lq_fallover(self)
	local zrot = 0
	local init = true
	local func=function(self)
		if init then
			local vel = self.object:get_velocity()
			self.object:set_velocity(kitz.pos_shift(vel,{y=1}))
			kitz.animate(self,'stand')
			init = false
		end
		zrot=zrot+pi*0.05
		local rot = self.object:get_rotation()
		self.object:set_rotation({x=rot.x,y=rot.y,z=zrot})
		if zrot >= pi*0.5 then return true end
	end
	kitz.queue_low(self,func)
end
-----------------------------
-- HIGH LEVEL QUEUE FUNCTIONS
-----------------------------

function kitz.dumbstep(self,height,tpos,speed_factor,idle_duration)
	if height <= 0.001 then
		kitz.lq_turn2pos(self,tpos)
		kitz.lq_dumbwalk(self,tpos,speed_factor)
	else
		kitz.lq_turn2pos(self,tpos)
		kitz.lq_dumbjump(self,height)
	end
	idle_duration = idle_duration or 6
	kitz.lq_idle(self,random(ceil(idle_duration*0.5),idle_duration))
end

function kitz.hq_roam(self,prty)
	local func=function(self)
		if kitz.is_queue_empty_low(self) and self.isonground then
			--local pos = kitz.get_stand_pos(self)
			local neighbor = random(8)

			local height, tpos, liquidflag = kitz.is_neighbor_node_reachable(self,neighbor)
			if height and not liquidflag then kitz.dumbstep(self,height,tpos,0.3) end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_follow0(self,tgtobj)	-- probably delete this one
	local func = function(self)
		if not tgtobj then return true end
		if kitz.is_queue_empty_low(self) and self.isonground then
			local pos = kitz.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) > 3 then
				local neighbor = kitz.dir2neighbor(vector.direction(pos,opos))
				if not neighbor then return true end		--temp debug
				local height, tpos = kitz.is_neighbor_node_reachable(self,neighbor)
				if height then kitz.dumbstep(self,height,tpos)
				else
					for i=1,4 do --scan left
						height, tpos = kitz.is_neighbor_node_reachable(self,(8+neighbor-i-1)%8+1)
						if height then kitz.dumbstep(self,height,tpos)
							break
						end		--scan right
						height, tpos = kitz.is_neighbor_node_reachable(self,(neighbor+i-1)%8+1)
						if height then kitz.dumbstep(self,height,tpos)
							break
						end
					end
				end
			else
				kitz.lq_idle(self,1)
			end
		end
	end
	kitz.queue_high(self,func,0)
end

function kitz.hq_follow(self,prty,tgtobj)
	local func = function(self)
		if not kitz.is_alive(tgtobj) then return true end
		if kitz.is_queue_empty_low(self) and self.isonground then
			local pos = kitz.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) > 3 then
				kitz.goto_next_waypoint(self,opos)
			else
				kitz.lq_idle(self,1)
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_goto(self,prty,tpos)
	local func = function(self)
		if kitz.is_queue_empty_low(self) and self.isonground then
			local pos = kitz.get_stand_pos(self)
			if vector.distance(pos,tpos) > 3 then
				kitz.goto_next_waypoint(self,tpos)
			else
				return true
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_runfrom(self, prty, tgtobj)
	local init=true
	local timer=6
	local func = function(self)

		if not kitz.is_alive(tgtobj) then return true end
		if init then
			timer = timer-self.dtime
			if timer <=0 or vector.distance(self.object:get_pos(),tgtobj:get_pos()) < 8 then
				kitz.play_sound(self,'scared')
				init=false
			end
			return
		end

		if kitz.is_queue_empty_low(self) and self.isonground then
			local pos = kitz.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) < self.view_range*1.1 then
				local tpos = {x=2*pos.x - opos.x,
								y=opos.y,
								z=2*pos.z - opos.z}
				kitz.goto_next_waypoint(self,tpos)
			else
				self.object:set_velocity({x=0,y=0,z=0})
				return true
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_hunt(self,prty,tgtobj)
	local func = function(self)
		if not kitz.is_alive(tgtobj) then return true end
		if kitz.is_queue_empty_low(self) and self.isonground then
			local pos = kitz.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local dist = vector.distance(pos,opos)
			if dist > self.view_range then
				return true
			elseif dist > 3 then
				kitz.goto_next_waypoint(self,opos)
			else
				kitz.hq_attack(self,prty+1,tgtobj)
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_warn(self,prty,tgtobj)
	local timer=0
	local tgttime = 0
	local init = true
	local func = function(self)
		if not kitz.is_alive(tgtobj) then return true end
		if init then
			kitz.animate(self,'stand')
			init = false
		end
		local pos = kitz.get_stand_pos(self)
		local opos = tgtobj:get_pos()
		local dist = vector.distance(pos,opos)

		if dist > 11 then
			return true
		elseif dist < 4 or timer > 12 then						-- too close man
--			kitz.clear_queue_high(self)
			kitz.remember(self,'hate',tgtobj:get_player_name())
			kitz.hq_hunt(self,prty+1,tgtobj)							-- priority
		else
			timer = timer+self.dtime
			if kitz.is_queue_empty_low(self) then
				kitz.lq_turn2pos(self,opos)
			end
			-- make noise in random intervals
			if timer > tgttime then
				kitz.play_sound(self,'warn')
				-- if self.sounds and self.sounds.warn then
					-- minetest.sound_play(self.sounds.warn, {object=self.object})
				-- end
				tgttime = timer + 1.1 + random()*1.5
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_die(self)
	local timer = 5
	local start = true
	local func = function(self)
		if start then
			kitz.lq_fallover(self)
			self.logic = function(self) end	-- brain dead as well
			start=false
		end
		timer = timer-self.dtime
		if timer < 0 then self.object:remove() end
	end
	kitz.queue_high(self,func,100)
end

function kitz.hq_attack(self,prty,tgtobj)
	local func = function(self)
		if not kitz.is_alive(tgtobj) then return true end
		if kitz.is_queue_empty_low(self) then
			local pos = kitz.get_stand_pos(self)
--			local tpos = tgtobj:get_pos()
			local tpos = kitz.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if dist > 3 then
				return true
			else
				kitz.lq_turn2pos(self,tpos)
				local height = tgtobj:is_player() and 0.35 or tgtobj:get_luaentity().height*0.6
				if tpos.y+height>pos.y then
					kitz.lq_jumpattack(self,tpos.y+height-pos.y,tgtobj)
				else
					kitz.lq_dumbwalk(self,kitz.pos_shift(tpos,{x=random()-0.5,z=random()-0.5}))
				end
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_liquid_recovery(self,prty)	-- scan for nearest land
	local radius = 1
	local yaw = 0
	local func = function(self)
		if not self.isinliquid then return true end
		local pos=self.object:get_pos()
		local vec = minetest.yaw_to_dir(yaw)
		local pos2 = kitz.pos_shift(pos,vector.multiply(vec,radius))
		local height, liquidflag = kitz.get_terrain_height(pos2)
		if height and not liquidflag then
			kitz.hq_swimto(self,prty,pos2)
			return true
		end
		yaw=yaw+pi*0.25
		if yaw>2*pi then
			yaw = 0
			radius=radius+1
			if radius > self.view_range then
				kitz.hurt(self, self.hp, "stuck in liquid")
				return true
			end
		end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_swimto(self,prty,tpos)
	local box = self.object:get_properties().collisionbox
	local cols = {}
	local func = function(self)
		if not self.isinliquid then
			if self.isonground then return true end
			return false
		end

		local pos = kitz.get_stand_pos(self)
		local y=self.object:get_velocity().y
		local pos2d = {x=pos.x,y=tpos.y,z=pos.z}
		local dir=vector.normalize(vector.direction(pos2d,tpos))
		local yaw = minetest.dir_to_yaw(dir)

		if kitz.timer(self,1) then
			cols = kitz.get_box_displace_cols(pos,box,dir,1)
			for _,p in ipairs(cols[1]) do
				p.y=pos.y
				local h = kitz.get_terrain_height(p)
				if h and h>pos.y and self.isinliquid then
					kitz.lq_freejump(self)
					break
				end
			end
		elseif kitz.turn2yaw(self,yaw) then
			dir.y = y
			self.object:set_velocity(dir)
		end
	end
	kitz.queue_high(self,func,prty)
end

---------------------
-- AQUATIC
---------------------

-- MACROS
local function aqua_radar_dumb(pos,yaw,range,reverse)
	range = range or 4

	local function okpos(p)
		local node = kitz.nodeatpos(p)
		if node then
			if node.drawtype == 'liquid' then
				local nodeu = kitz.nodeatpos(kitz.pos_shift(p,{y=1}))
				local noded = kitz.nodeatpos(kitz.pos_shift(p,{y=-1}))
				if (nodeu and nodeu.drawtype == 'liquid') or (noded and noded.drawtype == 'liquid') then
					return true
				else
					return false
				end
			else
				local h = kitz.get_terrain_height(p)
				if h then
					local node2 = kitz.nodeatpos({x=p.x,y=h+1.99,z=p.z})
					if node2 and node2.drawtype == 'liquid' then return true, h end
				else
					return false
				end
			end
		else
			return false
		end
	end

	local fpos = kitz.pos_translate2d(pos,yaw,range)
	local ok,h = okpos(fpos)
	if not ok then
		local ffrom, fto, fstep
		if reverse then
			ffrom, fto, fstep = 3,1,-1
		else
			ffrom, fto, fstep = 1,3,1
		end
		for i=ffrom, fto, fstep  do
			local ok,h = okpos(kitz.pos_translate2d(pos,yaw+i,range))
			if ok then return yaw+i,h end
			ok,h = okpos(kitz.pos_translate2d(pos,yaw-i,range))
			if ok then return yaw-i,h end
		end
		return yaw+pi,h
	else
		return yaw, h
	end
end

function kitz.is_in_deep(target)
	if not target then return false end
	local nodepos = kitz.get_stand_pos(target)
	local node1 = kitz.nodeatpos(nodepos)
	nodepos.y=nodepos.y+1
	local node2 = kitz.nodeatpos(nodepos)
	nodepos.y=nodepos.y-2
	local node3 = kitz.nodeatpos(nodepos)
	if node1 and node2 and node3 and node1.drawtype=='liquid' and (node2.drawtype=='liquid' or node3.drawtype=='liquid') then
		return true
	end
end

-- HQ behaviors

function kitz.hq_aqua_roam(self,prty,speed)
	local tyaw = 0
	local init = true
	local prvscanpos = {x=0,y=0,z=0}
	local center = self.object:get_pos()
	local func = function(self)
		if init then
			kitz.animate(self,'def')
			init = false
		end
		local pos = kitz.get_stand_pos(self)
		local yaw = self.object:get_yaw()
		local scanpos = kitz.get_node_pos(kitz.pos_translate2d(pos,yaw,speed))
		if not vector.equals(prvscanpos,scanpos) then
			prvscanpos=scanpos
			local nyaw,height = aqua_radar_dumb(pos,yaw,speed,true)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+1
				self.object:set_velocity(vel)
			end
			if yaw ~= nyaw then
				tyaw=nyaw
				kitz.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end
		if kitz.timer(self,1) then
			if vector.distance(pos,center) > abr*16*0.5 then
				tyaw = minetest.dir_to_yaw(vector.direction(pos,{x=center.x+random()*10-5,y=center.y,z=center.z+random()*10-5}))
			else
				if random(10)>=9 then tyaw=tyaw+random()*pi - pi*0.5 end
			end
		end

		kitz.turn2yaw(self,tyaw,3)
--		local yaw = self.object:get_yaw()
		kitz.go_forward_horizontal(self,speed)
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_aqua_turn(self,prty,tyaw,speed)
	local func = function(self)
		local finished=kitz.turn2yaw(self,tyaw)
--		local yaw = self.object:get_yaw()
		kitz.go_forward_horizontal(self,speed)
		if finished then return true end
	end
	kitz.queue_high(self,func,prty)
end

function kitz.hq_aqua_attack(self,prty,tgtobj,speed)
	local tyaw = 0
	local prvscanpos = {x=0,y=0,z=0}
	local init = true
	local tgtbox = tgtobj:get_properties().collisionbox
	local func = function(self)
		if not kitz.is_alive(tgtobj) then return true end
		if init then
			kitz.animate(self,'fast')
			kitz.play_sound(self,'attack')
			init = false
		end
		local pos = kitz.get_stand_pos(self)
		local yaw = self.object:get_yaw()
		local scanpos = kitz.get_node_pos(kitz.pos_translate2d(pos,yaw,speed))
		if not vector.equals(prvscanpos,scanpos) then
			prvscanpos=scanpos
			local nyaw,height = aqua_radar_dumb(pos,yaw,speed*0.5)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+1
				self.object:set_velocity(vel)
			end
			if yaw ~= nyaw then
				tyaw=nyaw
				kitz.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end

		local tpos = tgtobj:get_pos()
		local tyaw=minetest.dir_to_yaw(vector.direction(pos,tpos))
		kitz.turn2yaw(self,tyaw,3)
		yaw = self.object:get_yaw()
		if kitz.timer(self,1) then
			if not kitz.is_in_deep(tgtobj) then return true end
			local vel = self.object:get_velocity()
			if tpos.y>pos.y+0.5 then self.object:set_velocity({x=vel.x,y=vel.y+0.5,z=vel.z})
			elseif tpos.y<pos.y-0.5 then self.object:set_velocity({x=vel.x,y=vel.y-0.5,z=vel.z}) end
		end
		if kitz.is_pos_in_box(kitz.pos_translate2d(pos,yaw,self.attack.range),tpos,tgtbox) then	--bite
			tgtobj:punch(self.object,1,self.attack)
			kitz.hq_aqua_turn(self,prty,yaw-pi,speed)
			return true
		end
		kitz.go_forward_horizontal(self,speed)
	end
	kitz.queue_high(self,func,prty)
end
