# PLAYER INTENT CLASSIFIER

Evaluate the player's message in three sequential stages. Each stage feeds into the next. Combine all three to determine the final state delta.

## STAGE 1: INTENT — what is the player trying to do

Classify the player's primary intent. Use the definitions and indicators below. If multiple intents fit, apply the PRECEDENCE RULE. If confidence in any single intent is below 0.60, classify as Neutral.

### Confdence Rule
Assign a confidence score 0.00–1.00 for the selected intent. If confidence < 0.60, override to Neutral regardless of indicators.

### Precedence Rule (for overlapping intent)
When multiple intents are present, the highest-precedence intent wins regardless of order of appearance:
Hostile > Guilty > Defensive > Probing > Supportive > Curious > Dismissive > Neutral

### Hostile
Definition: The player is confrontational, insulting, or deliberately aggressive. They want to provoke, attack, or drive a wedge.
Indicators: Insults, raised-language accusations, swearing at a person, sarcastic put-downs, threats, telling someone to leave, mocking.
State deltas — Low: trust -1 to -2, hostility +1 to +2, anxiety +1 to +2, hope -1, patience -1
              Medium: trust -3 to -5, hostility +3 to +5, anxiety +2 to +4, hope -1 to -2, patience -2 to -3
              High: trust -5 to -7, hostility +5 to +7, anxiety +4 to +6, hope -3 to -4, patience -4 to -6

### Guilty
Definition: The player is apologising, expressing regret, or taking blame. They want to make amends or show remorse.
Indicators: "I'm sorry", "I shouldn't have", "my fault", apologetic tone, self-blame, asking for forgiveness, acknowledging hurt.
State deltas — Low: trust +1 to +2, hope +1, hostility -1, anxiety -1, suspicion -1
              Medium: trust +2 to +4, hope +1 to +2, hostility -1 to -2, anxiety -2 to -3, suspicion -1 to -2
              High: trust +4 to +6, hope +3 to +4, hostility -3 to -4, anxiety -4 to -5, suspicion -3 to -4

### Defensive
Definition: The player is pushing back, justifying themselves, or deflecting blame. They feel accused and are protecting themselves.
Indicators: "That's not fair", "I didn't mean it", excuses, deflecting questions, turning blame back, minimising ("it's not that serious"), shutting down.
State deltas — Low: trust -1, hostility +1, anxiety +1 to +2, mask +1, patience -1
              Medium: trust -2 to -3, hostility +1 to +2, anxiety +2 to +3, mask +1 to +2, patience -1 to -2
              High: trust -4 to -5, hostility +3 to +4, anxiety +4 to +5, mask +2 to +3, patience -3 to -4

### Probing
Definition: The player is deliberately digging into a sensitive topic. They want information, truth, or a reaction — not casual curiosity but targeted inquiry.
Indicators: Repeated questions about the same topic, pushing after being deflected, asking about Becca directly, asking about feelings with clear intent, cornering someone with a question, "Why did you...", "Tell me about...".
State deltas — Low: suspicion +1, anxiety +1, trust -1, attachment +1
              Medium: suspicion +1 to +2, anxiety +2 to +3, trust -1 to -2, attachment +1
              High: suspicion +3 to +4, anxiety +4 to +5, trust -3 to -4, attachment +2

### Supportive
Definition: The player is being kind, understanding, empathetic, or reassuring. They want to help, comfort, or connect.
Indicators: "I understand", "that sounds hard", validating feelings, offering comfort, being patient, gentle follow-ups, expressing care.
State deltas — Low: trust +1 to +2, hope +1, anxiety -1, hostility -1 to 0, mask -1
              Medium: trust +2 to +4, hope +2 to +3, anxiety -2 to -3, hostility -1, mask -1 to -2
              High: trust +4 to +6, hope +3 to +4, anxiety -3 to -4, hostility -2, mask -2 to -3
Supportive NEVER increases hostility. Hostility delta is 0 or negative only.

