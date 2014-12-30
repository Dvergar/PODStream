package podstream;
import haxe.macro.Expr;
import haxe.macro.Context;

typedef NetworkVariable = {name:String, type:String, redirection:String};


class SerializerMacro
{
    static public var componentIds:Int = -1;
    static public var componentSerializeIds:Int = -1;
    static public var serialized:Array<String> = new Array();

    static inline function getComponentId():Int
    {
        componentIds++;
        return componentIds;
    }

    static inline function getComponentSerializedId():Int
    {
        componentSerializeIds++;
        return componentSerializeIds;
    }

    static public function getSerialized():Array<String>
    {
        // PODSTREAM SERIALIZATION + -HAXE- SERIALIZED
        var serializedSerialized:String = haxe.Resource.getString("serialized");
        return haxe.Unserializer.run(serializedSerialized);
    }

    #if macro
    static public function _build(fields:Array<Field>, ?componentName:String):Array<Field>
    {
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        // CONTEXT MIGHT NOT ALWAYS GIVE YOU THE RIGHT COMPONENT NAME
        // YOU CAN PASS THE COMPONENT NAME IN THAT CASE
        var componentName = componentName;
        if(componentName == null) componentName = cls.name;

        #if debug trace("### PodStream Serialization: " + componentName + " ###"); #end

        // PROCESS EACH PARAMETER AND SAVE IT UP
        var networkVariables:Array<NetworkVariable> = new Array();
        for(f in fields)
        {
            if(f.meta.length != 0)
            {
                // META NET TYPES (can't be above because typemeta related to msgtypesmetas)
                for(m in f.meta)
                {
                    if(m.name == "Short" ||
                       m.name == "Int" ||
                       m.name == "Float" ||
                       m.name == "Bool" ||
                       m.name == "Byte" ||
                       m.name == "String")
                    {
                        var netVar:NetworkVariable = {name:f.name,
                                                      type:m.name,
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
                    else
                    {
                        Context.error("Not a network type : " + m.name, pos);
                    }
                }
            }
        }
        
        // ASSIGN ID
        var id = getComponentId();

        // ADDS ID TO OBJECT & CLASS
        #if debug trace("ID assigned: " + id); #end
        fields.push({kind: FVar(TPath({name: "Int", pack: [], params: [] }),
                                      {expr: EConst(CInt(Std.string(id))), pos : pos }),
                     meta: [], name: "_id", doc: null, pos: pos, access: [APublic] });

        fields.push({kind: FVar(TPath({name: "Int", pack: [], params: [] }),
                                      {expr: EConst(CInt(Std.string(id))), pos : pos }),
                     meta: [], name: "__id", doc: null, pos: pos, access: [APublic, AStatic] });

        
        haxe.macro.Context.onGenerate(function(types)
        {
            Context.addResource("serialized", haxe.io.Bytes.ofString(haxe.Serializer.run(serialized)));
        });

        if(networkVariables.length == 0)
        {
            #if debug trace('No serialization for $componentName, abort'); #end
            return fields;
        }


        ////////////////////////////////////////////
        // RETURN HERE PLEASE DONT FORGET HIM :'( //
        ////////////////////////////////////////////


        // ADDS ID TO __ SERIALIZED __ OBJECT & CLASS
        var sid = getComponentSerializedId();
        fields.push({kind: FVar(TPath({name: "Int", pack: [], params: [] }),
                                      {expr: EConst(CInt(Std.string(sid))), pos : pos }),
                     meta: [], name: "_sid", doc: null, pos: pos, access: [APublic] });

        fields.push({kind: FVar(TPath({name: "Int", pack: [], params: [] }),
                                      {expr: EConst(CInt(Std.string(sid))), pos : pos }),
                     meta: [], name: "__sid", doc: null, pos: pos, access: [APublic, AStatic] });


        // ADD COMPONENT TO ARRAY
        serialized.push(componentName);

        #if debug trace("networkVariables " + networkVariables); #end

        var inExprlist = [];
        var outExprlist = [];

        for(netVar in networkVariables)
        {
            var varNameOut = netVar.name;
            var varNameIn = netVar.name;
            if(netVar.redirection != null) varNameIn = netVar.redirection;
            var varType = netVar.type;

            var ein;
            var eout;

            switch(varType)
            {
                case "Short":
                    outExprlist.push( macro bo.writeInt16(Std.int($i{varNameOut})) );
                    inExprlist.push( macro $i{varNameIn} = bi.readInt16() );
                case "Int":
                    outExprlist.push( macro bo.writeInt32(Std.int($i{varNameOut})) );
                    inExprlist.push( macro $i{varNameIn} = bi.readInt32() );
                case "Byte":
                    outExprlist.push( macro bo.writeByte(Std.int($i{varNameOut})) );
                    inExprlist.push( macro $i{varNameIn} = bi.readByte() );
                case "Float":
                    outExprlist.push( macro bo.writeFloat($i{varNameOut}) );
                    inExprlist.push( macro $i{varNameIn} = bi.readFloat() );
                case "Bool":
                    outExprlist.push( macro ($i{varNameOut} == true) ? bo.writeByte(1) : bo.writeByte(0) );
                    inExprlist.push( macro $i{varNameIn} = (bi.readByte() == 0) ? return false : return true );
                case "String":
                    outExprlist.push( macro bo.writeInt16($i{varNameOut}.length) );
                    outExprlist.push( macro bo.writeString($i{varNameOut}) );
                    inExprlist.push( macro $i{varNameIn} = bi.readString(bi.readInt16()) );
            }
        }

        // IN
        var arg = {name:"bi", type:null, opt:false, value:null};

        var func = {args:[arg],
                    ret:null,
                    params:[],
                    expr:{expr:EBlock(inExprlist), pos:pos}};

        fields.push({name: "unserialize",
                     doc: null,
                     meta: [],
                     access: [APublic],
                     kind: FFun(func),
                     pos: pos});

        // OUT
        var arg = {name:"bo", type:null, opt:false, value:null};

        var func = {args:[arg],
                    ret:null,
                    params:[],
                    expr:{expr:EBlock(outExprlist), pos:pos}};

        fields.push({name: "serialize",
                     doc: null,
                     meta: [],
                     access: [APublic],
                     kind: FFun(func),
                     pos: pos});

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