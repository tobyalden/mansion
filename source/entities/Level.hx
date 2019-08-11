package entities;

import haxepunk.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import openfl.Assets;

class Level extends Entity
{
    public static inline var TILE_SIZE = 16;

    private var walls:Grid;
    private var tiles:Tilemap;

    public function new() {
        super();
        type = "walls";

        loadLevel("testlevel");

        tiles = new Tilemap(
            'graphics/tiles.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        tiles.loadFromString(walls.saveToString(',', '\n', '1', '0'));

        graphic = tiles;
        mask = walls;
    }

    private function loadLevel(levelName:String) {
        var xml = Xml.parse(Assets.getText('levels/${levelName}.oel'));
        var fastXml = new haxe.xml.Fast(xml.firstElement());
        var segmentWidth = Std.parseInt(fastXml.node.width.innerData);
        var segmentHeight = Std.parseInt(fastXml.node.height.innerData);
        walls = new Grid(segmentWidth, segmentHeight, TILE_SIZE, TILE_SIZE);
        for (r in fastXml.node.walls.nodes.rect) {
            walls.setRect(
                Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
            );
        }
    }

    override public function update() {
        super.update();
    }
}


