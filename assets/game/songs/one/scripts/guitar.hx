import funkin.objects.note.Note;
import funkin.backend.Conductor;
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxBackdrop;

var FRETS = 'UI/notes/guitar/frets';
var fretFor = ['fret1', 'fret2', 'fret3', 'fret2', 'fret1'];

var shader3D = newShader('gh3d');
var laneCamera:FlxCamera;
var gemCamera:FlxCamera;

// 3d lane position
var LANE_XROT = 1.24;
var LANE_ZPOS = 0.34;
var LANE_YPOS = 0.26;
var LANE_ZOOM = 0.92;
var LANE_CAM_HEIGHT_MULT = 1.75;
var laneExtra = 0;

// modchart position
var GEM_START_Y = 682.0;
var GEM_END_Y = -8.0;
var GEM_X = 2.0;
var GEM_START_SPACE = 43.0;
var GEM_END_SPACE = 116.0;
var GEM_START_SCALE = 0.35;
var GEM_END_SCALE = 1.0;

var HIGHWAY = 'UI/notes/guitar/highway';
var HW_WIDTH = 600.0;
var HW_X = 0.0;
var highway:FlxBackdrop;
var highwayTileH = 1.0;
var placedHighway = false;

var HW_REF_W = 512.0;
var SIDES = 'UI/notes/guitar/hw-sides';
var STRING = 'UI/notes/guitar/hw-string';
var MARK = 'UI/notes/guitar/hw-fretmarker';
var MARK_POOL = 16;

var SIDE_Y = 85.0;
var SIDE_H = 1.14;
var STR_Y = 10.0;
var STR_H = 1.74;
var STR_W = 0.8;
var STR_BRIGHT = 0.75;
var MARK_Y = 18.0;
var MARK_S_SCALE = 0.5;
var MARK_S_BRIGHT = 0.75;

// note spacing
var GEM_SPACING = 116.0;
var FRET_SPACING = 120.0;
var FRET_X = 2.0;
var HIT_SPACING = 120.0;
var HOLD_SPACING = 122.0;
var SUS_END_Y = 0.0;

// trail size
var SUS_SCALE = 0.62;
var ACT_SCALE = 0.90;

var SCORE_UI_X = 450.0;

var sidesSpr;
var stringSprs = [];
var marksL = [];
var marksS = [];
var needsSort = false;
var loweredNotes = false;

// per lane hold state. heldHead tracks which sustain is held
var holding = [false, false, false, false, false];
var susEnd = [0.0, 0.0, 0.0, 0.0, 0.0];
var heldHead = [null, null, null, null, null];
var springing = [false, false, false, false, false];

function preNoteGeneration()
{
	Note.swagWidth = GEM_SPACING;

	PlayState.instance.holdSubdivisions = 4;
}

function applyLaneOffsets(skin, keys)
{
	if (skin == null) return;

	var mid = (keys - 1) * 0.5;
	for (l in 0...keys)
	{
		var step = l - mid;
		if (skin.receptorOffsets != null) skin.receptorOffsets[l].x = -((FRET_SPACING - GEM_SPACING) * step + FRET_X);
		if (skin.splashOffsets != null) skin.splashOffsets[l].x = -(HIT_SPACING - GEM_SPACING) * step;
		if (skin.sustainSplashOffsets != null) skin.sustainSplashOffsets[l].x = -(HOLD_SPACING - GEM_SPACING) * step;
		if (skin.susEndOffsets != null) skin.susEndOffsets[l].y = SUS_END_Y;
	}
}

function buildLaneCamera()
{
	laneExtra = Std.int(FlxG.height * (LANE_CAM_HEIGHT_MULT - 1));

	laneCamera = new FlxCamera(0, -laneExtra, FlxG.width, FlxG.height + laneExtra);
	laneCamera.bgColor = 0x00000000;
	laneCamera.filters = [new ShaderFilter(shader3D)];
	laneCamera.scroll.y = -laneExtra;
	FlxG.cameras.insert(laneCamera, 1, false);

	gemCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
	gemCamera.bgColor = 0x00000000;
	FlxG.cameras.insert(gemCamera, 2, false);

	notes.cameras = [laneCamera];
}

function applyLane()
{
	shader3D.data.xrot.value = [LANE_XROT];
	shader3D.data.zpos.value = [LANE_ZPOS];
	shader3D.data.ypos.value = [LANE_YPOS];
	laneCamera.zoom = LANE_ZOOM;
}

function applyGemPath()
{
	var hl = hitlineY();

	modManager.setValue('ghHitY', hl);
	modManager.setValue('ghRunway', hl + laneExtra);
	modManager.setValue('ghBaseSpace', Note.swagWidth);
	modManager.setValue('ghKeys', modManager.keys);

	modManager.setValue('ghStartY', GEM_START_Y);
	modManager.setValue('ghEndY', GEM_END_Y);
	modManager.setValue('ghX', GEM_X);
	modManager.setValue('ghStartSpace', GEM_START_SPACE);
	modManager.setValue('ghEndSpace', GEM_END_SPACE);
	modManager.setValue('ghStartScale', GEM_START_SCALE);
	modManager.setValue('ghEndScale', GEM_END_SCALE);

	modManager.setValue('ghpath', 1);
}

