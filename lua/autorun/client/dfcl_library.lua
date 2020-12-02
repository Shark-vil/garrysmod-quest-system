DFCL = {};

--[[
    Description:
    Creates a class object.
--]]
function DFCL:New( ui_name )

    ui_name = string.Replace( ui_name, ' ', '' );

    -- Private fields
    local private = {};
    
    private.mainPanel = {};     -- Main panel
    private.panels = {};        -- All registered panels
    private.focusPanels = {};   -- List of focus tracking panels
    private.focusNames = {};    -- List of focus tracking panels name
    private.ignorePanels = {};  -- Ignored panels when setting states
    private.eventName = ui_name .. "_" .. tostring( SysTime() );    -- Unique name for hooks
    private.contextMenuState = false;   -- Context menu status
    private.MakePopup = true;  -- Disables the state update method if false

    -- Public fields
    local public = {};

    --[[
        Description:
        Returns the main panel.
        --------------
        @return (Panel) - Main Panel
    --]]
    function public:GetMainPanel()
        return private.mainPanel;
    end;

    --[[
        Description:
        Sets whether to update the state through the main method or not.
        --------------
        @param (Boolean) status - Turns on the MakePopup if true
    --]]
    function public:EnableMakePopup( status )
        private.MakePopup = status;
    end;

    --[[
        Description:
        Returns the state of keystrokes (abbreviated method).
        --------------
        @param (Boolean) status - Will return the true if there is focus
    --]]
    function public:GetKeyboardState( panel )
        return panel:IsKeyboardInputEnabled();
    end;

    --[[
        Description:
        Returns the state of mouse clicks (shortened method).
        --------------
        @param (Boolean) status - Will return the true if there is focus
    --]]
    function public:GetMouseState( panel )
        return panel:IsMouseInputEnabled();
    end;

    --[[
        Description:
        Focuses the main panel and all the dependencies.
    --]]
    function public:MakePopup()
        if ( not private.MakePopup ) then
            return;
        end;

        local IgnoreStates = {};

        for _, panel in pairs( self:GetIgnorePanels() ) do
            local data = {
                object = panel,
                keyboardState = panel:IsKeyboardInputEnabled(),
                mouseState = panel:IsMouseInputEnabled()
            };
            table.insert( IgnoreStates, panel );
        end;

        private.mainPanel:MakePopup();

        for _, data in pairs( IgnoreStates ) do
            self:PanelState( data.object, data.keyboardState, data.mouseState );
        end;
    end;

    --[[
        Description:
        Registers the panel in the system.
        --------------
        @param (Panel) panel - Panel for registration in the system
        @param (Boolean : false) isMainPanel - Is this the main panel or not
    --]]
    function public:AddPanel( panel, isMainPanel )
        if ( not IsValid( panel ) ) then return; end;

        if ( isMainPanel ~= nil and isMainPanel ) then
            private.mainPanel = panel;
        end;

        table.insert( private.panels, panel );
    end;

    --[[
        Description:
        Removes a panel from the system.
        --------------
        @param (Panel) panel - Panel object to delete
    --]]
    function public:RemovePanel( panel )
        for i = 1, table.Count( private.panels ) do
            if ( private.panels[ i ] == panel ) then
                table.remove( private.panels, i );
                break;
            end;
        end;
    end;

    --[[
        Description:
        Adds focus tracking for a panel group with the specified name.
        If the context menu closes, the focus will return, provided that it was previously.
        --------------
        @param (String) panelName - Panel name (Example: "DTextEntry")
    --]]
    function public:AddFocusName( panelName )
        table.insert( private.focusNames, panelName );
    end;

    --[[
        Description:
        Deletes focus tracking for a panel group.
        --------------
        @param (String) panelName - Panel name (Example: "DTextEntry")
    --]]
    function public:RemoveFocusName( panelName )
        for i = 1, table.Count( private.focusNames ) do
            if ( private.focusNames[ i ] == panelName ) then
                table.remove( private.focusNames, i );
                break;
            end;
        end;
    end;

    --[[
        Description:
        Forcibly trying to set focus on the panel.
        --------------
        @param (Panel) panel - A panel object
    --]]
    function public:SetFocusPanel( panel )

        self:AddIgnorePanel( panel );
        self:MakePopup();
        panel:RequestFocus();
        self:RemoveIgnorePanel( panel );

    end;

    --[[
        Description:
        Adds focus tracking for a panel. If the context menu closes,
            the focus will return, provided that it was previously.
        --------------
        @param (Panel) panel - A panel object
    --]]
    function public:AddFocusPanel( panel )
        if ( not IsValid( panel ) ) then return; end;
        
        table.insert( private.focusPanels, panel );
    end;

    --[[
        Description:
        Deletes focus tracking for a panel.
        --------------
        @param (Panel) panel - A panel object
    --]]
    function public:RemoveFocusPanel( panel )
        for i = 1, table.Count( private.focusPanels ) do
            if ( private.focusPanels[ i ] == panel ) then
                table.remove( private.focusPanels, i );
                break;
            end;
        end;
    end;

    --[[
        Description:
        Adds a panel to the ignore list.
        --------------
        @param (Panel) panel - A panel object
    --]]
    function public:AddIgnorePanel( panel )
        if ( table.HasValue( private.ignorePanels, panel ) ) then
            return;
        end;
        
        table.insert( private.ignorePanels, panel );
    end;

    --[[
        Description:
        Check that the panel is in the ignored list.
        --------------
        @return (Boolean) - Returns true if the panel is in the ignored list
    --]]
    function public:IsIgnorePanel( panel )
        if ( table.HasValue( private.ignorePanels, panel ) ) then
            return true;
        end;
        return false;
    end;

    --[[
        Description:
        Get a list of ignored objects.
        --------------
        @return (Panel[]) - List of ignore panel objects
    --]]
    function public:GetIgnorePanels()
        return private.ignorePanels;
    end;

    --[[
        Description:
        Removes a panel from the ignored list.
        --------------
        @param (Panel) panel - A panel object
    --]]
    function public:RemoveIgnorePanel( panel )
        for i = 1, table.Count( private.ignorePanels ) do
            if ( private.ignorePanels[ i ] == panel ) then
                table.remove( private.ignorePanels, i );
                break;
            end;
        end;
    end;

    --[[
        Description:
        Returns the name for the hooks.
        --------------
        @return (String) - Name of hooks
    --]]
    function public:GetEventName()
        return private.eventName;
    end;

    --[[
        Description:
        Returns a list of registered panels.
        --------------
        @return (Panel[]) - List of panel objects
    --]]
    function public:GetPanels()
        return private.panels;
    end;

    --[[
        Description:
        Sets the state of the panel.
        --------------
        @param (Panel) panel - A panel object
        @param (Boolean) keyboard_state - Keyboard activity status
        @param (Boolean) mouse_state - Mouse activity status
    --]]
    function public:PanelState( panel, keyboard_state, mouse_state )
        if ( not IsValid( panel ) ) then return; end;

        if ( not table.HasValue( private.panels, panel ) ) then
            return;
        end;

        panel:SetKeyboardInputEnabled( keyboard_state );
        panel:SetMouseInputEnabled( mouse_state );
    end;

    --[[
        Description:
        Sets the state for the selected panel list.
        --------------
        @param (Panel[]) panels - List of panel objects
        @param (Boolean) keyboard_state - Keyboard activity status
        @param (Boolean) mouse_state - Mouse activity status
    --]]
    function public:PanelsState( panels, keyboard_state, mouse_state )
        for _, panel in pairs( panels ) do
            if ( not IsValid( panel ) ) then continue; end;

            if ( not table.HasValue( private.panels, panel ) ) then
                continue;
            end;

            panel:SetKeyboardInputEnabled( keyboard_state );
            panel:SetMouseInputEnabled( mouse_state );
        end;
    end;


    --[[
        Description:
        Sets the state for all panels.
        --------------
        @param (Boolean) keyboard_state - Keyboard activity status
        @param (Boolean) mouse_state - Mouse activity status
    --]]
    function public:PanelAllState( keyboard_state, mouse_state )
        for _, panel in pairs( private.panels ) do
            if ( not IsValid( panel ) ) then continue; end;

            if ( self:IsIgnorePanel( panel ) ) then
                continue;
            end;

            panel:SetKeyboardInputEnabled( keyboard_state );
            panel:SetMouseInputEnabled( mouse_state );
        end;
    end;

    --[[
        Description:
        Resets the state of panels.
    --]]
    function public:PanelStateReset()
        self:MakePopup();
        self:PanelAllState( false, false );
    end;

    --[[
        Description:
        Returns the status of the context menu.
        --------------
        @return (Boolean) - Will return true if the context menu is open
    --]]
    function public:ContextMenuIsOpen()
        return private.contextMenuState;
    end;

    --[[
        Description:
        Destroys an object of a class and its dependencies.
    --]]
    function public:Destruct()
        self:RemoveMouseClickListener();
        self:RemoveContextMenuListener();

        hook.Run( "DFCL_Destruct_" .. private.eventName );

        self = nil;
    end;

    --[[
        Description:
        Calls the destruction method if the menu does not exist.
        --------------
        @return (Boolean) - Will return the true in case of destruction
    --]]
    function public:DestructInvalidMenu()
        
        if ( not IsValid( private.mainPanel ) ) then
            self:Destruct();
            return true;
        end;

        return false;

    end;

    --[[
        Description:
        Adds a mouse click listener to control the state of panels.
    --]]
    function public:AddMouseClickListener()
        hook.Add( "GUIMouseReleased", private.eventName, function( mouseCode, aimVector )

            if ( public:DestructInvalidMenu() ) then return; end;

            if ( private.contextMenuState ) then
                public:MakePopup();
                public:PanelAllState( false, true );
            else
                public:PanelStateReset();
            end;
        end );
    end;


    --[[
        Description:
        Removes a mouse click listener.
    --]]
    function public:RemoveMouseClickListener()
        hook.Remove( "GUIMouseReleased", private.eventName );
    end;

    --[[
        Description:
        Adds a context menu listener to control the state of panels.
    --]]
    function public:AddContextMenuListener()
        hook.Add( "OnContextMenuOpen", private.eventName, function()
            
            if ( public:DestructInvalidMenu() ) then return; end;

            timer.Simple( 0.1, function()
                public:MakePopup();
                public:PanelAllState( false, true );
            end );
            
            private.contextMenuState = true;

        end );
    
        hook.Add( "OnContextMenuClose", private.eventName, function()

            if ( public:DestructInvalidMenu() ) then return; end;

            local focusPanels = {};

            for _, panel in pairs( private.focusPanels ) do
                if ( not IsValid( panel ) or not panel:HasFocus() ) then 
                    continue; 
                end;

                table.insert( focusPanels, panel );
            end;

            for _, panel in pairs( private.panels ) do
                if ( not IsValid( panel ) or not panel:HasFocus() ) then 
                    continue; 
                end;

                if ( table.HasValue( private.focusNames, panel:GetName() ) ) then
                    table.insert( focusPanels, panel );
                end;
            end;

            public:PanelStateReset()
            private.contextMenuState = false;

            timer.Simple( 0.1, function()
                for _, panel in pairs( focusPanels ) do
                    public:SetFocusPanel( panel );
                end;
            end );

        end );
    end;

    --[[
        Description:
        Deletes the context menu listener.
    --]]
    function public:RemoveContextMenuListener()
        hook.Remove( "OnContextMenuOpen", private.eventName );
        hook.Remove( "OnContextMenuClose", private.eventName );
    end;

    setmetatable( public, self );
    self.__index = self;
    
    return public;
end;