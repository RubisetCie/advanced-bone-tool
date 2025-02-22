TOOL.Name = "#tool.adv_bone.name"
TOOL.Category = "Poser"

local IsValid = IsValid
local controlpanel = controlpanel
local vgui = vgui
local net = net

if CLIENT then
	language.Add("tool.adv_bone.name", "Advanced Bone Tool")
	language.Add("tool.adv_bone.desc", "Manipulate object's bones")
	language.Add("tool.adv_bone.0", "Click to select object, context menu to edit bones.")

	language.Add("tool.adv_bone.bone", "Bone")

	language.Add("tool.adv_bone.editangles", "Edit Angles")
	language.Add("tool.adv_bone.pitch", "Pitch")
	language.Add("tool.adv_bone.yaw", "Yaw")
	language.Add("tool.adv_bone.roll", "Roll")

	language.Add("tool.adv_bone.editposition", "Edit Position")
	language.Add("tool.adv_bone.editscale", "Edit Scale")
	language.Add("tool.adv_bone.x", "X")
	language.Add("tool.adv_bone.y", "Y")
	language.Add("tool.adv_bone.z", "Z")
	language.Add("tool.adv_bone.multi", "Multiplier")

	language.Add("tool.adv_bone.help", "Thank you for downloading this tool! <3 Th13teen")

	function UpdateAdvBoneMenu(ent, bone)
		if (IsValid(ent)) then
			--print("Updating list")

			local panel = controlpanel.Get("adv_bone")

			if (!IsValid(panel.combo_bonelist)) then
				return
			end

			local ang = ent:GetManipulateBoneAngles(bone) or angle_zero
			local pos = ent:GetManipulateBonePosition(bone) or vector_origin
			local scale = ent:GetManipulateBoneScale(bone) or Vector(1, 1, 1)

			panel.ent = ent

			panel.combo_bonelist:Clear()
			for i = 0, ent:GetBoneCount() - 1 do
				local name = ent:GetBoneName(i)
				if (name != "__INVALIDBONE__") then
					panel.combo_bonelist:AddChoice(name)
				end
			end

			local name = ent:GetBoneName(bone)
			if (name == "__INVALIDBONE__") then name = "static_prop" end
			panel.combo_bonelist:SetValue(name)

			panel.slider_ang_pitch:SetValue(ang.p)
			panel.slider_ang_yaw:SetValue(ang.y)
			panel.slider_ang_roll:SetValue(ang.r)

			panel.slider_pos_x:SetValue(pos.x)
			panel.slider_pos_y:SetValue(pos.y)
			panel.slider_pos_z:SetValue(pos.z)

			panel.slider_scale_x:SetValue(scale.x)
			panel.slider_scale_y:SetValue(scale.y)
			panel.slider_scale_z:SetValue(scale.z)
		end
	end

	net.Receive("UpdateAdvBoneMenu", function()
		local ent = net.ReadEntity()
		local bone = net.ReadFloat()
		UpdateAdvBoneMenu(ent, bone)
	end)

	local shouldGlow = false
	hook.Add("OnContextMenuOpen", "Advanced Bone Tool", function()
		local tool = LocalPlayer():GetTool()
		if (IsValid(tool)) then
			shouldGlow = (tool.Name == "Advanced Bone Tool")
		end
	end)

	hook.Add("OnContextMenuClose", "Advanced Bone Tool", function()
		shouldGlow = false
	end)

	hook.Add("PreDrawHalos", "Advanced Bone Tool", function()
		if (!shouldGlow) then return end
		local ply = LocalPlayer()
		local ent = ply:GetNWEntity("AdvBoneEntity")
		local col = ply:GetWeaponColor() * 255
		if (IsValid(ent)) then
			halo.Add({ent}, Color(col.r, col.g, col.b))
			halo.Add({ent}, Color(255, 255, 255, 100))
		end
	end)
else
	util.AddNetworkString("UpdateAdvBoneMenu")
	util.AddNetworkString("UpdateAdvBoneSettings")
	net.Receive("UpdateAdvBoneSettings", function()
		local data = net.ReadTable()
		local ent = data.ent
		if (!IsValid(ent)) then return end
		local bone = 0
		for i = 0, ent:GetBoneCount() - 1 do
			local name = ent:GetBoneName(i)
			if (name == data.bone) then
				bone = i
			end
		end
		ent:ManipulateBoneAngles(bone, data.ang)
		ent:ManipulateBonePosition(bone, data.pos)
		ent:ManipulateBoneScale(bone, data.scale)
	end)
end

function TOOL:SelectEntity(ent, physbone)
	if CLIENT then return true end
	if (IsValid(ent)) then
		if (IsValid(ent.AttachedEntity)) then ent = ent.AttachedEntity end
		self.Entity = ent
		self.Bone = self.Entity:TranslatePhysBoneToBone(physbone) or 0
		self:GetOwner():SetNWEntity("AdvBoneEntity", self.Entity)
		net.Start("UpdateAdvBoneMenu")
			net.WriteEntity(self.Entity)
			net.WriteFloat(self.Bone)
		net.Send(self:GetOwner())
	end
	return true
end

function TOOL:LeftClick(tr)
	-- Find entity that player is looking at.
	return self:SelectEntity(tr.Entity, tr.PhysicsBone)
end

function TOOL:RightClick(tr)
	-- Select Self.
	return self:SelectEntity(self:GetOwner(), 0)
end

