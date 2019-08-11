package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import entities.*;

class GameScene extends Scene
{
    public static inline var PLAYFIELD_SIZE = 320;

    private var player:Player;

    override public function begin() {
        player = new Player(50, 50);
        add(player);
        add(new Level());
        add(new Viewport(camera));
        camera.x = -20;
        camera.y = -20;
    }

    override public function update() {
        camera.x = (
            Math.floor((player.centerX) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - 20
        );
        camera.y = (
            Math.floor((player.centerY) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - 20
        );
        super.update();
    }
}
