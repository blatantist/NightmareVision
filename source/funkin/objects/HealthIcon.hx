package funkin.objects;

import flixel.FlxSprite;

import funkin.game.IUiSprite;

@:nullSafety
class HealthIcon extends FlxSprite implements IUiSprite
{
	/**
	 * Optional parented sprite
	 * 
	 * If set `this` will follow the set parents position
	 */
	public var sprTracker:Null<FlxSprite> = null;
	
	/**
	 * Additional offsets for the icon
	 * 
	 * Used when `sprTracker` is not null.
	 */
	public var sprOffsets(default, null):FlxPoint = FlxPoint.get(10, 0);
	
	/**
	 * The icons current character name
	 */
	public var characterName(default, null):String = '';
	
	@:allow(funkin.states.editors.ChartEditorState)
	var updateOffset:Bool = true;
	
	/**
	 * Size every icon is drawn at, whatever resolution its graphic is authored at
	 */
	public static inline var ICON_SIZE:Float = 150;
	
	/**
	 * Size this icon is drawn at. Defaults to `ICON_SIZE`; menus that want a smaller icon set it
	 * rather than scaling the sprite, so the tracker offsets stay correct.
	 */
	public var size(default, set):Float = ICON_SIZE;
	
	function set_size(value:Float):Float
	{
		size = value;
		if (characterName != '') changeIcon(characterName, true);
		return value;
	}
	
	var iconOffsets:Array<Float> = [0, 0];
	
	/**
	 * Used to decide if the icon will be flipped
	 */
	var isPlayer:Bool = false;
	
	/** 
	 * Used for dividing icon based on how many frames it has
	**/
	public var frameCount(default, set):Int = 2;
	
	public var alphaMultipler(default, set):Float = 1;
	
	function set_alphaMultipler(v:Float):Float
	{
		alphaMultipler = FlxMath.bound(v, 0, 1);
		set_alpha(alpha);
		return alphaMultipler;
	}
	
	override function set_alpha(v:Float)
	{
		v = FlxMath.bound(v, 0, 1);
		v *= alphaMultipler;
		return super.set_alpha(v);
	}
	
	public function set_frameCount(value:Int)
	{
		frameCount = value;
		changeIcon(characterName, true);
		
		return value;
	}
	
	/**
	 * Bool that controls whether or not the frame setting is handled automatically
	**/
	public var updateFrames:Bool = true;
	
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		// Centre on the tracked sprite rather than leaning on a magic offset that only lined up at
		// one icon size (the old -30 was exactly this for a 150px icon on a 90px tall row).
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + sprOffsets.x,
			sprTracker.y + ((sprTracker.height - height) * 0.5) + sprOffsets.y);
	}
	
	/**
	 * Attempts to load a new icon by file name
	 */
	public function changeIcon(char:String, forced:Bool = false):HealthIcon
	{
		if (this.characterName == char && !forced) return this;
		
		this.characterName = char;
		
		var name:String = '${Paths.UI_PREFIX}icons/$char';
		if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-' + char; // Older versions of psych engine's support
		if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-face'; // Prevents crash from missing icon
		if (!Paths.fileExists('images/' + name + '.png')) name = 'UI/icons/icon-face'; // ultimate fallback incase icon-face doesnt exist in ur custom UI folder
		
		final graphic = Paths.image(name, null, false);
		
		loadGraphic(graphic, true, Math.floor(graphic.width / frameCount), Math.floor(graphic.height));
		
		// Icons authored above the standard size (album art, for instance) are scaled here rather
		// than being downsampled on disk, so the source stays available for larger UI.
		final iconScale:Float = size / frameHeight;
		scale.set(iconScale, iconScale);
		
		iconOffsets[0] = ((frameWidth * iconScale) - size) / 2;
		iconOffsets[1] = ((frameWidth * iconScale) - size) / 2;
		updateHitbox();
		
		var c = [];
		for (i in 0...frameCount)
			c.push(i);
			
		animation.add(char, c, 0, false, isPlayer);
		animation.play(char); // i do plan on adding more functionality to icons at a later date
		
		antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
		
		return this;
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		
		// ADD to the offset super just set — it carries the compensation for scaling about the
		// frame centre (-0.5 * (width - frameWidth)). Overwriting it threw that away, which only
		// went unnoticed while every icon was 150px at scale 1 and the compensation was zero.
		if (updateOffset)
		{
			offset.x += iconOffsets[0];
			offset.y += iconOffsets[1];
		}
	}
	
	override function destroy()
	{
		sprOffsets = FlxDestroyUtil.put(sprOffsets);
		super.destroy();
	}
	
	/**
	 * Updates the current animation based on a value from 0 - 1.
	 */
	public inline function updateIconAnim(health:Float):Void
	{
		if (!updateFrames) return;
		
		animation.frameIndex = health < 0.2 ? 1 : 0;
	}
}
