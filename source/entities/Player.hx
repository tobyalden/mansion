package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Player extends Entity
{
    public static inline var SPEED = 100;

    private var velocity:Vector2;

    public function new() {
        super();
        Key.define("up", [Key.UP, Key.I]);
        Key.define("down", [Key.DOWN, Key.K]);
        Key.define("left", [Key.LEFT, Key.J]);
        Key.define("right", [Key.RIGHT, Key.L]);
        graphic = new Image("graphics/player.png");
        velocity = new Vector2();
    }

    override public function update() {
        movement();
        super.update();
    }

    private function movement() {
        if(Input.check("left")) {
            velocity.x = -SPEED;
        }
        else if(Input.check("right")) {
            velocity.x = SPEED;
        }
        else {
            velocity.x = 0;
        }
        if(Input.check("up")) {
            velocity.y = -SPEED;
        }
        else if(Input.check("down")) {
            velocity.y = SPEED;
        }
        else {
            velocity.y = 0;
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
    }
}
