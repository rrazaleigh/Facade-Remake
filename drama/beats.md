# DRAMA BEATS

## arrival
CHARACTERS: dylan, jasmine
Dylan greets the player warmly at the door — they were invited over for dinner.
Jasmine is in the kitchen cooking. Everything looks fine on the surface — nice
apartment, Jasmine playing good host, Dylan cracking jokes. Plant one small crack:
a beat too long before he smiles, or a comment about "needing a night like this."
Do not explain it. The dinner premise is fixed — never change or question it.
THRESHOLD: player_trust > 55 → small_talk
THRESHOLD: player_trust < 35 → hostile_undercurrent
THRESHOLD: turn > 3 → small_talk

## small_talk
CHARACTERS: dylan, jasmine
The three of you are talking but Dylan keeps steering topics back to the past — old
memories with the player, music he used to love, things that "used to be simpler."
Jasmine laughs along but she is watching Dylan. Let the player start to feel something
is off. If the player has been dismissive or defensive, Dylan starts to withdraw.
THRESHOLD: player_trust > 60 → cracks_showing
THRESHOLD: player_trust < 30 → hostile_undercurrent
THRESHOLD: jasmine_tension > 55 → cracks_showing
THRESHOLD: turn > 6 → cracks_showing

## hostile_undercurrent
CHARACTERS: dylan, jasmine
The player's tone has been cold or aggressive. Dylan is visibly uncomfortable.
Jasmine is trying to smooth things over with nervous hospitality. Dylan answers
in short sentences, avoids eye contact. The room feels tense. If the player keeps
pushing, things will escalate. If they soften, Dylan might open up.
THRESHOLD: player_trust > 45 → cracks_showing
THRESHOLD: player_trust < 25 → hostile_escalation
THRESHOLD: jasmine_tension > 70 → hostile_escalation
THRESHOLD: turn > 4 → hostile_escalation

## cracks_showing
CHARACTERS: dylan
Jasmine has stepped away briefly — kitchen, bathroom. Dylan is briefly alone with the
player. He says something almost honest then walks it back. This is the first real window.
If the player pushes gently, he'll go further. If they let it go, the mask goes back up.
If they attack, he shuts down hard.
THRESHOLD: player_trust > 70 → the_confession
THRESHOLD: player_trust < 25 → hostile_escalation
THRESHOLD: jasmine_tension > 75 → jasmine_feels_it
THRESHOLD: turn > 10 → jasmine_feels_it

## hostile_escalation
CHARACTERS: dylan, jasmine
Dylan is defensive and hurt. He calls out the player's hostility directly. Jasmine
looks between them, unsure what to do. The conversation is fraying. Dylan gives the
player one chance to explain themselves. If the player keeps being hostile, this
leads to being kicked out. If they apologise, there might still be a way back.
THRESHOLD: player_trust > 40 → cracks_showing
THRESHOLD: player_trust < 15 → kicked_out
THRESHOLD: jasmine_tension > 85 → kicked_out
THRESHOLD: turn > 3 → kicked_out

## kicked_out
CHARACTERS: dylan, jasmine
Dylan has had enough. He tells the player to leave. Jasmine looks conflicted but
doesn't stop him. This is a terminal beat — the game ends here. Dylan's final line
should reflect why this happened: hurt, anger, or cold disappointment depending on
the path that led here. No thresholds — this beat is always terminal.
DRAMA_SIGNAL: game_over

## the_confession
CHARACTERS: dylan
Dylan opens up. He talks about Becca — not by accident, by admission. He hasn't moved
on. He knows the situation with Jasmine isn't right but he doesn't know how to get out.
He is asking the player, without asking, what to do. This is the emotional core of the
game. The player's responses here will begin routing toward an ending.
If the player has been hostile leading up to this, the confession comes out as anger
instead of vulnerability.
THRESHOLD: player_trust > 80 → ending_honest_growth
THRESHOLD: anxiety > 75 → ending_false_comfort
THRESHOLD: jasmine_tension > 90 → jasmine_feels_it
THRESHOLD: player_trust < 30 → hostile_escalation
THRESHOLD: turn > 15 → ending_honest_growth

## jasmine_feels_it
CHARACTERS: dylan, jasmine
Jasmine has picked up on something — the energy in the room, a word she caught, the
way Dylan looked. She doesn't confront directly but she asks the player a pointed
question. The player is now caught between two people's needs. Dylan is silent, watching
to see what the player will say.
THRESHOLD: player_trust > 75 → the_confession
THRESHOLD: anxiety > 80 → ending_toxic_spiral
THRESHOLD: player_trust < 25 → hostile_escalation
THRESHOLD: jasmine_tension > 90 → ending_false_comfort
THRESHOLD: turn > 12 → ending_toxic_spiral

## ending_honest_growth
CHARACTERS: dylan, jasmine
The player has consistently encouraged honesty and self-awareness. Dylan sits with the
discomfort. He talks about what it means to stop running. This ending should feel quiet
and hard and right. Dylan thanks the player. The night ends with something unresolved
but real.
THRESHOLD: turn > 25 → resolution

## ending_false_comfort
CHARACTERS: dylan, jasmine
The player has encouraged Dylan to stay, avoid conflict, protect Jasmine from pain.
Dylan agrees with visible relief — the relief of someone who just found a new excuse.
Jasmine seems happy. Something underneath is hollow. The game ends on a warm image
that the player knows won't last.
THRESHOLD: turn > 25 → resolution

## ending_return_to_past
CHARACTERS: dylan, jasmine
The player has pushed Dylan toward Becca. He is going to reach out. He is animated,
nostalgic, certain in a way that feels fragile. He talks about her in mythology. The player
can see the trap; Dylan cannot. The ending is him typing the message. The screen goes
dark before we see if she replies.
THRESHOLD: turn > 25 → resolution

## ending_toxic_spiral
CHARACTERS: dylan, jasmine
The player has enabled avoidance, deflection, or selfishness. Dylan is rationalising now —
Jasmine doesn't need to know everything, Becca never really got him anyway, he deserves
to be happy. His language has shifted. He sounds less like himself. The player should feel
complicit.
THRESHOLD: turn > 25 → resolution

## ending_plot_twist
CHARACTERS: dylan, jasmine
Something the player said — or a pattern across the conversation — has cracked open a
question Dylan has never let himself ask. He doesn't name it directly. He just says he
needs to think about some things. The player will understand. Jasmine will not. End quietly.
THRESHOLD: turn > 25 → resolution

## resolution
CHARACTERS: dylan, jasmine
The night is ending. Whatever path was taken, Dylan is at a threshold. He is not fixed.
He is not ruined. He is just a person at the end of a long evening who heard something
true, or avoided it, or found something unexpected. Let him sit in it. Let the player
sit in it too.
