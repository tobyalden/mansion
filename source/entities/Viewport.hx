package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Viewport extends Entity
{
    public static inline var STAMINA_BAR_LENGTH = 200;

    private var staminaBar:ColoredRect;
    private var rollMarker:ColoredRect;

    public function new(sceneCamera:Camera) {
        super();
        addGraphic(new Image("graphics/viewport.png"));
        staminaBar = new ColoredRect(STAMINA_BAR_LENGTH, 25, 0x008B00);
        staminaBar.x = 382;
        staminaBar.y = 45;
        addGraphic(staminaBar);
        rollMarker = new ColoredRect(2, 25, 0xFFFFFF);
        rollMarker.x = (
            382 + (Player.ROLL_COST / Player.MAX_STAMINA) * STAMINA_BAR_LENGTH
        );
        rollMarker.y = 45;
        addGraphic(rollMarker);
        layer = -1;
        followCamera = sceneCamera;
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        staminaBar.width = (
            player.stamina / Player.MAX_STAMINA * STAMINA_BAR_LENGTH
        );
        //staminaBar.color = (
            //player.stamina >= Player.ROLL_COST ? 0x008B00 : 0x8B0000
        //);
        super.update();
    }
}
