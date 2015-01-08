@:build(podstream.SerializerMacro.build())
class Position
{
    @Short public var x:Float;
    @Short public var y:Float;

    public function new() {}
}


@:build(podstream.SerializerMacro.build())
class Vector
{
    @Short("netx") public var x:Float = 0;
    @Short("nety") public var y:Float = 0;
    public var netx:Float;
    public var nety:Float;

    public function new() {}
}


class Sample
{
	public function new()
	{
		trace(podstream.SerializerMacro.getSerialized());

		// POSITION DATAS
		var pos = new Position();
		pos.x = 100;
		pos.y = 100;

		trace("pos _id: " + pos._id);
		trace("pos _sid: " + pos._sid);

		//// OUTPUT STREAM
		var bo = new haxe.io.BytesOutput();

		//// POSITION SERIALIZATION
		pos.serialize(bo);

		//// INPUT STREAM
		var bi = new haxe.io.BytesInput(bo.getBytes());

		//// POSITION UNSERIALIZATION
		var pos2 = new Position();
		pos2.unserialize(bi);
		trace("pos2.x:" + pos2.x);
		trace("pos2.y:" + pos2.y);


		// VECTOR DATAS
		var vec = new Vector();
		vec.x = 100;
		vec.y = 100;

		// OUTPUT STREAM
		var bo = new haxe.io.BytesOutput();

		// VECTOR SERIALIZATION
		vec.serialize(bo);

		// INPUT STREAM
		var bi = new haxe.io.BytesInput(bo.getBytes());

		//// VECTOR UNSERIALIZATION (with redirection)
		var vec2 = new Vector();
		vec2.unserialize(bi);
		trace("vec2.x: " + vec2.x); // default
		trace("vec2.y: " + vec2.y); // default
		trace("vec2.netx: " + vec2.netx); // serialized from x to netx
		trace("vec2.nety: " + vec2.nety); // serialized from y to nety
	}

	static public function main()
	{
		new Sample();
	}
}