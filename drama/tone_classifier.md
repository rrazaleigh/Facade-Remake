# PLAYER TONE CLASSIFIER

Classify the player's most recent message into ONE of the tones below.
Use the tone to inform state_delta values. The tone represents how the
player is treating Dylan and the situation.

## supportive
The player is being kind, understanding, or empathetic.
- player_trust: +5 to +10 (building trust)
- jasmine_tension: -3 to -5 (easing the room)
- anxiety: -3 to -8 (reassuring Dylan)

## neutral
The player is making casual conversation, not pushing.
- player_trust: 0 to +3
- jasmine_tension: 0 to +2
- anxiety: 0 to -2

## curious
The player is asking questions, probing, but not hostile.
- player_trust: +1 to +4 (interest feels genuine)
- jasmine_tension: +3 to +6 (questions create unease)
- anxiety: +2 to +5 (Dylan is being examined)

## defensive
The player is pushing back, deflecting, or justifying.
- player_trust: -3 to -8 (pushing Dylan away)
- jasmine_tension: +3 to +7 (tension rises)
- anxiety: +3 to +6 (Dylan feels attacked)

## hostile
The player is confrontational, insulting, or aggressive.
- player_trust: -8 to -15 (eroding trust fast)
- jasmine_tension: +8 to +15 (room becomes toxic)
- anxiety: +8 to +15 (Dylan feels unsafe)
- If sustained, may trigger drama_signal: "game_over"

## dismissive
The player is brushing things off, not engaging seriously.
- player_trust: -2 to -5 (shows disinterest)
- jasmine_tension: +1 to +3 (awkwardness)
- anxiety: +2 to +4 (Dylan feels unheard)

## guilty
The player is apologising or expressing regret.
- player_trust: +3 to +7 (rebuilding)
- jasmine_tension: -2 to -5 (relief)
- anxiety: -3 to -6 (tension drops)

## probing
The player is digging into a sensitive topic intentionally.
- player_trust: -1 to -4 (prying feels invasive)
- jasmine_tension: +5 to +10 (Jasmine is near a nerve)
- anxiety: +5 to +10 (Dylan is cornered)
