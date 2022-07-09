package pvp;

import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.FlxG;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

using StringTools;

typedef CharacterData = {
    var name:String;
    var displayName:String;
    var alternateForms:Array<AlternateForm>;
}

typedef AlternateForm = {
    var name:String;
    var displayName:String;
}

class CharacterSelect extends FlxSpriteGroup {
    var characters:Array<CharacterData> = [];

    var grpIcons:FlxTypedSpriteGroup<HealthIcon>;
    var panel:FlxSprite;
    var cornerSize:Int = 5;
    var selectedSquare:FlxSprite;
    
    var grpIconsPos:FlxPoint = new FlxPoint(0, 5);

    public var curSelectedX:Int = 0;
    public var curSelectedY:Int = 0;

    public var isGamepad:Bool = false;

    var curCharIndex(get, never):Int;
    var curCharPos(get, never):FlxPoint;
    var maxX:Int = 0;
    var maxY:Int = 1;

    var character:FlxSprite;
    var characterText:FlxText;
    var selectingAlt:Bool = false;
    var curCharacter:String = 'bf';
    var curAltIndex:Int = 0;
    var ready:Bool = false;
    var curAlts(get, never):Array<AlternateForm>;
    var readyText:FlxText;

    function get_curCharIndex() {
        return curSelectedX * 2 + curSelectedY;
    }

    function get_curCharPos() {
        var point = new FlxPoint(grpIcons.members[curCharIndex].x, grpIcons.members[curCharIndex].y);
        return point;
    }

    function get_curAlts() {
        return characters[curCharIndex].alternateForms;
    }

    public function new(x:Float = 0, y:Float = 0, characters:Array<CharacterData>, isGamepad:Bool = false) {
        super(x, y);
        this.characters = characters;
        this.isGamepad = isGamepad;

        scrollFactor.set();

        panel = new FlxSprite(0, 560);
        makeSelectorGraphic(panel, 600, 160, 0xff999999);
        panel.scrollFactor.set();

        selectedSquare = new FlxSprite(0, 560).makeGraphic(75, 75, 0xffcdcdcd);
        selectedSquare.scrollFactor.set();

        grpIcons = new FlxTypedSpriteGroup(5, 565);
        grpIcons.scrollFactor.set();

        for (i in 0...characters.length) {
            var char = characters[i].name;
            var charFile = Character.getFile(char);
            
            var icon = new HealthIcon(charFile.healthicon);
            icon.setGraphicSize(75, 75);
            updateIconHitbox(icon);
            icon.x = 75 * Math.floor(i / 2);
            if (icon.x / 75 > maxX) {
                maxX = Std.int(icon.x / 75);
            }
            icon.y = 75 * (i % 2);
            grpIcons.add(icon);
        }

        character = new FlxSprite();
        character.scrollFactor.set();

        characterText = new FlxText(0, panel.y - 64, 640, "", 32);
		characterText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterText.scrollFactor.set();
        characterText.borderSize = 2;

        readyText = new FlxText(0, 280 - 32, 640, "READY", 64);
		readyText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		readyText.scrollFactor.set();
        readyText.borderSize = 2;
        readyText.visible = false;

        add(panel);
        add(selectedSquare);
        add(grpIcons);
        add(character);
        add(characterText);
        add(readyText);

        setClipRect();
        changeSelection();
    }

