package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class InputState extends FlxState
{
	var inputText:FlxText;

	override public function create()
	{
		super.create();
		FlxG.debugger.toggleKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = FlxG.sound.muteKeys = [];

		bgColor = FlxColor.fromHSB(FlxG.random.int(0, 360), 1, .6, 1);

		FlxG.mouse.visible = true;

		var statusText = new FlxText(0, 60, FlxG.width, 'Networked Pong', 24);
		statusText.alignment = CENTER;
		statusText.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(statusText);

		var tooltip = new FlxText(0, statusText.y + statusText.height + 10, FlxG.width, 'Enter the IP address to the server and press enter.', 12);
		tooltip.alignment = CENTER;
		tooltip.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(tooltip);

		inputText = new FlxText(0, tooltip.y + tooltip.height + 40, FlxG.width, '', 16);
		inputText.alignment = CENTER;
		inputText.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(inputText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.BACKSPACE)
			inputText.text = inputText.text.substring(0, inputText.text.length - 1);
		else if (FlxG.keys.justPressed.ENTER)
		{
			var split:Array<String> = inputText.text.split(':');

			var ip = split[0];
			if (ip.length <= 1)
				ip = '127.0.0.1';
			var port = 8000;
			if (split[1] != null)
				port = Std.parseInt(split[1]);

			FlxG.switchState(new PlayState(ip, port));
		}
		else if (FlxG.keys.anyJustPressed([
			SHIFT, QUOTE, SLASH, BACKSLASH, GRAVEACCENT, TAB, CONTROL, ALT, PLUS, LBRACKET, RBRACKET, COMMA
		]))
			return; // Don't handle any of the action keys, just show me the regulars!!!!
		else if (FlxG.keys.justPressed.ANY)
		{
			var key:FlxKey = FlxG.keys.firstJustPressed();
			inputText.text += retNumber(key.toString());
		}
	}

	function retNumber(char:String)
	{
		var num = char.toLowerCase();
		if (numbers.exists(num))
			return numbers.get(num);
		else
			return char;
	}

	var numbers:Map<String, String> = [
		'one' => '1', 'two' => '2', 'three' => '3', 'four' => '4', 'five' => '5', 'six' => '6', 'seven' => '7', 'eight' => '8', 'nine' => '9', 'zero' => '0',
		'period' => '.', 'colon' => ':', 'semicolon' => ':', 'minus' => '-'
	];
}
