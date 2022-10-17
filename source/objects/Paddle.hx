package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import states.PlayState;

class Paddle extends FlxSprite
{
	/**Movement speed of the paddles**/
	public var speed:Int = 200;

	/**Whether or not the paddle will control itself.**/
	public var cpuControlled:Bool = false;

	/**Whether or not the player controls this paddle.**/
	public var playerControlled:Bool = false;

	override public function new()
	{
		super(0, 0);

		makeGraphic(10, 80);
		immovable = true;
		allowCollisions = WALL;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Store keyboard input in variables for quick acccess
		var up = FlxG.keys.anyPressed([UP, W]);
		var down = FlxG.keys.anyPressed([DOWN, S]);

		if (cpuControlled)
		{
			// Variable to store the closest ball in.
			var closestBall:Ball = null;

			// Variable to store the distance of the closest ball.
			var closestDiff:Float = 0;

			// Check every ball in the group of balls. We access it via `FlxG.state`, casting it into a `PlayState` instance to access `balls`.
			for (ball in cast(FlxG.state, PlayState).balls)
			{
				if (closestBall != null)
				{
					// Get the distance between the ball and the paddle.
					var diff = Math.abs((x + width / 2) - (ball.x + ball.width / 2));

					// If the ball we are currently checking is closer than the closest one we have stored, store this ball.
					if (diff < closestDiff)
					{
						closestBall = ball;
						closestDiff = diff;
					}
				}
				// If there is currently no ball stored, store this one.
				else
				{
					closestBall = ball;
					closestDiff = Math.abs((x + width / 2) - (closestBall.x + closestBall.width / 2));
				}

				var left = x < FlxG.width / 2;
				// If the closest ball is closer than 400px away, start moving toward it.
				// Also only move toward the ball if the ball is moving toward the paddle.
				if (closestDiff < 400 && (left && ball.velocity.x < 0 || !left && ball.velocity.x > 0))
					(ball.y + ball.height / 2) > (y + height / 2) ? velocity.y = speed : velocity.y = -speed;
				else if ((y + height / 2) > FlxG.height / 2 + height / 2 || (y + height / 2) < FlxG.height / 2 - height / 2)
					velocity.y = (y + height / 2) > FlxG.height / 2 + height / 2 ? -speed : speed;
				else
					velocity.y = 0;
			}
		}
		else if (playerControlled)
		{
			// Handle the movement of the player paddle.
			if (up && !down)
				velocity.y = -speed;
			else if (down && !up)
				velocity.y = speed;
			else
				velocity.y = 0;
		}
	}
}
