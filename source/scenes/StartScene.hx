package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import entities.*;
import openfl.Assets;

class StartScene extends Scene
{
    private var startSound:Sfx;

    override public function begin() {
        Key.define("start", [Key.Z]);
        startSound = new Sfx("audio/start.wav");
    }    

    override public function update() {
        if(Input.pressed("start")) {
            startSound.play();
            HXP.scene = new GameScene();
        }
        super.update();
    }
}
