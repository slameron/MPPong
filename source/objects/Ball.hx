package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxVelocity;

class Ball extends FlxSprite
{
	/**Value that will multiply the score earned from this ball.**/
	public var mult:Float = 1;

	/**Whether or not the ball should reset after it is scored. Should only be true for the first ball, additional balls should not reset.**/
	public var autoReset:Bool = false;

	/**Speed of the ball**/
	public var speed:Float;

	/**Similar to the create function of states.**/
	override public function new(?speed:Float = 200)
	{
		// Call the new function on the parent class, `FlxSprite`. Pass in 0, 0 as the x and y, as we'll change it later
		super(0, 0);

		// Sets the speed to the one that is passed into the function. If none is passed in, it uses the default value (200).
		this.speed = speed;

		// Make a 10x10 square
		makeGraphic(10, 10);

		// Center it on the screen
		screenCenter();

		elasticity = 1;
	}

	/**Resets the ball
	 * @param angle The angle at which the ball is fired. Leave null to have it random, set it for online multiplayer.
	**/
	public function start(angle:Null<Int> = null):Ball
	{
		screenCenter();

		// If angle was not passed in, we should randomize it
		if (angle == null)
		{
			// Array of numbers to exclude from the random selection. Makes sure the ball does not go too vertical.
			var exc:Array<Int> = [for (i in 75...106) i].concat([for (i in 255...286) i]);

			// Picks a random number or angle, excluding the previous array
			angle = FlxG.random.int(0, 360, exc);
		}

		// Gets a velocity x and y given the angle and speed
		var vel = FlxVelocity.velocityFromAngle(angle, speed);

		// Set the ball's velocity to the one we got
		velocity.set(vel.x, vel.y);

		// Pass the instance of this object to whatever called this funtion, useful for adding the ball directly with only one line.
		return this;
	}
}
