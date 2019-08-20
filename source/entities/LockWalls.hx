package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.*;


class LockWalls extends Entity {
    public var level(default, null):Level;
    private var sprite:Tilemap;

    public function new(x:Float, y:Float, level:Level) {
        super(x, y);
        this.level = level;
        this.sprite = level.lockTiles;
        type = "unlock";
        mask = level.lockWalls;
        graphic = sprite;
        sprite.alpha = 0;
    }

    override public function update() {
        var player = scene.getInstance("player");
        if(
            collideWith(player, x, y) == null
            && level.getAliveEnemyCount() > 0
            && cast(scene, GameScene).getLevelFromEntity(player) == level
            && cast(scene, GameScene).isLevelLocked
        ) {
            sprite.alpha = 1;
            type = "lock";
        }
        else {
            sprite.alpha = 0;
            type = "unlock";
        }
        super.update();
    }
}