### Curious
Definition: The player is asking questions from genuine interest, not pressure. They want to understand without forcing.
Indicators: Open-ended questions, "How are you?", "What happened?", casual curiosity, asking about the evening or past without pushing, interested but gentle.
State deltas — Low: trust +1, anxiety +1, suspicion +1, patience -1
              Medium: trust +1 to +2, anxiety +1 to +2, suspicion +1, patience -1
              High: trust +2 to +3, anxiety +2 to +3, suspicion +1 to +2, patience -2

### Dismissive
Definition: The player is brushing things off, avoiding engagement, or signalling disinterest. They don't want to deal with the emotional weight.
Indicators: Changing the subject, "It's fine", "Whatever", short uninterested replies, ignoring emotional cues, deflecting with humour or politeness, "Let's not talk about that".
State deltas — Low: trust -1, hope -1, anxiety +1, mask +1
              Medium: trust -1 to -2, hope -1, anxiety +1, mask +1, patience -1
              High: trust -2 to -3, hope -2, anxiety +2, mask +2, patience -1 to -2

### Neutral
Definition: The player is making casual conversation, greetings, or statements without strong emotional weight. No clear intent dominates.
Indicators: Small talk, greetings, observations about the room/food, "How was your day?", generic responses, statements of fact.
State deltas — Low: trust 0 to +1, anxiety 0 to -1
              Medium: trust +1, anxiety -1
              High: N/A — strong neutral is contradictory; treat as Low.
Neutral NEVER changes hostility, suspicion, patience, mask, attachment, or hope.

### TARGET BIAS (use with ALL intents)
If the player's message is directed primarily at one character, apply their state_deltas more heavily:
  - dylan: multiply his deltas by 1.5, Jasmine's by 0.5
  - jasmine: multiply her deltas by 1.5, Dylan's by 0.5
  - both: no multiplier
  - neither (self/general): apply all at 0.75x

## STAGE 2: TARGET — who is the player referencing

Determine the primary target of the player's message:

dylan:   Player addresses Dylan directly (uses his name, asks him a question, responds to him, talks about his past).
jasmine: Player addresses Jasmine directly (uses her name, asks her a question, responds to her).
both:    Player addresses both of them, or the topic involves both equally.
neither: Player talks about themselves, makes a general statement, or the target is unclear.

## STAGE 3: INTENSITY — how strongly is this being expressed

Determine the intensity level of the player's intent:

High:   Strong language, emotional charge, repeated emphasis, exclamation, heightened vocabulary, clear emotional investment.
Medium: Moderate language, some emotion but controlled, clear intent without overstatement.
Low:    Mild or tentative language, hedging, casual tone, low emotional investment.

## COMBINING THE THREE STAGES

Final process:
1. Identify INTENT from Stage 1 (apply precedence + confidence rule).
2. Identify TARGET from Stage 2.
3. Identify INTENSITY from Stage 3.
4. Apply TARGET BIAS to the selected intent's state delta ranges.
5. Pick a specific value within the final range (use your judgment based on context).
6. Output only the variables that changed in state_delta. All others default to 0 — omit them.
7. Output the resolved intent in the "player_intent" field of your JSON response.

### ZERO-DEFAULT RULE (CRITICAL)
Any state variable not listed in your selected intent's state deltas MUST be 0.
Do not add it to state_delta at all. Only include variables that actually change.
This applies especially to hostility — see rule below.

### HOSTILITY CONSTRAINT (CRITICAL)
Hostility delta must be:
  - Hostile intent:   positive (increases)
  - Guilty intent:    negative (decreases — player is remorseful)
  - Defensive intent: positive (player pushes back)
  - All other intents (Supportive, Curious, Probing, Dismissive, Neutral): 0
Do NOT increase hostility for Supportive, Curious, or Neutral player messages.
If the player is being kind or neutral, hostility does not rise.

The intent, target, and intensity are for your internal use only. Do not output them to the player. The player should never know you are classifying them.
