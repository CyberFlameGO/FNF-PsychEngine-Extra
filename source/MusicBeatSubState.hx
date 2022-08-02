package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class MusicBeatSubState extends FlxSubState
{
	public var resetCameraOnClose:Bool = false;
	var lastScroll:FlxPoint = FlxPoint.get();
	public function new()
	{
		lastScroll.copyFrom(FlxG.camera.scroll);
		super();
		closeCallback = onClose;
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(PlayState.SONG, Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	function onClose() {
		if (resetCameraOnClose) {
			FlxG.camera.follow(null);
			FlxG.camera.scroll.set();
		}

		lastScroll = FlxDestroyUtil.put(lastScroll);
	}
}
