package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.InputState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, InputState, 1, 60, 60, true));
	}
}
