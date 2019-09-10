package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.math.*;

class Viewport extends Entity
{
    public static inline var BOSS_HEALTH_BAR_LENGTH = 200;
    public static inline var THOUGHT_CONSOLE_WIDTH = 236;
    public static inline var THOUGHT_CONSOLE_HEIGHT = 100;

    private var healthBar:Image;
    private var bossHealthBar:ColoredRect;
    private var flaskCount:Text;
    private var thoughtConsole:Text;
    private var thoughtConsoleBox:ColoredRect;

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

        //thoughtConsoleBox = new ColoredRect(
            //THOUGHT_CONSOLE_WIDTH, THOUGHT_CONSOLE_HEIGHT, 0x000000
        //);
        //thoughtConsoleBox.x = 370;
        //thoughtConsoleBox.y = 200;
        //addGraphic(thoughtConsoleBox);

        //thoughtConsole = new Text(
            //"I have many thoughts.",
            //0, 0, THOUGHT_CONSOLE_WIDTH - 20, BOX_HEIGHT
        //);
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
