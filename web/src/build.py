import json
d = json.load(open('content.json'))
keep = ['ReadingTexts', 'Headlines', 'StealWords', 'StealTricky', 'CommentWords', 'Posts', 'ReactionYoutuber', 'Library', 'Theater',
        'GateQuestions', 'Glasses', 'Jobs', 'Diagnoses', 'LabExperiments', 'Inventions', 'Videos', 'HomeworkMistakes', 'Testimony',
        'Projects', 'SpaceGates', 'SmartestHeadlines']
sub = {k: d[k] for k in keep}
s = open('game.src.html', encoding='utf-8').read()
junk = "if(S.path==='Lose'&&S.emb>0&&!$('panelWrap').classList.contains('hide')===false){}"
s = s.replace(junk, '')
s = s.replace('/*CONTENT*/null', json.dumps(sub, ensure_ascii=False).replace('</', '<\\/'))
open('/home/user/brain-cell-game/lose-a-brain-cell-web.html', 'w', encoding='utf-8').write(s)
print(len(s))
