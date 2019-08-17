package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Viewport extends Entity
{
    public static inline var STAMINA_BAR_LENGTH = 200;

    private var staminaBar:ColoredRect;
    private var healthBar:Image;

    public function new(sceneCamera:Camera) {
        super();
        addGraphic(new Image("graphics/viewport.png"));

        staminaBar = new ColoredRect(STAMINA_BAR_LENGTH, 25, 0x008B00);
        staminaBar.x = 382;
        staminaBar.y = 100;
        addGraphic(staminaBar);

        for(i in 1...Std.int(Math.floor(Player.MAX_STAMINA / Player.CAST_COST))) {
            var marker = new ColoredRect(2, 25, 0xFFFFFF);
            marker.x = (
                staminaBar.x
                + Player.CAST_COST * i
                * (STAMINA_BAR_LENGTH / Player.MAX_STAMINA)
            );
            marker.y = staminaBar.y;
            addGraphic(marker);
        }

        healthBar = new Image("graphics/hearts.png");
        healthBar.x = 382;
        healthBar.y = 45;
        addGraphic(healthBar);

        layer = -1;
        followCamera = sceneCamera;
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        staminaBar.width = (
            player.stamina / Player.MAX_STAMINA * STAMINA_BAR_LENGTH
        );
        healthBar.clipRect = new Rectangle(0, 0, 25 * player.health, 25);
        super.update();
    }
}
