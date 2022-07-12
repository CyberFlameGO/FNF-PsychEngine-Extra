package;

import Note.EventNote;
import flixel.FlxG;
import StrumNote.KeyChangeEvent;
import StrumNote.StrumLine;
import haxe.Json;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Array<Dynamic>>;
	var bpm:Float;
	var timeSignature:Array<Int>;
	var needsVoices:Bool;
	var speed:Float;
	var ?boyfriendKeyAmount:Int;
	var ?dadKeyAmount:Int;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var skinModifier:String;

	var validScore:Bool;
}

typedef SwagSection =
{
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var ?gfSection:Bool;
	var ?bpm:Float;
	var ?changeBPM:Bool;
	var timeSignature:Array<Int>;
	var ?changeSignature:Bool;
	var ?altAnim:Bool;
	var ?changeKeys:Bool;
	var ?boyfriendKeyAmount:Int;
	var ?dadKeyAmount:Int;
}

typedef MetaFile = {
	var ?displayName:String;
	var freeplayDifficulties:String;
	var ?iconHiddenUntilPlayed:Bool;
}

class Song
{
	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		var curSong:String = Paths.formatToSongPath(songJson.song);
		
		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		if (songJson.boyfriendKeyAmount == null)
		{
			songJson.boyfriendKeyAmount = 4;
			songJson.dadKeyAmount = 4;
		}
		if (songJson.timeSignature == null)
		{
			songJson.timeSignature = [4, 4];
		}
		if (songJson.skinModifier == null || songJson.skinModifier.length < 1) {
			switch (curSong) {
				case 'senpai' | 'roses' | 'thorns':
					songJson.skinModifier = 'pixel'; //set to week 6 skin
				default:
					songJson.skinModifier = ''; //set to default
			}
		}
		
