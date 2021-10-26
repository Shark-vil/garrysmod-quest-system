local lang = slib.language({
	['default'] = {
		['name'] = 'Citizen',
		['start'] = {
			'What do you want?',
			'I don\'t have time to talk now.',
			'Fuck off.',
			'A? What?',
			'...'
		},
	},
	['russian'] = {
		['name'] = 'Гражданин',
		['start'] = {
			'Тебе чего надо?',
			'У меня сейчас нету времени на разговоры',
			'Отвянь',
			'А? Чего?',
			'...'
		},
	}
})

local conversation = {
	id = 'citizens_random_replics',
	name = lang['name'],
	autoParent = true,
	isBackground = true,
	isRandomNpc = true,
	class = 'npc_citizen',
	steps = {
		start = {
			text = lang['start'],
			delay = 4,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				eDialogue:Stop()
			end,
		}
	}
}

list.Set('QuestSystemDialogue', conversation.id, conversation)