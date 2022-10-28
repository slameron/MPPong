package server;

import mphx.connection.IConnection;
import mphx.server.impl.Server as MPHXServer;

typedef PaddleData =
{
	?y:Float,
	?vy:Float,
	id:String,
	left:Bool,
	room:Int
}

class Server
{
	public var connections:Map<IConnection, PaddleData>;

	var rooms:Map<Int, Room> = [];

	var server:MPHXServer;
	var ip:String = '127.0.0.1';
	var port:Int = 8000;

	public function new(?ip:String, ?port:Int)
	{
		if (ip != null)
			this.ip = ip;
		if (port != null)
			this.port = port;

		server = new MPHXServer(ip, port);

		connections = new Map();

		server.onConnectionAccepted = function(reason:String, connection:mphx.connection.IConnection) trace("A client joined the game. " + reason);

		server.onConnectionClose = function(reason:String, connection:mphx.connection.IConnection)
		{
			trace("A client disconnected from the game. " + reason);

			if (connection.room != null)
			{
				connection.room.broadcast('clientDisconnect');
				connection.room.onLeave(connection);
			}

			connections.remove(connection);
		}

		server.events.on('score', function(data:Dynamic, connection:IConnection)
		{
			cast(connection.room, Room).score.set(connection, cast(connection.room, Room).score.get(connection) + 1);

			cast(connection.room, Room).updateScore();
		});
		server.events.on('join', function(data:Dynamic, connection:IConnection)
		{
			if (connections[connection] != null)
				return;

			var lobbyRoom:Room = null;
			for (room in server.rooms)
			{
				if ((room.connections.length < room.maxConnections || room.maxConnections == -1))
				{
					lobbyRoom = cast(room, Room);
					break;
				}
			}
			if (lobbyRoom != null)
			{
				// There is a lobby room we can join - join it!

				var left = lobbyRoom.connections.length % 2 == 0;
				connections.set(connection, {room: lobbyRoom.ID, id: data.id, left: left});
				connection.putInRoom(lobbyRoom);
				trace('putting $connection in lobby ${lobbyRoom.ID}');
			}
			else
			{
				// There is not a lobby room - create one!
				var exc:Array<Int> = [];

				for (id in rooms.keys())
					exc.push(id);

				var rand:Int = Std.random(9999);
				while (exc.contains(rand))
					rand = Std.random(9999);

				var room = new Room(this, rand);
				server.rooms.push(room);
				rooms.set(room.ID, room);
				var left = room.connections.length % 2 == 0;
				connections.set(connection, {room: room.ID, id: data.id, left: left});
				connection.putInRoom(room);
				trace('putting $connection in lobby ${room.ID}');
			}
		});
		server.events.on('movementUpdate', function(data:Dynamic, client:IConnection)
		{
			var clientData = cast(client.room, Room).paddles.get(client);
			clientData.y = data.y;
			// clientData.vy = data.vy;
			cast(client.room, Room).newData.set(client, clientData);
		});

		startServer();
	}

	function startServer()
	{
		server.listen();
		trace('Server started on $ip:$port');

		var time = haxe.Timer.stamp();
		while (true)
		{
			server.update();
			update(haxe.Timer.stamp() - time);

			time = haxe.Timer.stamp();
			Sys.sleep(0.01); // wait for 1 ms to prevent full cpu usage. (0.01)
		}
	}

	public function update(elapsed:Float)
	{
		for (room in server.rooms)
		{
			if (room.connections.length == 0)
			{
				server.rooms.remove(room);
				continue;
			}

			cast(room, Room).update(elapsed);
		}
	}

	public static function main()
	{
		try
		{
			Sys.println('Enter the IP address to host on. Leave empty for localhost.');
			var ip = Sys.stdin().readLine();
			var port:Int = -99;
			if (ip.length <= 1)
				ip = '127.0.0.1';

			if (StringTools.contains(ip, ':'))
			{
				var split = ip.split(':');
				ip = split[0];
				port = Std.parseInt(split[1]);
			}
			if (port == -99)
			{
				Sys.println('Enter the port to host on. Leave empty for 8000.');
				var tmpPort = Sys.stdin().readLine();

				if (tmpPort.length <= 1)
					port = 8000;
				else
					port = Std.parseInt(tmpPort);
			}
			new Server(ip, port);
		}
		catch (e)
		{
			trace(e);
		}
	}
}
