local PANEL = {
    PanelManager = nil
};

--[[
    Description:
    Panel manager initialization
--]]
function PANEL:Init()

    self.PanelManager = DFCL:New( self:GetName() );

    self.PanelManager:AddMouseClickListener();
    self.PanelManager:AddContextMenuListener();

    self.PanelManager:AddPanel( self, true );

    timer.Simple( 0.3, function()

        local panels = self:GetChildren();

        for _, panel in pairs( panels ) do
            self.PanelManager:AddPanel( panel );
        end;

    end );

end;

--[[
    Description:
    Activates the synchronization of the panel manager and the children of the main panel
    --------------
    @param (Float : 1) sync_time - Sync refresh rate in seconds
--]]
function PANEL:ChildSync( sync_time )

    sync_time = sync_time or 1;
    
    local PanelEventName = self.PanelManager:GetEventName();
    local SyncEventName = PanelEventName .. "_ChildrenSync";

    timer.Create( SyncEventName, sync_time, 0, function()

        if ( not IsValid( self ) ) then return; end;

        local panels = self:GetChildren();
        local panelsExists = self.PanelManager:GetPanels();
        
        for _, panel in pairs( panels ) do
            if ( not table.HasValue( panelsExists, panel ) ) then
                self.PanelManager:AddPanel( panel );
            end;
        end;

    end );

    hook.Add( "DFCL_Destruct_" .. PanelEventName, SyncEventName, function()

        if ( timer.Exists( SyncEventName ) ) then
            timer.Remove( SyncEventName );
        end;

        hook.Remove( "DFCL_Destruct_" .. PanelEventName, SyncEventName );

    end );

end;

--[[
    Description:
    Adds focus tracking for a panel group with the specified name.
    If the context menu closes, the focus will return, provided that it was previously.
    --------------
    @param (String) panelName - Panel name (Example: "DTextEntry")
--]]
function PANEL:AddFocusName( panelName )
    self.PanelManager:AddFocusName( panelName );
end;

--[[
    Description:
    Deletes focus tracking for a panel group.
    --------------
    @param (String) panelName - Panel name (Example: "DTextEntry")
--]]
function PANEL:RemoveFocusName( panelName )
    self.PanelManager:RemoveFocusName( panelName );
end;

--[[
    Description:
    Adds focus tracking for a panel. If the context menu closes,
        the focus will return, provided that it was previously.
    --------------
    @param (Panel) panel - A panel object
--]]
function PANEL:AddFocusPanel( panel )
    self.PanelManager:AddFocusPanel( panel );
end;

--[[
    Description:
    Deletes focus tracking for a panel.
    --------------
    @param (Panel) panel - A panel object
--]]
function PANEL:RemoveFocusPanel( panel )
    self.PanelManager:RemoveFocusPanel( panel );
end;

--[[
    Description:
    Returns the panel manager
    --------------
    @return (Metatable) - Meta table panel manager
--]]
function PANEL:GetPanelManager()
    return self.PanelManager;
end;

--[[
    Description:
    Destroys the panel manager and all its dependencies
--]]
function PANEL:Destruct()
    self.PanelManager:Destruct();
end;

--[[
    Description:
    Destroys the panel manager and all its dependencies when closing the panel

    WARNING:
    When overloaded, the method will have to be called manually.
--]]
function PANEL:OnClose()
    self.PanelManager:Destruct();
end;

--[[
    Description:
    Destroys the panel manager and all its dependencies when removing a panel

    WARNING:
    When overloaded, the method will have to be called manually.
--]]
function PANEL:OnRemove()
    self.PanelManager:Destruct();
end;

vgui.Register( "DFrameContext", PANEL, "DFrame" )