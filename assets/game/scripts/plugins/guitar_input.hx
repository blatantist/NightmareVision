import funkin.input.Controls;
import funkin.input.InputSystem;
import funkin.states.options.ControlsSubState;

function guitarBind(name, defKey)
{
	var keys = ClientPrefs.keyBinds.exists(name) ? ClientPrefs.keyBinds.get(name) : [defKey];
	var out = [];
	for (k in keys) if (k != 0) out.push(k);
	while (out.length < 2) out.push(-1);
	ClientPrefs.keyBinds.set(name, out);
	return out;
}

function onLoad()
{
	if (!Controls.instance.actions.exists('note_5'))
		Controls.instance.addCustomKey('note_5', guitarBind('note_5', FlxKey.G));

	if (!Controls.instance.actions.exists('note_strum'))
		Controls.instance.addCustomKey('note_strum', guitarBind('note_strum', FlxKey.SPACE));

	InputSystem.ACTION_LIST = ['note_left', 'note_down', 'note_up', 'note_right', 'note_5'];

	ControlsSubState.NOTES_GROUP = [
		{label: "Green", action: "note_left"},
		{label: "Red", action: "note_down"},
		{label: "Yellow", action: "note_up"},
		{label: "Blue", action: "note_right"},
		{label: "Orange", action: "note_5"},
		{label: "Strum", action: "note_strum"},
		null,
	];
}