function buildHighway()
{
	highway = new FlxBackdrop(Paths.image(HIGHWAY), 0x10);
	highway.cameras = [laneCamera];
	highway.scrollFactor.set();
	highway.setGraphicSize(Std.int(HW_WIDTH));
	highway.updateHitbox();
	highwayTileH = highway.height > 0 ? highway.height : 1;
	highway.x = ((FlxG.width - HW_WIDTH) * 0.5) + HW_X;
	add(highway);
}

function laneScale() return HW_WIDTH / HW_REF_W;

function hitlineY()
{
	var f = playFields.members[0];
	if (f == null) return FlxG.height * 0.8;
	var s = f.members[0];
	return (s == null) ? FlxG.height * 0.8 : s.y + (s.height * 0.5);
}

function laneCount()
{
	var f = playFields.members[0];
	return (f == null) ? 5 : f.members.length;
}

function newLanePart(img)
{
	var s = new FlxSprite(0, 0);
	s.loadGraphic(Paths.image(img));
	s.cameras = [laneCamera];
	s.antialiasing = true;
	add(s);
	return s;
}

function buildHighwayParts()
{
	sidesSpr = newLanePart(SIDES);

	for (i in 0...laneCount())
		stringSprs.push(newLanePart(STRING));

	for (i in 0...MARK_POOL)
	{
		var l = newLanePart(MARK);
		l.visible = false;
		marksL.push(l);

		var s = newLanePart(MARK);
		s.visible = false;
		marksS.push(s);
	}

	applyPartSizes();
}

function sizePart(s, w, h)
{
	s.setGraphicSize(Std.int(w), Std.int(h));
	s.updateHitbox();
	s.x = (FlxG.width * 0.5) + HW_X - (w * 0.5);
}

function applyPartSizes()
{
	var sc = laneScale();
	var hl = hitlineY();

	if (sidesSpr != null)
	{
		sizePart(sidesSpr, sidesSpr.frameWidth * sc, (hl + laneExtra) * SIDE_H);
		sidesSpr.y = hl - sidesSpr.height + SIDE_Y;
	}

	{
		var st = stringSprs[i];
		if (st == null) continue;

		sizePart(st, st.frameWidth * sc * STR_W, st.frameHeight * sc * STR_H);
		st.x = modManager.getBaseX(i, 0) - (st.width * 0.5);
		st.y = hl - st.height + STR_Y;
		st.setColorTransform(STR_BRIGHT, STR_BRIGHT, STR_BRIGHT, 1);
	}

	for (m in marksL) sizePart(m, m.frameWidth * sc, m.frameHeight * sc);
	for (m in marksS)
	{
		sizePart(m, m.frameWidth * sc, m.frameHeight * sc * MARK_S_SCALE);
		m.setColorTransform(MARK_S_BRIGHT, MARK_S_BRIGHT, MARK_S_BRIGHT, 1);
	}
}

function updateHighwayParts()
{
	var hl = hitlineY();
	var runway = hl + laneExtra;

	for (m in marksL) m.visible = false;
	for (m in marksS) m.visible = false;

	var li = 0;
	var si = 0;
	var b = Math.floor(Conductor.getBeat(Conductor.songPosition));
	var guard = 0;

	while (guard < 128)
	{
		var dist = (getNoteInitialTime(Conductor.beatToSeconds(b)) - Conductor.visualPosition) * songSpeed;
		if (dist > runway + 100) break;

		var yy = hl - dist;
		if (b >= 0 && yy <= hl + 20)
		{
			var m = null;
			if (b % Conductor.BEATS_PER_MEASURE == 0)
			{
				if (li < marksL.length) { m = marksL[li]; li++; }
			}
			else if (si < marksS.length) { m = marksS[si]; si++; }

			if (m != null)
			{
				m.visible = true;
				m.y = yy - m.height + MARK_Y;
			}
		}

		b++;
		guard++;
	}
}

function updateHighway()
{
	if (highway == null) return;

	var off = (Conductor.visualPosition * songSpeed) % highwayTileH;
	if (off < 0) off += highwayTileH;
	highway.y = off - highwayTileH;
}

