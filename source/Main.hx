import haxepunk.*;
import haxepunk.debug.Console;
import scenes.*;

class Main extends Engine
{
    static function main() {
        new Main();
    }

    override public function init() {
#if debug
        Console.enable();
#end
        HXP.scene = new GameScene();
    }

	override public function update() {
        super.update();
    }
}
