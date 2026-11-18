import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, 'content.json'), encoding='utf-8'))
keep = ['ReadingTexts', 'Headlines', 'StealWords', 'StealTricky', 'CommentWords', 'Posts', 'ReactionYoutuber', 'Library', 'Theater',
        'GateQuestions', 'Glasses', 'Jobs', 'Diagnoses', 'LabExperiments', 'Inventions', 'Videos', 'HomeworkMistakes', 'Testimony',
        'Projects', 'SpaceGates', 'SmartestHeadlines']
sub = {k: d[k] for k in keep}
s = open(os.path.join(HERE, 'game.src.html'), encoding='utf-8').read()
junk = "if(S.path==='Lose'&&S.emb>0&&!$('panelWrap').classList.contains('hide')===false){}"
s = s.replace(junk, '')
s = s.replace('/*CONTENT*/null', json.dumps(sub, ensure_ascii=False).replace('</', '<\\/'))
open(os.path.join(HERE, '..', 'lose-a-brain-cell-web.html'), 'w', encoding='utf-8').write(s)
print(len(s))
