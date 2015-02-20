import haxe.macro.Expr;
import haxe.macro.Context;


class MyMacro
{
    macro static public function build():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();

        var EntityType = {
            name:"Entity",
            serialize: function(varNameOut:String) {
                return [macro trace("lol")];
            },
            unserialize: function(varNameIn:String) {
                return [macro trace("unserialize")];
            }
        };


        fields = podstream.SerializerMacro._build(fields, [EntityType]);

        return fields;
    }
}