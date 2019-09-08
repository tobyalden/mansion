package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.tweens.motion.*;
import haxepunk.utils.*;
import scenes.GameScene;

class DisplayMap extends Entity
{
    public static inline var TILE_SIZE = 1;

    private var fullLayout:Grid;
    private var fullLayoutTiles:Tilemap;
    private var revealedTiles:Tilemap;
    private var playerIndicator:Spritemap;

    public function new(fullLayout:Grid, sceneCamera:Camera) {
        super();
        Key.define("showmap", [Key.TAB, Key.M]);
        this.fullLayout = fullLayout;
        layer = -999;
        followCamera = sceneCamera;
        fullLayoutTiles = new Tilemap(
            "graphics/displaymaptiles.png",
            fullLayout.columns * TILE_SIZE,
            fullLayout.rows * TILE_SIZE,
            TILE_SIZE, TILE_SIZE
        );
        revealedTiles = new Tilemap(
            "graphics/displaymaptiles.png",
            fullLayout.columns * TILE_SIZE,
            fullLayout.rows * TILE_SIZE,
            TILE_SIZE, TILE_SIZE
        );
        for(tileX in 0...fullLayout.columns) {
            for(tileY in 0...fullLayout.rows) {
                if(fullLayout.getTile(tileX, tileY)) {
                    fullLayoutTiles.setTile(tileX, tileY, 1);
                }
            }
        }
        var background = new Image("graphics/displaymapbackground.png");
        playerIndicator = new Spritemap(
            "graphics/displaymapplayerindicator.png", 24, 24
        );
        playerIndicator.add("idle", [0, 1], 4);
        playerIndicator.play("idle");


        addGraphic(background);
        fullLayoutTiles.x = (background.width - fullLayoutTiles.width) / 2;
        fullLayoutTiles.y = (background.height - fullLayoutTiles.height) / 2;
        revealedTiles.x = (background.width - fullLayoutTiles.width) / 2;
        revealedTiles.y = (background.height - fullLayoutTiles.height) / 2;
        //fullLayoutTiles.alpha = 0.4;
        //addGraphic(fullLayoutTiles);
        addGraphic(revealedTiles);
        addGraphic(playerIndicator);
        graphic.x = 20;
        graphic.y = 20;
    }

    override public function update() {
        visible = Input.check("showmap");
        var gameScene = cast(scene, GameScene);
        playerIndicator.x = (
            gameScene.currentScreenX * 20 + fullLayoutTiles.x - 2
        );
        playerIndicator.y = (
            gameScene.currentScreenY * 20 + fullLayoutTiles.y - 2
        );
        for(tileX in 0...20) {
            for(tileY in 0...20) {
                var revealedTileX = gameScene.currentScreenX * 20 + tileX;
                var revealedTileY = gameScene.currentScreenY * 20 + tileY;
                if(fullLayout.getTile(revealedTileX, revealedTileY)) {
                    revealedTiles.setTile(revealedTileX, revealedTileY, 1);
                }
            }
        }
        super.update();
    }
}

