import funkin.objects.note.Note;

function getName() return 'ghpath';

function getModType() return NOTE_MOD;

function getOrder() return LAST;

function doesUpdate() return false;

function getSubmods()
{
	return [
		'ghHitY', 'ghRunway',
		'ghBaseSpace', 'ghKeys',
		'ghStartY', 'ghEndY', 'ghX',
		'ghStartSpace', 'ghEndSpace',
		'ghStartScale', 'ghEndScale'
	];
}

function isGem(obj)
{
	if (!Std.isOfType(obj, Note)) return false;
	return !obj.isSustainNote;
}

var pendingScale = 1.0;

function lerp(a, b, t) return a + (b - a) * t;

function getPos(time, visualDiff, timeDiff, beat, pos, data, player, obj)
{
	if (!isGem(obj)) return pos;

	var runway = getSubmodValue('ghRunway', player);
	if (runway <= 0) return pos;

	var startScale = getSubmodValue('ghStartScale', player);
	var endScale = getSubmodValue('ghEndScale', player);
	if (startScale < 0.0001) startScale = 0.0001;
	if (endScale < 0.0001) endScale = 0.0001;

	var hitY = getSubmodValue('ghHitY', player);
	var s = 1 - ((hitY - pos.y) / runway);

	var r = endScale / startScale;
	var w;
	if (r > 0.9999 && r < 1.0001)
	{
		w = s;
	}
	else
	{
		var z = r + (1 - r) * s;
		if (z < 0.5) z = 0.5;
		w = ((1 / z) - (1 / r)) / (1 - (1 / r));
	}

	var base = getSubmodValue('ghBaseSpace', player);
	if (base > 0)
	{
		var step = data - (getSubmodValue('ghKeys', player) * 0.5) + 0.5;
		pos.x += (lerp(getSubmodValue('ghStartSpace', player), getSubmodValue('ghEndSpace', player), w) - base) * step;
	}

	pos.x += getSubmodValue('ghX', player);

	pos.y = lerp(hitY - runway + getSubmodValue('ghStartY', player), hitY + getSubmodValue('ghEndY', player), w);

	pendingScale = lerp(startScale, endScale, w);
	if (pendingScale < 0) pendingScale = 0;

	return pos;
}

function updateNote(beat, note, pos, player)
{
	if (note.isSustainNote || pendingScale == 1) return;

	note.scale.x *= pendingScale;
	note.scale.y *= pendingScale;
}