		for (secNum in 0...songJson.notes.length) {
			var sec:SwagSection = songJson.notes[secNum];
			if (sec.gfSection == null) sec.gfSection = false;
			if (sec.bpm == null) sec.bpm = songJson.bpm;
			if (sec.changeBPM == null) sec.changeBPM = false;
			if (sec.timeSignature == null) {
				var timeSignature:Array<Int> = songJson.timeSignature;
				sec.timeSignature = timeSignature.copy(); //haxe why are you so WEEEEEEEIIIIIIRD
			}
			if (sec.changeSignature == null) sec.changeSignature = false;
			if (sec.altAnim == null) sec.altAnim = false;
			if (sec.changeKeys == null) sec.changeKeys = false;
			if (sec.boyfriendKeyAmount == null) sec.boyfriendKeyAmount = songJson.boyfriendKeyAmount;
			if (sec.dadKeyAmount == null) sec.dadKeyAmount = songJson.dadKeyAmount;
			var i:Int = 0;
			var notes = sec.sectionNotes;
			var len:Int = notes.length;
			while(i < len)
			{
				var note = notes[i];
				while (note.length < 5) {
					note.push(null);
				}
				if (note[3] != null && Std.isOfType(note[3], Int)) note[3] = editors.ChartingState.noteTypeList[note[3]];
				if (note[3] != null && note[3] == true) note[3] = 'Alt Animation';
				if (note[3] == null) note[3] = '';
				if (note[4] == null || note[4].length < 1) note[4] = [];
				notes[i] = [note[0], note[1], note[2], note[3], note[4]];
				i++;
			}
			songJson.notes[secNum] = sec;
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		rawJson = Paths.getContent(Paths.json('$formattedFolder/$formattedSong')).trim();

		if (rawJson == null) {
			return null;
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Dynamic = parseJSONshit(rawJson);
		if (formattedSong != 'events' && formattedSong != 'picospeaker') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song; //actual song
		var tempSong:Dynamic = cast Json.parse(rawJson).song; //copy to check for other variables

		if (swagShit.gfVersion == null) {
			if (tempSong.player3 != null) {
				swagShit.gfVersion = tempSong.player3;
			}
			if (tempSong.gf != null) {
				swagShit.gfVersion = tempSong.gf;
			}
		}
		if (swagShit.boyfriendKeyAmount == null) {
			if (tempSong.playerKeyAmount != null) {
				swagShit.boyfriendKeyAmount = tempSong.playerKeyAmount;
			}
			if (tempSong.opponentKeyAmount != null) {
				swagShit.dadKeyAmount = tempSong.opponentKeyAmount;
			}
			if (tempSong.mania != null) {
				switch (tempSong.mania) {
					case 1:
						swagShit.boyfriendKeyAmount = 6;
					case 2:
						swagShit.boyfriendKeyAmount = 7;
					case 3:
						swagShit.boyfriendKeyAmount = 9;
					default:
						swagShit.boyfriendKeyAmount = 4;
				}
				swagShit.dadKeyAmount = swagShit.boyfriendKeyAmount;
			}
			if (tempSong.keyCount != null) {
				swagShit.boyfriendKeyAmount = tempSong.keyCount;
				swagShit.dadKeyAmount = tempSong.keyCount;
			}
			if (tempSong.playerKeyCount != null) {
				swagShit.boyfriendKeyAmount = tempSong.playerKeyCount;
			}
		}
		if (swagShit.timeSignature == null) {
			if (tempSong.numerator != null && tempSong.denominator != null) {
				swagShit.timeSignature = [tempSong.numerator, tempSong.denominator];
			}
			if (tempSong.timescale != null && tempSong.timescale.length == 2) {
				var timescale:Array<Int> = tempSong.timescale;
				swagShit.timeSignature = timescale.copy();
			}
		}

		for (i in 0...tempSong.notes.length) {
			var sec = tempSong.notes[i];
			var numerator:Null<Int> = sec.numerator;
			var denominator:Null<Int> = sec.denominator;
			if (numerator != null && denominator != null) {
				swagShit.notes[i].timeSignature = [numerator, denominator];
			}
			var sectionBeats:Null<Float> = sec.sectionBeats;
			if (sectionBeats != null) {
				swagShit.notes[i].timeSignature[0] = Math.round(sectionBeats);
				swagShit.notes[i].changeSignature = true;
			}
			var playerKeys:Null<Int> = sec.playerKeys;
			var opponentKeys:Null<Int> = sec.opponentKeys;
			if (playerKeys != null && opponentKeys != null) {
				swagShit.notes[i].boyfriendKeyAmount = playerKeys;
				swagShit.notes[i].dadKeyAmount = opponentKeys;
			}
		}

		swagShit.validScore = true;
		return swagShit;
	}

	public static function generateNotes(song:SwagSong, ?dadStrums:StrumLine, ?boyfriendStrums:StrumLine, pvp:Bool = false) {
		var notes:Array<Note> = [];

		var noteData:Array<SwagSection> = song.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var curStepCrochet = Conductor.stepCrochet;
		var curBPM = Conductor.bpm;
		var curDenominator = Conductor.timeSignature[1];
		var curPlayerKeys = song.boyfriendKeyAmount;
		var curOpponentKeys = song.dadKeyAmount;
		for (curSection in 0...noteData.length)
		{
			var section = noteData[curSection];
			if (section.changeBPM) {
				curBPM = section.bpm;
				curStepCrochet = (((60 / curBPM) * 4000) / curDenominator) / 4;
			}
			if (section.changeSignature) {
				curDenominator = section.timeSignature[1];
				curStepCrochet = (((60 / curBPM) * 4000) / curDenominator) / 4;
			}
			if (section.changeKeys) {
				if (curOpponentKeys != section.dadKeyAmount) {
					curOpponentKeys = section.dadKeyAmount;
					if (dadStrums != null) {
						var event:KeyChangeEvent = {
							section: curSection,
							keys: curOpponentKeys 
						};
						dadStrums.pushEvent(event);
					}
				}
				if (curPlayerKeys != section.boyfriendKeyAmount) {
					curPlayerKeys = section.boyfriendKeyAmount;
					if (boyfriendStrums != null) {
						var event:KeyChangeEvent = {
							section: curSection,
							keys: curPlayerKeys 
						};
						boyfriendStrums.pushEvent(event);
					}
				}
			}
			var leftKeys = (section.mustHitSection ? curPlayerKeys : curOpponentKeys);
			var rightKeys = (!section.mustHitSection ? curPlayerKeys : curOpponentKeys);
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if (CoolUtil.inAnyPlayState(true) && PlayState.instance.inEditor && daStrumTime < PlayState.instance.startPos) continue;
				var daNoteData:Int = Std.int(songNotes[1]);
				if (songNotes[1] >= leftKeys) {
					daNoteData = Std.int(songNotes[1] - leftKeys);
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] >= leftKeys)
				{
					gottaHitNote = !gottaHitNote;
				}
				var isOpponent:Bool = !gottaHitNote;

				if (CoolUtil.inAnyPlayState(true) && PlayState.instance.opponentChart) {
					gottaHitNote = !gottaHitNote;
				}

				if (pvp) gottaHitNote = true;

				var oldNote:Note;
				if (notes.length > 0)
					oldNote = notes[notes.length - 1];
				else
					oldNote = null;

				var keys = isOpponent ? curOpponentKeys : curPlayerKeys;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, keys);
				swagNote.mustPress = gottaHitNote;
				swagNote.isOpponent = isOpponent;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < rightKeys));
				swagNote.characters = songNotes[4];
				if (songNotes[4] == null) swagNote.characters = [0];
				swagNote.bpm = curBPM;
				swagNote.stepCrochet = curStepCrochet;
				swagNote.noteType = songNotes[3];
				swagNote.scrollFactor.set();
				notes.push(swagNote);

				var susLength:Float = swagNote.sustainLength / curStepCrochet;
				var floorSus:Int = Math.floor(susLength);
				if (floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = notes[notes.length - 1];

						var songSpeed = CoolUtil.inAnyPlayState() ? CoolUtil.getPlayState().songSpeed : 1;
						var sustainNote:Note = new Note(daStrumTime + (curStepCrochet * susNote) + (curStepCrochet / songSpeed), daNoteData, oldNote, true, false, keys);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.isOpponent = isOpponent;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.characters = songNotes[4];
						if (songNotes[4] == null) sustainNote.characters = [0];
						sustainNote.bpm = curBPM;
						sustainNote.stepCrochet = curStepCrochet;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						notes.push(sustainNote);

						if (!sustainNote.isOpponent)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
					}
				}

				if (!swagNote.isOpponent)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
			daBeats += 1;
		}
		trace('dad key change map: ' + dadStrums.keyChangeMap);
		trace('bf key change map: ' + boyfriendStrums.keyChangeMap);
		return notes;
	}

	public static function generateEventNotes(song:SwagSong, ?pushedCallback:EventNote->Void, ?earlyTriggerFunction:EventNote->Float) {
		var eventNotes:Array<EventNote> = [];
		var curSong = Paths.formatToSongPath(song.song);
		if (Paths.existsPath('data/$curSong/events.json', TEXT)) {
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', curSong).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					if (earlyTriggerFunction != null) subEvent.strumTime -= earlyTriggerFunction(subEvent);
					eventNotes.push(subEvent);
					if (pushedCallback != null) pushedCallback(subEvent);
				}
			}
		}
		for (event in song.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				if (earlyTriggerFunction != null) subEvent.strumTime -= earlyTriggerFunction(subEvent);
				eventNotes.push(subEvent);
				if (pushedCallback != null) pushedCallback(subEvent);
			}
		}
		return eventNotes;
	}

	public static function getMetaFile(name:String):MetaFile {
		name = Paths.formatToSongPath(name);
		var characterPath:String = 'data/$name/meta.json';
		var path:String = Paths.getPath(characterPath);
		if (!Paths.exists(path))
		{
			var meta:MetaFile = {
				displayName: null,
				freeplayDifficulties: null,
				iconHiddenUntilPlayed: false
			};
			return meta;
		}

		var rawJson = Paths.getContent(path);

		if (rawJson == null) {
			return null;
		}

		var json:MetaFile = cast Json.parse(rawJson);
		if (json.iconHiddenUntilPlayed == null) json.iconHiddenUntilPlayed = true;
		return json;
	}

	public static function getDisplayName(song:String) {
		var meta = Song.getMetaFile(song);
		return meta.displayName != null ? meta.displayName : song;
	}

	public static function getGFVersion(song:String, stage:String) {
		switch (song)
		{
			case 'stress':
				return 'pico-speaker';
		}
        switch (stage)
        {
            case 'limo':
                return 'gf-car';
            case 'mall' | 'mallEvil':
                return 'gf-christmas';
            case 'school' | 'schoolEvil':
                return 'gf-pixel';
            case 'tank':
                return 'gf-tankmen';
            default:
                return 'gf';
        }
    }
}
