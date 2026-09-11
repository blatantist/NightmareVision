package funkin.backend.plugins;

import flixel.FlxBasic;

import funkin.input.Controls;

/**
 * Adds the bind of f11 to fullscreen.
 */
@:nullSafety
class FullScreenPlugin extends FlxBasic
{
	@:nullSafety(Off)
	static var instance:FullScreenPlugin;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new FullScreenPlugin());
			#if debug
			FlxG.console.registerClass(FullScreenPlugin);
			#end
		}
	}
	
	public function new()
	{
		super();
		this.visible = false;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (Controls.instance.FULLSCREEN)
		{
			// i was gonna change the actual key to fullscreen but thats like
			// really deep
			// like
			// lime/_backend/native/NativeApplication
			// just to modify it
			// so idk ig u have 2 options now
			
			FlxG.fullscreen = !FlxG.fullscreen;
		}
		
		if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		// sound tray only listens to keys so pad volume goes here
		if (Controls.instance.padJustPressed('volume_mute')) FlxG.sound.toggleMuted();
		if (Controls.instance.padJustPressed('volume_up')) FlxG.sound.changeVolume(0.1);
		if (Controls.instance.padJustPressed('volume_down')) FlxG.sound.changeVolume(-0.1);
	}
}
