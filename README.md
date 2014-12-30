PODStream
=========

PODStream will serialize and deserialize your fields from/to a `ByteArray`.

Given a position component such as:

```Haxe
@:build(podstream.SerializerMacro.build())
class Position
{
    @Short public var x:Float;
    @Short public var y:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
}
```

You can prefix your fields with:
* `@Short`
* `@Int`
* `@Float`
* `@Bool`
* `@Byte`
* `@String`

Note: Arrays are not supported.

In the example above the haxe macro will generate two methods which will transform your class to:

```Haxe
class Position
{
    public var _id:Int = 0;
    public static var _id:Int = 0;
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

## Redirections

You can redirect deserializations to other variables such as:

`@Short('netx') var x:Float;`

In this case the variable `x` will be serialized as a Short but will be unserialized and assigned to the variable `netx`. It can be helpful when you are sharing the same class between a client & a server.

### Example

```Haxe
@:build(podstream.SerializerMacro.build())
class Position2
{
    @Short("netx") public var x:Float;
    @Short("nety") public var y:Float;
    public var netx:Float;
    public var nety:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
}
```

will generate:

```Haxe
class Position2
{
    public var _id:Int = 1;
    public static var _id:Int = 1;
    public var x:Float;
    public var y:Float;
    public var netx:Float;
    public var nety:Float;

    public function new(x:Float, y:Float)
    {
        this.x = x;
        this.y = y;
    }
    
    public function unserialize(bi)
    {
        netx = bi.readInt16();
        nety = bi.readInt16();
    }
    
    public function serialize(bo)
    {
        bo.writeInt16(Std.int(x));
        bo.writeInt16(Std.int(y));
    }
}
```

## ID generation

Each serialized class will be assigned a unique public & static ID such as `myInstance._id` and `MyClass.__id`.

## Serialization datas

You can call `podstream.SerializerMacro.getSerialized()` from your application and get an Array of String of the types serialized.

You can then use `Type.resolveClass(YourClass)` to resolve the type from the string returned if needed.