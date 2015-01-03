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
    @Short("netx") public var x:Float;
    @Short("nety") public var y:Float;
    public var netx:Float;
    public var nety:Float;

    public function new() {}
}


class Sample
{
	public function new()
	{
		trace(podstream.SerializerMacro.getSerialized());

		var pos = new Position();
		pos.x = 100;
		pos.y = 100;

		trace("pos _id: " + pos._id);
		trace("pos _sid: " + pos._sid);

		var bo = new haxe.io.BytesOutput();
		pos.serialize(bo);

		var bi = new haxe.io.BytesInput(bo.getBytes());
		var pos2 = new Position();
		pos2.unserialize(bi);
		trace(pos2.x);
		trace(pos2.y);
	}

	static public function main()
	{
		new Sample();
	}
}