scommand.Create('qsystem_editor').OnServer(function(ply, cmd, args)
	if not IsValid(ply) then return end
	sgui.route('qsystem/editor', ply)
end).Access( { isAdmin = true } ).Register()
