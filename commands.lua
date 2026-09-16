local ccf = craft_conflict_finder

core.register_chatcommand("craft_conflicts", {
	func = function(name)
		ccf.ui.formspec():show(name)
	end,
})
