package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.math.*;

class Viewport extends Entity
{
    public static inline var BOSS_HEALTH_BAR_LENGTH = 200;

    private var healthBar:Image;
    private var bossHealthBar:ColoredRect;
    private var flaskCount:Text;

    public function new(sceneCamera:Camera) {
        super();
        addGraphic(new Image("graphics/viewport.png"));

        healthBar = new Image("graphics/hearts.png");
        healthBar.x = 382;
        healthBar.y = 45;
        addGraphic(healthBar);

        bossHealthBar = new ColoredRect(BOSS_HEALTH_BAR_LENGTH, 25, 0xB68FFF);
        bossHealthBar.x = 382;
        bossHealthBar.y = 100;
        addGraphic(bossHealthBar);

        layer = -99;
        followCamera = sceneCamera;

        flaskCount = new Text("", 382, 150);
        addGraphic(flaskCount);
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        healthBar.clipRect = new Rectangle(0, 0, 25 * player.health, 25);
        var _boss = cast(scene.getInstance("ringmaster"));
        if(_boss != null) {
            var boss = cast(_boss, RingMaster);
            bossHealthBar.width = (
                boss.health / RingMaster.STARTING_HEALTH
                * BOSS_HEALTH_BAR_LENGTH
            );
        }
        flaskCount.text = 'FLASKS: ${player.flaskCount}';
        super.update();
    }
}