function onCreatePost()
{
	modManager.setValue('transformY', 20);

	for (field in playFields)
	{
		field.noteSplashes = true; // engine default is off

		applyLaneOffsets(field._skin, field.members.length);

		for (lane in 0...field.members.length)
		{
			var strum = field.members[lane];
			strum.texture = FRETS;
			strum.flipX = (lane == 3 || lane == 4); // frets 4 & 5 are 1 & 2 mirrored

			strum.animation.addByIndices('confirm', fretFor[lane] + '000', [0, 1, 2, 3, 4, 5], '', 36, false);
			strum.animation.addByIndices('held', fretFor[lane] + '000', [0], '', 24, false);

			strum.playAnim('static', true);
			strum.resetAnim = 0;
		}
	}

	buildLaneCamera();
	buildHighway();
	buildHighwayParts();
	applyLane();
	applyGemPath();
}

{
	if (ratingGraphic != null) ratingGraphic.x += SCORE_UI_X;

	if (ratingNumGroup != null)
	{
		for (n in ratingNumGroup.members)
			if (n != null && n.alive) n.x += SCORE_UI_X;
	}
}

function onSpawnNote(note)
{
	needsSort = true;

	if (note == null) return;

	note.cameras = note.isSustainNote ? [laneCamera] : [gemCamera];

	{
		var want = 'scroll';
		if (note.noteType == 'Tap') want = 'scrollTap';
		else if (note.noteType == 'HOPO') want = 'scrollHopo';

		if (note.animation.exists(want) && note.animation.name != want) note.playAnim(want, true);
	}
	else
	{
		var s = note.skin.noteScale * SUS_SCALE;
		note.scale.x = s;
		if (note.isSustainEnd) note.scale.y = s;
	}
}

function onSpawnNoteSplash(splash, note)
{
	splash.rgbGraphics.enabled = false;
	splash.alpha = 0.8;
}

function onSpawnSustainSplash(splash, note)
{
	splash.rgbGraphics.enabled = false;
}

function noteHasSustain(note) return note.isSustainNote || note.sustainLength > 0;

function goodNoteHit(note, id)
{
	if (!noteHasSustain(note)) return;

	var lane = note.noteData;
	var strum = note.playField.members[lane];
	if (strum == null) return;

	strum.playAnim('held', true);
	strum.resetAnim = 0;

	var head = (note.isSustainNote && note.parent != null) ? note.parent : note;

	holding[lane] = true;
	heldHead[lane] = head;
	susEnd[lane] = head.strumTime + head.sustainLength;
}

function onInputRelease(key)
{
	if (holding[key] || springing[key]) springBack(key);
}

function springBack(lane)
{
	holding[lane] = false;
	heldHead[lane] = null;
	springing[lane] = true;

	for (field in playFields)
	{
		var strum = field.members[lane];
		if (strum != null)
		{
			strum.playAnim('confirm', true);
			strum.resetAnim = 0;
		}
	}
}

function onUpdatePost(elapsed)
{
	for (field in playFields)
	{
		for (lane in 0...field.members.length)
		{
			var strum = field.members[lane];
			strum.rgbGraphics.enabled = true; // stock disables the shader on 'static'

			if (holding[lane] && Conductor.songPosition >= susEnd[lane]) springBack(lane);
			if (springing[lane] && strum.animation.name == 'confirm' && strum.animation.finished) springing[lane] = false;
		}
	}

	for (note in notes)
	{
		if (note == null || !note.exists || !note.alive || !note.isSustainNote) continue;

		var head = (note.parent != null) ? note.parent : note;
		var lit = holding[note.noteData] && heldHead[note.noteData] == head;
		var missed = note.tooLate || head.tooLate || (note.tailState != null && note.tailState.missed);

		var base = note.isSustainEnd ? 'holdend' : 'hold';
		var want = missed ? base + 'Miss' : (lit ? base + 'Press' : base);

		if (note.animation.name != want)
		{
			var s = note.skin.noteScale * (lit ? ACT_SCALE : SUS_SCALE);
			note.scale.x = s;
			if (note.isSustainEnd) note.scale.y = s;

			note.playAnim(want, true);
		}

		if (missed && note.alpha != 1)
		{
			note.alpha = 1;
			note.alphaMod = 1;
		}
	}

	if (needsSort)
	{
		needsSort = false;
		notes.sort(function(order, a, b) return (a.isSustainNote ? 0 : 1) - (b.isSustainNote ? 0 : 1), 1);
	}

	if (!loweredNotes && members.indexOf(notes) > -1 && members.indexOf(playFields) > -1)
	{
		loweredNotes = true;
		remove(notes, true);
		insert(members.indexOf(playFields), notes);
	}

	if (loweredNotes && !placedHighway && highway != null && members.indexOf(notes) > -1)
	{
		placedHighway = true;

		var parts = [highway, sidesSpr];
		for (m in marksS) parts.push(m);
		for (m in marksL) parts.push(m);
		for (st in stringSprs) parts.push(st);

		for (part in parts)
		{
			remove(part, true);
			insert(members.indexOf(notes), part);
		}

		applyPartSizes();
		applyGemPath();
	}

	updateHighway();
	updateHighwayParts();
}
