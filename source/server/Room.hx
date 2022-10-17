package server;

import mphx.connection.IConnection;
import mphx.connection.impl.Connection;
import server.Server.PaddleData;

class Room extends mphx.server.room.Room
{
	public var ID:Int;

	var server:Server;

	public var paddles:Map<IConnection, PaddleData>;
	public var score:Map<IConnection, Int>;

	/**Map to hold the new data that is received from clients, that has not yet been pushed.**/
	public var newData:Map<IConnection, PaddleData>;

	public function new(server:Server, id:Int)
	{
		super();
		maxConnections = 2;
		this.server = server;
		paddles = new Map();
		newData = new Map();
		score = new Map();

		ID = id;
	}

	override public function onJoin(connection:IConnection):Bool
	{
		if (super.onJoin(connection))
		{
			paddles.set(connection, server.connections.get(connection));
			score.set(connection, 0);
			var left = paddles.get(connection).left;
			connection.send('left', left);
			for (c in connections)
				if (c != connection)
					c.send('opponentJoined');

			if (connections.length > 1)
			{
				startGame();
				trace('startingGame');
			}
			return true;
		}
		else
		{
			trace('its broken');
			return false;
		}
	}

	override public function onLeave(connection:IConnection)
	{
		super.onLeave(connection);
	}

	var ticks:Int = 0;

	public function update(elapsed:Float)
	{
		if ((ticks++) % 4 == 0) // don't broadcast every frame, clients would end up getting a queue of packets to handle (LAG!!!!!)
		{
			var positions:Array<PaddleData> = [for (i in paddles) i];
			var data = {positions: positions};

			broadcast('movementUpdate', data);
		}
	}

	function startGame()
	{
		// Array of numbers to exclude from the random selection. Makes sure the ball does not go too vertical.
		var exc:Array<Int> = [
			for (i in 0...4)
				for (j in(i * 90) - 10...(i * 90) + 10)
				{
					var k = j;
					if (j > 0)
						k = 360 - j;
					k;
				}
		];

		// Picks a random number or angle, excluding the previous array
		var angle = Std.random(360);
		while (exc.contains(angle))
			angle = Std.random(360);

		broadcast('gameStart', angle);
	}

	public function updateScore()
	{
		var data:Array<{id:String, score:Int}> = [];
		for (connection in connections)
		{
			var d = {id: paddles.get(connection).id, score: score.get(connection)};
			data.push(d);
		}
		var exc:Array<Int> = [
			for (i in 0...4)
				for (j in(i * 90) - 10...(i * 90) + 10)
				{
					var k = j;
					if (j > 0)
						k = 360 - j;
					k;
				}
		];

		broadcast('updateScore', data);
		var angle = Std.random(360);
		while (exc.contains(angle))
			angle = Std.random(360);
		broadcast('spawnBall', {angle: angle, delay: 2});
	}
}
