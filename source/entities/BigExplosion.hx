package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.Spritemap;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class BigExplosion extends Entity {

    public static inline var SIZE = 32;

    public function new(source:Entity) {
        super(
            source.x + source.width * HXP.choose(1, 0.25, 0.5, 0.75) - SIZE / 2,
            source.y + source.height * HXP.choose(1, 0.25, 0.5, 0.75) - SIZE / 2
        );
        var sprite = new Spritemap("graphics/bigexplosion.png", 32, 32);
        sprite.add("idle", [0, 1, 2, 3, 4], 12);
        sprite.play("idle");
        sprite.onAnimationComplete.bind(function(_:Animation) {
            scene.remove(this);
        });
        graphic = sprite;
    }
}