    var holdTime:Float = 0;
    override function update(elapsed:Float) {
        super.update(elapsed);

        if (!isGamepad) {
            var controls = PlayerSettings.player1.controls;
            if (ready) {
                if (controls.BACK) {
                    playerUnready();
                }
            } else {
                if (!selectingAlt) {
                    if (grpIcons.length > 1) {
                        if (controls.UI_UP_P) {
                            changeSelection(0, -1);
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        }
                        if (controls.UI_DOWN_P) {
                            changeSelection(0, 1);
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        }
                        if (grpIcons.length > 2) {
                            if (controls.UI_LEFT_P) {
                                changeSelection(-1);
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                                holdTime = 0;
                            }
                            if (controls.UI_RIGHT_P) {
                                changeSelection(1);
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                                holdTime = 0;
                            }
                            if (controls.UI_LEFT || controls.UI_RIGHT)
                            {
                                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                                holdTime += elapsed;
                                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
                
                                if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                                {
                                    changeSelection((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
                                }
                            }
                        }
                    }
        
                    if (controls.BACK) {
                        FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
                        MusicBeatState.switchState(new MainMenuState());
                    }
    
                    if (controls.ACCEPT) {
                        if (curAlts.length > 0) {
                            selectingAlt = true;
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        } else {
                            playerReady();
                        }
                    }
                } else {
                    if (curAlts.length > 0) {
                        if (controls.UI_LEFT_P) {
                            changeAlt(-1);
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        }
                        if (controls.UI_RIGHT_P) {
                            changeAlt(1);
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        }
                    }
    
                    if (controls.BACK) {
                        selectingAlt = false;
                        curAltIndex = 0;
                        changeAlt();
                        FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
                    } else if (controls.ACCEPT) {
                        playerReady();
                    }
                }
            }
        }

        var lerpVal:Float = CoolUtil.boundTo(elapsed * 10, 0, 1);
        grpIcons.setPosition(FlxMath.lerp(grpIcons.x, panel.x + grpIconsPos.x, lerpVal), FlxMath.lerp(grpIcons.y, panel.y + grpIconsPos.y, lerpVal));
		selectedSquare.setPosition(FlxMath.lerp(selectedSquare.x, curCharPos.x, lerpVal), FlxMath.lerp(selectedSquare.y, curCharPos.y, lerpVal));

        setClipRect();
    }

    function changeSelection(x:Int = 0, y:Int = 0) {
        curSelectedX += x;
        if (curSelectedX < 0)
			curSelectedX = maxX;
		if (curSelectedX > maxX || grpIcons.members[curCharIndex] == null)
			curSelectedX = 0;
        

        curSelectedY += y;
        if (curSelectedY < 0)
			curSelectedY = maxY;
        if (curSelectedY > maxY)
            curSelectedY = 0;
        if (grpIcons.members[curCharIndex] == null)
            curSelectedY -= 1;

        if (maxX >= 9) {
            grpIconsPos.x = FlxMath.remapToRange(curSelectedX, 0, maxX, 5, panel.width - grpIcons.width);
        }

        curAltIndex = 0;
        changeAlt();
    }

    function changeAlt(add:Int = 0) {
        curAltIndex += add;
        if (curAltIndex < 0)
			curAltIndex = curAlts.length;
		if (curAltIndex > curAlts.length)
			curAltIndex = 0;

        if (curAltIndex > 0) {
            curCharacter = curAlts[curAltIndex - 1].name;
            characterText.text = curAlts[curAltIndex - 1].displayName;
        } else {
            curCharacter = characters[curCharIndex].name;
            characterText.text = characters[curCharIndex].displayName;
        }
        character.loadGraphic(Paths.image('pvp/char/$curCharacter'));
    }

    function updateIconHitbox(icon:HealthIcon) {
        icon.updateHitbox();
        icon.offset.set(-0.5 * (icon.width - icon.frameWidth), -0.5 * (icon.height - icon.frameHeight));
    }

    function setClipRect() {
        for (icon in grpIcons) {
            if (icon.x + icon.width < panel.x || icon.x > panel.x + panel.width) {
                icon.active = false;
                icon.visible = false;
            } else {
                icon.active = true;
                icon.visible = true;
                var swagRect = new FlxRect(0, 0, icon.frameWidth, icon.frameHeight);
                if (icon.x < panel.x) {
                    swagRect.x += Math.abs(panel.x - icon.x) * 2;
                    swagRect.width -= swagRect.x;
                    icon.clipRect = swagRect;
                } else if (icon.x + icon.width > panel.x + panel.width) {
                    swagRect.width -= ((icon.x + icon.width) - (panel.x + panel.width)) / icon.scale.x;
                    icon.clipRect = swagRect;
                }
                icon.clipRect = swagRect;
            }
        }
    }

    function playerReady() {
        ready = true;
        readyText.visible = true;
        character.alpha = 0.5;
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
    }

    function playerUnready() {
        ready = false;
        readyText.visible = false;
        character.alpha = 1;
        FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
    }

    function makeSelectorGraphic(panel:FlxSprite,w,h,color:FlxColor)
	{
		panel.makeGraphic(w, h, color);
		panel.pixels.fillRect(new Rectangle(0, 190, panel.width, 5), 0x0);

		panel.pixels.fillRect(new Rectangle(0, 0, cornerSize, cornerSize), 0x0);														 //top left
		drawCircleCornerOnSelector(panel,false, false,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, 0, cornerSize, cornerSize), 0x0);							 //top right
		drawCircleCornerOnSelector(panel,true, false,color);
		panel.pixels.fillRect(new Rectangle(0, panel.height - cornerSize, cornerSize, cornerSize), 0x0);							 //bottom left
		drawCircleCornerOnSelector(panel,false, true,color);
		panel.pixels.fillRect(new Rectangle(panel.width - cornerSize, panel.height - cornerSize, cornerSize, cornerSize), 0x0); //bottom right
		drawCircleCornerOnSelector(panel,true, true,color);
	}

    function drawCircleCornerOnSelector(panel:FlxSprite,flipX:Bool, flipY:Bool,color:FlxColor)
	{
		var antiX:Float = (panel.width - cornerSize);
		var antiY:Float = flipY ? (panel.height - 1) : 0;
		if(flipY) antiY -= 2;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 1), Std.int(Math.abs(antiY - 8)), 10, 3), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), color);
		if(flipY) antiY += 1;
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 3), Std.int(Math.abs(antiY - 5)),  8, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 4), Std.int(Math.abs(antiY - 4)),  7, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 5), Std.int(Math.abs(antiY - 3)),  6, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 6), Std.int(Math.abs(antiY - 2)),  5, 1), color);
		panel.pixels.fillRect(new Rectangle((flipX ? antiX : 8), Std.int(Math.abs(antiY - 1)),  3, 1), color);
	}
}