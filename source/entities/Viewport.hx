package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.math.*;
import scenes.*;

class Viewport extends Entity
{
    public static inline var BOSS_HEALTH_BAR_WIDTH = 241;
    public static inline var BOSS_HEALTH_BAR_HEIGHT = 104;
    public static inline var THOUGHT_CONSOLE_WIDTH = 236;
    public static inline var THOUGHT_CONSOLE_HEIGHT = 100;

    private var hearts:Spritemap;
    private var heals:Spritemap;
    private var bossHealthBar:Image;
    private var thoughtConsole:Text;
    private var thoughtConsoleBox:ColoredRect;

    public function new(sceneCamera:Camera) {
        super();
        addGraphic(new Image('graphics/viewport${
            GameScene.isHardMode ? 'hard' : 'normal'
        }.png'));

        hearts = new Spritemap('graphics/hearts${
            GameScene.isHardMode ? 'hard' : 'normal'
        }.png', HXP.width, HXP.height);
        var numHearts = GameScene.isHardMode ? 3 : 5;
        for(i in 0...(numHearts + 1)) {
            hearts.add('${i}', [i]);
        }
        addGraphic(hearts);

        heals = new Spritemap('graphics/heals${
            GameScene.isHardMode ? 'hard' : 'normal'
        }.png', HXP.width, HXP.height);
        var numHeals = GameScene.isHardMode ? 3 : 5;
        for(i in 0...(numHeals + 1)) {
            heals.add('${i}', [i]);
        }
        addGraphic(heals);

        bossHealthBar = new Image("graphics/bosshealthbar.png");
        bossHealthBar.x = 374;
        bossHealthBar.y = 256;
        addGraphic(bossHealthBar);

        layer = -99;
        followCamera = sceneCamera;
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        hearts.play('${player.health}');
        heals.play('${player.flaskCount}');
        var gameScene = cast(scene, GameScene);
        var bossName = gameScene.getCurrentBossName();
        var _boss = cast(scene.getInstance(bossName));
        if(_boss != null) {
            var boss = cast(_boss, Enemy);
            var currentHealth = boss.health;
            var startingHealth:Int;
            if(bossName == "superwizard") {
                startingHealth = SuperWizard.STARTING_HEALTH;
            }
            else if(bossName == "ringmaster") {
                startingHealth = RingMaster.STARTING_HEALTH;
            }
            else if(bossName == "grandjoker") {
                startingHealth = GrandJoker.STARTING_HEALTH;
            }
            else {
                startingHealth = Grandfather.STARTING_HEALTH;
            }
            var fullHealth = (
                GameScene.isNightmare
                ? Std.int(
                    startingHealth * GameScene.NIGHTMARE_HEALTH_MULTIPLIER
                )
                : startingHealth
            );
            bossHealthBar.visible = true;
            bossHealthBar.clipRect = new Rectangle(
                BOSS_HEALTH_BAR_WIDTH * (1 - currentHealth / fullHealth),
                0,
                BOSS_HEALTH_BAR_WIDTH * (currentHealth / fullHealth),
                BOSS_HEALTH_BAR_HEIGHT
            );
        }
        else {
            bossHealthBar.visible = false;
        }
        super.update();
    }
}
