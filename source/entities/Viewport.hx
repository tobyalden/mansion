package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Viewport extends Entity
{
    public function new(sceneCamera:Camera) {
        super();
        graphic = new Image("graphics/viewport.png");
        layer = -1;
        followCamera = sceneCamera;
    }

    override public function update() {
        super.update();
    }
}
