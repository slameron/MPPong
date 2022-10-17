package states;

import client.Client;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Ball;
import objects.Paddle;

class PlayState extends FlxState
{
	var left:Bool = false;

	/**Object representing the player's paddle**/
	var myPaddle:Paddle;

	/**Object representing other player's paddle**/
	var opponentPaddle:Paddle;

	/**Container for the paddles to run less collision checks**/
	var grpPaddles:FlxTypedGroup<Paddle>;

	/**Group containing camera border for collisions.**/
	var walls:FlxGroup;

	/**Group containing all the balls, members MUST be of type `Ball`**/
	public var balls:FlxTypedGroup<Ball>;

	var client:client.Client;
	var ip:String;
	var port:Int;

	var myScore(null, set):Int;
	var opponentScore(null, set):Int;
	var myScoreTxt:FlxText;
	var opponentScoreTxt:FlxText;

	function set_myScore(score:Int)
	{
		myScoreTxt.text = '$score';
		myScoreTxt.setPosition(FlxG.width / 2 - myScoreTxt.width / 2 + (left ? 30 : -30), FlxG.height - myScoreTxt.height - 10);
		return myScore = score;
	}

	function set_opponentScore(score:Int)
	{
		opponentScoreTxt.text = '$score';
		opponentScoreTxt.setPosition(FlxG.width / 2 - opponentScoreTxt.width / 2 + (left ? -30 : 30), FlxG.height - opponentScoreTxt.height - 10);
		return opponentScore = score;
	}

	override public function new(ip:String = '127.0.0.1', port:Int = 8000)
	{
		super();
		this.ip = ip;
		this.port = port;
	}

	/**Function that is run at the start of this state. Used to initialize objects**/
	override public function create()
	{
		super.create();
		FlxG.mouse.visible = false;
		bgColor = FlxColor.fromHSB(FlxG.random.int(0, 360), 1, 1, .6);
		FlxG.autoPause = false;

		// Make a border around the camera to collide with the paddles/balls.
		add(walls = FlxCollision.createCameraWall(FlxG.camera, true, 5));

		// Initialize and add the group of balls.
		add(balls = new FlxTypedGroup());

		// Initialize and add the group of paddles.
		add(grpPaddles = new FlxTypedGroup());

		// Initialize the paddle objects and add them to the group
		grpPaddles.add(myPaddle = new Paddle());
		grpPaddles.add(opponentPaddle = new Paddle());

		// Set the paddles to the appropriate positions on the screen
		opponentPaddle.setPosition(FlxG.width - opponentPaddle.width - 20, FlxG.height / 2 - opponentPaddle.height / 2);
		myPaddle.setPosition(20, FlxG.height / 2 - myPaddle.height / 2);
		opponentPaddle.cpuControlled = opponentPaddle.playerControlled = false;

		myScoreTxt = new FlxText(0, 0, 0, '0', 24);
		myScoreTxt.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(myScoreTxt);
		opponentScoreTxt = new FlxText(0, 0, 0, '0', 24);
		opponentScoreTxt.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(opponentScoreTxt);

		myScore = opponentScore = 0;

		var statusText = new FlxText(0, 20, FlxG.width, 'Connecting to server...', 24);
		statusText.alignment = CENTER;
		statusText.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(statusText);

		// opponentPaddle.cpuControlled = true;

		// Setup and start the client
		client = new Client(ip, port, makeID(10));

		client.connectionEstablished = () -> client.send('join', {id: client.id});
		client.connectionError = error ->
		{
			if (!statusText.alive)
				statusText.revive();
			statusText.text = 'Connection to server failed.\nReturning to menu...';

			new FlxTimer().start(3, tmr -> FlxG.switchState(new InputState()));
		};

		client.events.on('opponentJoined', data ->
		{
			trace('got movement update');
		});

		client.events.on('movementUpdate', data ->
		{
			var positions:Array<Dynamic> = data.positions;

			for (positionData in positions)
			{
				if (positionData.id == client.id)
					continue;

				opponentPaddle.y = positionData.y;
				opponentPaddle.velocity.y = positionData.vy;
			}
		});

		// Since `myPaddle` is on the left, if the player is on the right, swap the objects associated with the variables.
		client.events.on('left', data ->
		{
			statusText.text = "Waiting for another player...";
			if (data == false)
			{
				var hold = myPaddle;
				myPaddle = opponentPaddle;
				opponentPaddle = hold;
				hold = null;
				var hold = myScoreTxt;
				myScoreTxt = opponentScoreTxt;
				opponentScoreTxt = hold;
				hold = null;
			}
			this.left = data;
		});

		// When the server lets us know the game is started, add a ball and start it, telling it to move at the angle the server sent.
		client.events.on('gameStart', data ->
		{
			statusText.text = 'Opponent Joined!\nYou\'re on the ${left ? 'left' : 'right'}.';
			new FlxTimer().start(2, tmr ->
			{
				statusText.kill();
				balls.add(new Ball().start(data));
				myPaddle.playerControlled = true;
			});
		});

		client.events.on('spawnBall',
			data -> if (data.delay > 0) new FlxTimer().start(data.delay,
				tmr -> balls.add(new Ball().start(data.angle))) else balls.add(new Ball().start(data.angle)));

		client.events.on('updateScore', data ->
		{
			FlxG.camera.shake(0.025, 0.05);
			bgColor = FlxColor.fromHSB(FlxG.random.int(0, 360), 1, 1, .6);
			var scores:Array<Dynamic> = data;
			for (score in scores)
			{
				if (score.id == client.id)
					myScore = score.score;
				else
					opponentScore = score.score;
			}
		});
		client.start();
	}

	/**Function that runs every frame. `elapsed` is the amount of time that has passed since the last frame, measured in seconds.**/
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Collide the paddles against the camera border. Stops the paddles from moving off-screen.
		FlxG.collide(myPaddle, walls);

		// Collide the group of balls with the walls. If it hits, `wallCollide` is called, passing in the ball and wall that collided.
		FlxG.collide(balls, walls, wallCollide);

		// Collide the group of balls with the paddles. If it hits, `paddleCollide` is called, passing in the ball and paddle that collided.
		FlxG.collide(balls, grpPaddles, paddleCollide);

		if (client.isReady)
		{
			client.update();
			if ((tick++) % 4 == 0)
				client.send('movementUpdate', {y: myPaddle.y, vy: myPaddle.velocity.y});
		}
	}

	var tick:Int = 0;

	function wallCollide(ball:Ball, wall:FlxObject)
	{
		// If the height is more than the width, the wall is on the left or right. We can reset the ball and add to the score.
		if (wall.height > wall.width)
		{
			if (Math.abs(ball.x - myPaddle.x) <= 50)
				client.send('score', client.id);

			// Remove the ball
			ball.kill();
		}
	}

	function paddleCollide(ball:Ball, paddle:Paddle)
	{
		ball.velocity.set(ball.velocity.x * 1.1, ball.velocity.y * 1.1);
	}

	function makeID(length:Int):String
	{
		var id:String = "";

		var characters:String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

		for (i in 0...length)
			id += characters.charAt(FlxG.random.int(0, characters.length - 1));

		return (id);
	}
}