function TOOL:BuildCPanel()
	local function UpdateBone()
		local panel = controlpanel.Get("adv_bone")
		local posmult = panel.slider_pos_multi:GetValue()
		local angmult = panel.slider_ang_multi:GetValue()
		local data = { ent = panel.ent,
					bone = panel.combo_bonelist:GetValue(),
					ang = Angle(panel.slider_ang_pitch:GetValue() * angmult, panel.slider_ang_yaw:GetValue() * angmult, panel.slider_ang_roll:GetValue() * angmult),
					pos = Vector(panel.slider_pos_x:GetValue() * posmult, panel.slider_pos_y:GetValue() * posmult, panel.slider_pos_z:GetValue() * posmult),
					scale = Vector(panel.slider_scale_x:GetValue(), panel.slider_scale_y:GetValue(), panel.slider_scale_z:GetValue()) }

		net.Start("UpdateAdvBoneSettings")
			net.WriteTable(data)
		net.SendToServer()
	end

	self.combo_bonelist = vgui.Create( "CtrlListBox", self )
	local combo_bonelistlabel = vgui.Create( "DLabel", self )
	combo_bonelistlabel:SetText( "#tool.adv_bone.bone" )
	combo_bonelistlabel:SetDark( true )
	self.combo_bonelist:SetValue("")
	self.combo_bonelist:SetHeight( 25 )
	self.combo_bonelist:Dock( TOP )
	self.combo_bonelist.ChooseOption = function(pnl, val)
		pnl:SetValue(val)
		local bone = 0
		local ent = LocalPlayer():GetNWEntity("AdvBoneEntity")
		for i = 0, ent:GetBoneCount() - 1 do
			local name = ent:GetBoneName(i)
			if (name == val) then
				bone = i
			end
		end
		UpdateAdvBoneMenu(ent, bone)
	end
	self:AddItem( combo_bonelistlabel, self.combo_bonelist )

	--Angles
	self:Help( "#tool.adv_bone.editangles" )

	self.slider_ang_pitch = self:NumSlider( "#tool.adv_bone.pitch", nil, -360, 360, 2 )
	self.slider_ang_pitch:SetValue(0)
	self.slider_ang_pitch:SetHeight(16)
	self.slider_ang_pitch.OnValueChanged = function() UpdateBone() end

	self.slider_ang_yaw = self:NumSlider( "#tool.adv_bone.yaw", nil, -360, 360, 2 )
	self.slider_ang_yaw:SetValue(0)
	self.slider_ang_yaw:SetHeight(16)
	self.slider_ang_yaw.OnValueChanged = function() UpdateBone() end

	self.slider_ang_roll = self:NumSlider( "#tool.adv_bone.roll", nil, -360, 360, 2 )
	self.slider_ang_roll:SetValue(0)
	self.slider_ang_roll:SetHeight(16)
	self.slider_ang_roll.OnValueChanged = function() UpdateBone() end

	self.slider_ang_multi = self:NumSlider( "#tool.adv_bone.multi", nil, -256, 256, 2 )
	self.slider_ang_multi:SetValue(1)
	self.slider_ang_multi.OnValueChanged = function() UpdateBone() end

	--Position
	self:Help( "#tool.adv_bone.editposition" )

	self.slider_pos_x = self:NumSlider( "#tool.adv_bone.x", nil, -512, 512, 2 )
	self.slider_pos_x:SetValue(0)
	self.slider_pos_x:SetHeight(16)
	self.slider_pos_x.OnValueChanged = function() UpdateBone() end

	self.slider_pos_y = self:NumSlider( "#tool.adv_bone.y", nil, -512, 512, 2 )
	self.slider_pos_y:SetValue(0)
	self.slider_pos_y:SetHeight(16)
	self.slider_pos_y.OnValueChanged = function() UpdateBone() end

	self.slider_pos_z = self:NumSlider( "#tool.adv_bone.z", nil, -512, 512, 2 )
	self.slider_pos_z:SetValue(0)
	self.slider_pos_z:SetHeight(16)
	self.slider_pos_z.OnValueChanged = function() UpdateBone() end

	self.slider_pos_multi = self:NumSlider( "#tool.adv_bone.multi", nil, -128, 128, 2 )
	self.slider_pos_multi:SetValue(1)
	self.slider_pos_multi.OnValueChanged = function() UpdateBone() end

	--Scale
	self:Help( "#tool.adv_bone.editscale" )

	self.slider_scale_x = self:NumSlider( "#tool.adv_bone.x", nil, -20, 20, 2 )
	self.slider_scale_x:SetValue(0)
	self.slider_scale_x:SetHeight(16)
	self.slider_scale_x.OnValueChanged = function() UpdateBone() end

	self.slider_scale_y = self:NumSlider( "#tool.adv_bone.y", nil, -20, 20, 2 )
	self.slider_scale_y:SetValue(0)
	self.slider_scale_y:SetHeight(16)
	self.slider_scale_y.OnValueChanged = function() UpdateBone() end

	self.slider_scale_z = self:NumSlider( "#tool.adv_bone.z", nil, -20, 20, 2 )
	self.slider_scale_z:SetValue(0)
	self.slider_scale_z:SetHeight(16)
	self.slider_scale_z.OnValueChanged = function() UpdateBone() end

	self.button_reset = vgui.Create( "DButton", self )
	self.button_reset:SetText("Reset")
	self.button_reset.DoClick = function()
		local panel = controlpanel.Get("adv_bone")

		panel.slider_ang_pitch:SetValue(0)
		panel.slider_ang_yaw:SetValue(0)
		panel.slider_ang_roll:SetValue(0)
		panel.slider_ang_multi:SetValue(1)

		panel.slider_pos_x:SetValue(0)
		panel.slider_pos_y:SetValue(0)
		panel.slider_pos_z:SetValue(0)
		panel.slider_pos_multi:SetValue(1)

		panel.slider_scale_x:SetValue(1)
		panel.slider_scale_y:SetValue(1)
		panel.slider_scale_z:SetValue(1)
	end
	self:AddPanel( self.button_reset )
end
