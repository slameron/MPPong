package client;

class Client extends mphx.client.Client
{
	public var isReady:Bool = false;
	public var id:String;

	public var connectionEstablished:() -> Void;
	public var connectionError:String->Void;

	override public function new(ip:String, port:Int, id:String)
	{
		super(ip, port);
		this.id = id;

		onConnectionEstablished = function()
		{
			trace('Client connection established');
			isReady = true;
			if (connectionEstablished != null)
				connectionEstablished();
		};
	}

	public function start():Client
	{
		connect();
		return this;
	}

	override function connect()
	{
		var error:Bool = false;
		var errorMessage:String = '';

		try
		{
			onConnectionError = function(s:Dynamic)
			{
				error = true;
				trace(s);
				errorMessage = s;

				if (connectionError != null)
					connectionError(s);
			}

			super.connect();
		}
		catch (e:Dynamic)
		{
			trace(e);
			error = true;
			errorMessage = e;
		}
	}
}
