package podstream;
import haxe.macro.Expr;
import haxe.macro.Context;

// typedef NetworkVariable = {name:String, type:String, redirection:String};
typedef NetworkVariable = {name:String, type:NetworkType, redirection:String};
typedef NetworkType = {
    name:String,
    unserialize:String->Array<Expr>,
    serialize:String->Array<Expr>
}


class SerializerMacro
{
    static public var classIds:Int = -1;
    static public var classSerializeIds:Int = -1;
    static public var serialized:Array<String> = new Array();

    static inline function getClassId():Int
        return ++classIds;

    static inline function getClassSerializedId():Int
        return ++classSerializeIds;

    static public function getSerialized():Array<String>
    {
        // PODSTREAM SERIALIZATION + -HAXE- SERIALIZED
        var serializedSerialized:String = haxe.Resource.getString("serialized");
        return haxe.Unserializer.run(serializedSerialized);
    }

    #if macro
    static public function _build(fields:Array<Field>, ?customTypes:Array<NetworkType>, ?className:String):Array<Field>
    {
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        // NETWORK TYPES
        if(customTypes == null) customTypes = [];
        var networkTypes:Array<NetworkType> = [];
        networkTypes = networkTypes.concat(customTypes);

        networkTypes.push({
            name:"Short",
            serialize: function(varNameOut:String) {
                return [macro bo.writeInt16(Std.int($i{varNameOut}))];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = bi.readInt16()];
            }
        });

        networkTypes.push({
            name:"Int",
            serialize: function(varNameOut:String) {
                return [macro bo.writeInt32(Std.int($i{varNameOut}))];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = bi.readInt32()];
            }
        });

        networkTypes.push({
            name:"Byte",
            serialize: function(varNameOut:String) {
                return [macro bo.writeByte(Std.int($i{varNameOut}))];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = bi.readByte()];
            }
        });

        networkTypes.push({
            name:"Float",
            serialize: function(varNameOut:String) {
                return [macro bo.writeByte(Std.int($i{varNameOut}))];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = bi.readByte()];
            }
        });

        networkTypes.push({
            name:"Bool",
            serialize: function(varNameOut:String) {
                return [macro ($i{varNameOut} == true) ? bo.writeByte(1) : bo.writeByte(0)];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = (bi.readByte() == 0) ? false : true];
            }
        });

        networkTypes.push({
            name:"String",
            serialize: function(varNameOut:String) {
                return [macro bo.writeInt16($i{varNameOut}.length),
                        macro bo.writeString($i{varNameOut})];
            },
            unserialize: function(varNameIn:String) {
                return [macro $i{varNameIn} = bi.readString(bi.readInt16())];
            }
        });

        // CONTEXT MIGHT NOT ALWAYS GIVE YOU THE RIGHT CLASS NAME
        // YOU CAN PASS THE CLASS NAME IN THAT CASE
        if(className == null) className = cls.name;

        #if debug trace("### PodStream Serialization: " + className + " ###"); #end

        // PROCESS EACH PARAMETER AND SAVE IT UP
        var networkVariables:Array<NetworkVariable> = new Array();
        for(f in fields)
        {
            if(f.meta.length != 0)
            {
                // META NET TYPES (can't be above because typemeta related to msgtypesmetas)
                for(m in f.meta)
                {
                    for(netType in networkTypes)
                    {
                        if(m.name == netType.name)
                        {
                            var netVar:NetworkVariable = {name:f.name,
                                                          type:netType,
                                                          redirection:null};

                            if(m.params.length != 0)
                            {
                                switch(m.params[0].expr)
                                {
                                    case EConst(CString(redirection)):
                                        netVar.redirection = redirection;
                                    case _:
                                }
                            }

                            networkVariables.push(netVar);
                        }
                    }
                }
            }
        }
        
        // ASSIGN ID
        var id = getClassId();

        // ADDS ID TO OBJECT & CLASS
        // WORKAROUND: Since there is already _sid & __sid
        // but useful when non-serializable objects ID are needed
        var def = macro class {public var _id:Int = $v{id};
                               public static var __id:Int = $v{id}};
        fields = fields.concat(def.fields);
        #if debug trace("ID assigned: " + id); #end
        
        haxe.macro.Context.onGenerate(function(types)
        {
            Context.addResource("serialized", haxe.io.Bytes.ofString(haxe.Serializer.run(serialized)));
        });

        if(networkVariables.length == 0)
        {
            #if debug trace('No serialization for $className, abort'); #end
            return fields;
        }


        ////////////////////////////////////////////
        // RETURN HERE PLEASE DONT FORGET HIM :'( //
        ////////////////////////////////////////////


        // ADDS ID TO __ SERIALIZED __ OBJECT & CLASS
        var sid = getClassSerializedId();
        var def = macro class {public var _sid:Int = $v{sid};
                               public static var __sid:Int = $v{sid}};
        fields = fields.concat(def.fields);


        // ADD CLASS TO ARRAY
        serialized.push(className);

        #if debug trace("networkVariables " + networkVariables); #end

        var inExprlist:Array<Expr> = [];
        var outExprlist:Array<Expr> = [];

        for(netVar in networkVariables)
        {
            var varNameOut = netVar.name;
            var varNameIn = netVar.name;
            if(netVar.redirection != null) varNameIn = netVar.redirection;
            var varType = netVar.type;

            outExprlist = outExprlist.concat(netVar.type.serialize(varNameOut));
            inExprlist = inExprlist.concat(netVar.type.unserialize(varNameIn));
            // outExprlist = netVar.type.serialize(varNameOut);
            // inExprlist = netVar.type.unserialize(varNameIn);
        }

        var serializationCls = macro class {
            public function unserialize(bi)
                $b{inExprlist};
            public function serialize(bo)
                $b{outExprlist};
        };

        fields = fields.concat(serializationCls.fields);

        for(f in fields)
        {
            #if debug trace("Podstream class view : " + new haxe.macro.Printer().printField(f)); #end
        }

        return fields;
    }
    #end

    macro static public function build():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();
        fields = _build(fields);

        return fields;
    }

}