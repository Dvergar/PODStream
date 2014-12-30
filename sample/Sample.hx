@:build(podstream.SerializerMacro.build())
class Position
{
    @Short public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
}


class Sample
{
	public function new()
	{
		trace("hello");

		trace(podstream.SerializerMacro.getSerialized());
	}

	static public function main()
	{
		new Sample();
	}
}