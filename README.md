PODStream
=========

PODStream will serialize and deserialize your fields from/to a `ByteArray`.

Given a position component such as:

```Haxe
@:build(podstream.SerializerMacro.build())
class CPosition
{
    @short public var x:Float;
    @short public var y:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
}
```

You can prefix your fields with:
* `@short`
* `@int`
* `@float`
* `@bool`
* `@byte`
* `@string`

Note: Arrays are not supported.

In the example above the haxe macro will generate two methods which will transform your component to:

```Haxe
class CPosition
{
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
    
    public function unserialize(bi)
    {
        x = bi.readInt16();
        y = bi.readInt16();
    }
    
    public function serialize(bo)
    {
        bo.writeInt16(Std.int(x));
        bo.writeInt16(Std.int(y));
    }
}
```

The library is used in two steps:
* Mark your fields with the appropriate serialization
* Pass your ByteArray around
