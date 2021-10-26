local lang = slib.language({
	['default'] = {
		['name'] = 'Jar',
		['start'] = {
			'WHAT DO YOU WANT?!!!',
			'Put me back!',
			'Dont touch me!',
			'AAAAAAAAAAAAAAAAAAAAAAAAAAA!!!',
			'NO, NOT NECESSARY, LET GO!'
		},
	},
	['russian'] = {
		['name'] = 'Банка',
		['start'] = {
			'ТЕБЕ ЧЕГО НАДО?!!!',
			'Поставь меня обратно!',
			'Не трогай меня!',
			'ААААААААААААААААААААААААААА!!!',
			'НЕТ, НЕ НАДО, ОТПУСТИ!'
		},
	}
})

local conversation = {
	id = 'talking_bank',
	name = lang['name'],
	autoParent = true,
	isBackground = true,
	model = 'models/props_junk/PopCan01a.mdl',
	condition = function(ply, ent)
		if math.random(0, 10) ~= 0 then return false end
	end,
	steps = {
		start = {
			text = lang['start'],
			delay = 4,
			event = function(eDialogue)
				if CLIENT then
					eDialogue:VoiceSay('vo/coast/bugbait/sandy_help.wav')
				end
			end,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				eDialogue:Stop()
			end,
		}
	}
}

list.Set('QuestSystemDialogue', conversation.id, conversation)