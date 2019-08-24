package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.tweens.motion.*;
import haxepunk.utils.*;
import scenes.*;

class Ring extends Entity {
    private var ringMaster:RingMaster;
    private var sprite:Spritemap;
    private var tosser:CubicMotion;

    public function new(ringMaster:RingMaster) {
        super();
        this.ringMaster = ringMaster;
        type = "hazard";
        sprite = new Spritemap("graphics/ring.png", 40, 40);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        mask = new Circle(20);
        collidable = false;
        tosser = new CubicMotion();
        addTween(tosser);
    }

    private function getCurveControlPoint(target:Entity, flip:Bool) {
        var towardsPlayer = new Vector2(
            target.centerX - centerX, target.centerY - centerY
        );
        var offset = towardsPlayer.clone();
        offset.perpendicular();
        offset.scale(1.5);
        if(flip) {
            offset.inverse();
        }
        towardsPlayer.scale(1.35);
        towardsPlayer.add(offset);
        return towardsPlayer;
    }

    public function toss() {
        if(!tosser.active) {
            var player = scene.getInstance("player");
            var controlPointA = getCurveControlPoint(player, false);
            var controlPointB = getCurveControlPoint(player, true);
            tosser.setMotion(
                x, y,
                x + controlPointA.x, y + controlPointA.y,
                x + controlPointB.x, y + controlPointB.y,
                x, y,
                MathUtil.clamp(distanceFrom(player, true) / 50, 1.5, 2),
                Ease.sineInOut
            );
            trace(distanceFrom(player, true));

            //23 -> 230
            tosser.start();
        }
    }

    override public function update() {
        if(tosser.active) {
            moveTo(tosser.x, tosser.y);
        }
        else {
            moveTo(
                ringMaster.centerX - width / 2,
                ringMaster.centerY - height / 2
            );
        }
        super.update();
    }
}

