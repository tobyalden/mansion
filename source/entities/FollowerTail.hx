package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class FollowerTail extends Entity {
    public var head(default, null):Enemy;

    public function new(x:Float, y:Float, head:Enemy) {
        super(x, y);
        this.head = head;
        type = "tail";
        mask = new Circle(9);
        graphic = new Image("graphics/followertail.png");
    }

    public function die() {
        scene.remove(this);
        explode();
    }

    private function explode(
        numExplosions:Int = 2, speed:Float = 600, goQuickly:Bool = true,
        goSlowly:Bool = false
    ) {
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2/numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(speed * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            var explosion = new DeathParticle(
                centerX, centerY, directions[count], goQuickly, goSlowly
            );
            explosion.layer = -99;
            scene.add(explosion);
            count++;
        }
    }
}
