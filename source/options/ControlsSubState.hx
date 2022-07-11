package options;

import StrumNote.StrumLine;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;

using StringTools;

class ControlsSubState extends MusicBeatSubState {
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';

	var optionShit:Array<Array<String>> = [
		['NOTES'],
		[''],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Key 1', 'debug_1'],
		['Key 2', 'debug_2']
	];

	var keyTexts:Array<Array<String>> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpInputs:Array<AttachedText> = [];
	private var grpInputsAlt:Array<AttachedText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new() {
		super();
		
		for (i in 1...Note.MAX_KEYS + 1) {
			keyTexts.push(['${i}K']);
		}

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var id = 2;
		for (txt in keyTexts) {
			optionShit.insert(id, txt);
			id++;
		}
		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length) {
			var isCentered:Bool = false;
			if (unselectableCheck(i, true)) {
				isCentered = true;
			}
			var isPress:Bool = (optionShit[i][0] == defaultKey);
			if (!isPress && optionShit[i].length < 2) {
				for (txt in keyTexts) {
					if (optionShit[i] == txt) {
						isPress = true;
					}
				}
			}

			var optionText:Alphabet = new Alphabet(0, (10 * i), optionShit[i][0], (!isCentered || isPress), false);
			optionText.isMenuItem = true;
			if (isCentered) {
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
				optionText.yAdd = -55;
			} else {
				optionText.forceX = 200;
			}
			optionText.yMult = 60;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (!isCentered) {
				addBindTexts(optionText, i);
			}
			if ((!isCentered || isPress) && curSelected < 0) curSelected = i;
		}
		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (!rebindingKey) {
			if (controls.UI_UP_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0)) {
				changeSelection(-1);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0)) {
				changeSelection(1);
				holdTime = 0;
			}

			var down = controls.UI_DOWN;
			var up = controls.UI_UP;
			if (down || up)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
				}
			}

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel != 0)) {
				changeAlt();
			}

			if (controls.BACK) {
				ClientPrefs.reloadControls();
				close();
				CoolUtil.playCancelSound();
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0) {
				if (optionShit[curSelected][0] == defaultKey) {
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					CoolUtil.playConfirmSound();
				} else {
					var match = false;
					for (i in keyTexts) {
						if (optionShit[curSelected] == i) {
							openSubState(new NoteBindingSubState(curSelected - 1));
							match = true;
						}
					}

					if (!match && !unselectableCheck(curSelected)) {
						bindingTime = 0;
						rebindingKey = true;
						if (curAlt) {
							grpInputsAlt[getInputTextNum()].alpha = 0;
						} else {
							grpInputs[getInputTextNum()].alpha = 0;
						}
						CoolUtil.playScrollSound();
					}
				}
			}
		} else {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				CoolUtil.playConfirmSound();
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if (bindingTime > 5) {
				if (curAlt) {
					grpInputsAlt[curSelected].alpha = 1;
				} else {
					grpInputs[curSelected].alpha = 1;
				}
				CoolUtil.playScrollSound();
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function getInputTextNum() {
		var num:Int = 0;
		for (i in 0...curSelected) {
			if (optionShit[i].length > 1) {
				num++;
			}
		}
		return num;
	}
	
	function changeSelection(change:Int = 0) {
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;

			if (!unselectableCheck(bullShit)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if (grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if (grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}

			bullShit++;
		}
		CoolUtil.playScrollSound();
	}

	function changeAlt() {
		curAlt = !curAlt;
		for (i in 0...grpInputs.length) {
			if (grpInputs[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputs[i].alpha = 0.6;
				if (!curAlt) {
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length) {
			if (grpInputsAlt[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputsAlt[i].alpha = 0.6;
				if (curAlt) {
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		CoolUtil.playScrollSound();
	}

	private function unselectableCheck(num:Int, ?checkCentered:Bool = false):Bool {
		if (optionShit[num][0] == defaultKey) {
			return checkCentered;
		}
		var keyMatch = false;
		for (i in keyTexts) {
			if (optionShit[num][0] == i[0]) {
				keyMatch = true;
				if (checkCentered) return true;
			}
		}
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey && !keyMatch;
	}

	private function addBindTexts(optionText:Alphabet, num:Int) {
		var keys = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKeys() {
		while(grpInputs.length > 0) {
			var item:AttachedText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while(grpInputsAlt.length > 0) {
			var item:AttachedText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		for (i in 0...grpOptions.length) {
			if (!unselectableCheck(i, true)) {
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;
		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if (grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if (grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}

class NoteBindingSubState extends MusicBeatSubState {
	var curSelected:Int = 0;
	var curAlt:Bool = false;
	var keys:Int = 4;
	var strumGroup:StrumLine;
	var bgTween:FlxTween;
	var text1:FlxText;
	var text2:FlxText;
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;
	private var keysArray:Array<Array<FlxKey>>;
	var testingBinds:Bool = false;
	var testTxt:FlxText;

	public function new(keys:Int = 4) {
		super();
		this.keys = keys;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		strumGroup = new StrumLine(320, 0, keys);
		strumGroup.receptors.forEach(function (spr:StrumNote) {
			spr.screenCenter(Y);
		});
		add(strumGroup);

		text1 = new FlxText(0, 450, FlxG.width - 800, '', 32);
		text1.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text1.screenCenter(X);
		text1.scrollFactor.set();
		text1.borderSize = 1.25;
		add(text1);
		text2 = new FlxText(0, 550, FlxG.width - 800, '', 32);
		text2.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text2.screenCenter(X);
		text2.scrollFactor.set();
		text2.borderSize = 1.25;
		text2.alpha = 0.6;
		add(text2);

		testTxt = new FlxText(0, FlxG.height * 0.2, FlxG.width - 800, 'Press "1" to switch to keybind testing', 32);
		testTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		testTxt.screenCenter(X);
		testTxt.scrollFactor.set();
		testTxt.borderSize = 1.25;
		add(testTxt);

		bgTween = FlxTween.tween(bg, {alpha: 0.3}, 0.4, {ease: FlxEase.quartInOut, onComplete: function(twn:FlxTween) {
			bgTween = null;
		}});

		changeSelection();
	}

	var holdTime:Float = 0;
	var bindingTime:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!rebindingKey) {
			if (!testingBinds) {
				if ((controls.UI_LEFT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0)) && keys > 1) {
					changeSelection(-1);
					holdTime = 0;
				}
				if ((controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0)) && keys > 1) {
					changeSelection(1);
					holdTime = 0;
				}
	
				var left = controls.UI_LEFT;
				var right = controls.UI_RIGHT;
				if (left || right)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (right ? -1 : 1));
					}
				}
	
				if (controls.UI_UP_P || controls.UI_DOWN_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel != 0)) {
					changeAlt();
				}
	
				if (controls.BACK) {
					ClientPrefs.reloadControls();
					if (bgTween != null) {
						bgTween.cancel();
					}
					close();
					CoolUtil.playCancelSound();
				}
	
				if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0) {
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt) {
						text2.alpha = 0;
					} else {
						text1.alpha = 0;
					}
					CoolUtil.playScrollSound();
				}

				if (FlxG.keys.justPressed.ONE && !rebindingKey) {
					testingBinds = true;
					text1.visible = false;
					text2.visible = false;
					testTxt.text = 'Press "1" to switch to keybind changing';
					for (i in strumGroup.receptors) {
						i.alpha = 1;
					}
					CoolUtil.playScrollSound();
				}
			} else {
				var controlArray:Array<Bool> = [];
				for (i in keysArray) {
					controlArray.push(FlxG.keys.anyJustPressed(i));
				}
				if (controlArray.contains(true)) {
					for (i in 0...controlArray.length) {
						if (controlArray[i]) {
							strumGroup.receptors.members[i].playAnim('pressed');
						}
					}
				}

				var controlReleaseArray:Array<Bool> = [];
				for (i in keysArray) {
					controlReleaseArray.push(FlxG.keys.anyJustReleased(i));
				}
				if (controlReleaseArray.contains(true)) {
					for (i in 0...controlReleaseArray.length) {
						if (controlReleaseArray[i]) {
							strumGroup.receptors.members[i].playAnim('static');
						}
					}
				}

				if (controls.BACK) {
					ClientPrefs.reloadControls();
					if (bgTween != null) {
						bgTween.cancel();
					}
					close();
					CoolUtil.playCancelSound();
				}

				if (FlxG.keys.justPressed.ONE) {
					testingBinds = false;
					text1.visible = true;
					text2.visible = true;
					testTxt.text = 'Press "1" to switch to keybind testing';
					changeSelection();
				}
			}
		} else {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(getKeybindName());
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(getKeybindName(), keysArray);

				reloadKeys();
				if (curAlt) {
					text2.alpha = 1;
				} else {
					text1.alpha = 1;
				}
				CoolUtil.playConfirmSound();
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if (bindingTime > 5) {
				if (curAlt) {
					text2.alpha = 1;
				} else {
					text1.alpha = 1;
				}
				CoolUtil.playScrollSound();
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = keys - 1;
		if (curSelected >= keys)
			curSelected = 0;

		for (i in 0...strumGroup.receptors.length) {
			if (i == curSelected) {
				strumGroup.receptors.members[i].alpha = 1;
			} else {
				strumGroup.receptors.members[i].alpha = 0.6;
			}
		}

		reloadKeys();

		CoolUtil.playScrollSound();
	}

	function changeAlt() {
		curAlt = !curAlt;
		text1.alpha = curAlt ? 0.6 : 1;
		text2.alpha = !curAlt ? 0.6 : 1;

		CoolUtil.playScrollSound();
	}

	function getKeybindName() {
		return 'note${keys}_$curSelected';
	}

	function reloadKeys() {
		keysArray = [];
		for (i in 0...keys) {
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note${keys}_$i')));
		}

		var keys = ClientPrefs.keyBinds.get(getKeybindName());
		text1.text = InputFormatter.getKeyName(keys[0]);
		text2.text = InputFormatter.getKeyName(keys[1]);

		text1.alpha = curAlt ? 0.6 : 1;
		text2.alpha = !curAlt ? 0.6 : 1;
	}
}