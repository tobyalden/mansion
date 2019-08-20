package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.*;

typedef IntPair = {
    var x:Int;
    var y:Int;
}

typedef IntPairWithLevel = {
    var x:Int;
    var y:Int;
    var level:Level;
}

class Level extends Entity {
    public static inline var TILE_SIZE = 16;
    public static inline var MIN_LEVEL_WIDTH = 320;
    public static inline var MIN_LEVEL_HEIGHT = 320;
    public static inline var MIN_LEVEL_WIDTH_IN_TILES = 20;
    public static inline var MIN_LEVEL_HEIGHT_IN_TILES = 20;
    public static inline var NUMBER_OF_ROOMS = 3;
    public static inline var NUMBER_OF_HALLWAYS = 3;
    public static inline var NUMBER_OF_SHAFTS = 3;
    public static inline var ITEM_BORDER = 4;

    public var lockWalls(default, null):Grid;
    public var lockTiles(default, null):Tilemap;
    public var walls(default, null):Grid;
    public var pits(default, null):Grid;
    public var openSpots(default, null):Array<IntPairWithLevel>;
    public var levelType(default, null):String;
    public var enemies(default, null):Array<Enemy>;
    private var wallTiles:Tilemap;
    private var groundTiles:Tilemap;
    private var pitTiles:Tilemap;

    public function new(x:Int, y:Int, levelType:String) {
        super(x, y);
        this.levelType = levelType;
        type = "walls";
        if(levelType == "room") {
            loadLevel('${
                Std.int(Math.floor(Random.random * NUMBER_OF_ROOMS))
            }');
        }
        else if(levelType == "hallway") {
            loadLevel('${
                Std.int(Math.floor(Random.random * NUMBER_OF_HALLWAYS))
            }');
        }
        else if(levelType == "shaft") {
            loadLevel('${
                Std.int(Math.floor(Random.random * NUMBER_OF_SHAFTS))
            }');
        }
        else {
            // levelType == "start"
            loadLevel('start');
        }
        if(levelType != "start") {
            if(Random.random < 0.5) {
                flipHorizontally(walls);
                flipHorizontally(pits);
            }
            if(Random.random < 0.5) {
                flipVertically(walls);
                flipVertically(pits);
            }
        }
        openSpots = new Array<IntPairWithLevel>();
        mask = walls;
        enemies = new Array<Enemy>();
    }

    public function getAliveEnemyCount() {
        var count = 0;
        for(enemy in enemies) {
            if(!enemy.isDead) {
                count++;
            }
        }
        return count;
    }

    public function findOpenSpots() {
        if(levelType == "start") {
            return;
        }
        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(
                    !getTile(tileX, tileY)
                    && !getTile(tileX + 1, tileY)
                    && !getTile(tileX - 1, tileY)
                    && !getTile(tileX, tileY + 1)
                    && !getTile(tileX, tileY - 1)
                    && !getTile(tileX + 1, tileY + 1)
                    && !getTile(tileX + 1, tileY - 1)
                    && !getTile(tileX - 1, tileY - 1)
                    && !getTile(tileX - 1, tileY + 1)
                    && !pits.getTile(tileX, tileY)
                    && !pits.getTile(tileX + 1, tileY)
                    && !pits.getTile(tileX - 1, tileY)
                    && !pits.getTile(tileX, tileY + 1)
                    && !pits.getTile(tileX, tileY - 1)
                    && !pits.getTile(tileX + 1, tileY + 1)
                    && !pits.getTile(tileX + 1, tileY - 1)
                    && !pits.getTile(tileX - 1, tileY - 1)
                    && !pits.getTile(tileX - 1, tileY + 1)
                    && (tileX % MIN_LEVEL_WIDTH_IN_TILES) > ITEM_BORDER
                    && (tileY % MIN_LEVEL_HEIGHT_IN_TILES) > ITEM_BORDER
                    && (tileX % MIN_LEVEL_WIDTH_IN_TILES)
                    < MIN_LEVEL_WIDTH_IN_TILES - ITEM_BORDER - 1
                    && (tileY % MIN_LEVEL_HEIGHT_IN_TILES)
                    < MIN_LEVEL_HEIGHT_IN_TILES - ITEM_BORDER - 1
                ) {
                    openSpots.push({
                        x: tileX,
                        y: tileY,
                        level: this
                    });
                }
            }
        }
    }

    private function getTile(
        tileX:Int, tileY:Int, outOfBoundsReturnsTrue:Bool = false
    ) {
        if(
            tileX < 0 || tileY < 0
            || tileX >= walls.columns || tileY >= walls.rows
        ) {
            return outOfBoundsReturnsTrue;
        }
        return walls.getTile(tileX, tileY);
    }

    public function flipHorizontally(wallsToFlip:Grid) {
        for(tileX in 0...Std.int(wallsToFlip.columns / 2)) {
            for(tileY in 0...wallsToFlip.rows) {
                var tempLeft:Null<Bool> = wallsToFlip.getTile(tileX, tileY);
                // For some reason getTile() returns null instead of false!
                if(tempLeft == null) {
                    tempLeft = false;
                }
                var tempRight:Null<Bool> = wallsToFlip.getTile(
                    wallsToFlip.columns - tileX - 1, tileY
                );
                if(tempRight == null) {
                    tempRight = false;
                }
                wallsToFlip.setTile(tileX, tileY, tempRight);
                wallsToFlip.setTile(
                    wallsToFlip.columns - tileX - 1, tileY, tempLeft
                );
            }
        }
    }

    public function flipVertically(wallsToFlip:Grid) {
        for(tileX in 0...wallsToFlip.columns) {
            for(tileY in 0...Std.int(wallsToFlip.rows / 2)) {
                var tempTop:Null<Bool> = wallsToFlip.getTile(tileX, tileY);
                // For some reason getTile() returns null instead of false!
                if(tempTop == null) {
                    tempTop = false;
                }
                var tempBottom:Null<Bool> = wallsToFlip.getTile(
                    tileX, wallsToFlip.rows - tileY - 1
                );
                if(tempBottom == null) {
                    tempBottom = false;
                }
                wallsToFlip.setTile(tileX, tileY, tempBottom);
                wallsToFlip.setTile(
                    tileX, wallsToFlip.rows - tileY - 1, tempTop
                );
            }
        }
    }

    private function loadLevel(levelName:String) {
        // Load geometry
        var xml = Xml.parse(Assets.getText(
            'levels/${levelType}/${levelName}.oel'
        ));
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

        // Load optional geometry
        pits = new Grid(segmentWidth, segmentHeight, TILE_SIZE, TILE_SIZE);
        if(fastXml.hasNode.optionalWalls) {
            for (r in fastXml.node.optionalWalls.nodes.rect) {
                if(Random.random < 0.5) {
                    continue;
                }
                if(Random.random < 0.5) {
                    walls.setRect(
                        Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
                    );
                }
                else {
                    pits.setRect(
                        Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                        Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
                    );
                }
            }
        }

        lockWalls = new Grid(segmentWidth, segmentHeight, 8, 8);
        for(tileX in 0...lockWalls.columns) {
            for(tileY in 0...lockWalls.rows) {
                if(
                    tileX == 0
                    || tileY == 0
                    || tileX == lockWalls.columns - 1
                    || tileY == lockWalls.rows - 1
                ) {
                    lockWalls.setTile(tileX, tileY);
                }
            }
        }
    }

    public function fillLeft(offsetY:Int) {
        for(tileY in 0...MIN_LEVEL_HEIGHT_IN_TILES) {
            walls.setTile(0, tileY + offsetY * MIN_LEVEL_HEIGHT_IN_TILES);
        }
    }

    public function fillRight(offsetY:Int) {
        for(tileY in 0...MIN_LEVEL_HEIGHT_IN_TILES) {
            walls.setTile(
                walls.columns - 1,
                tileY + offsetY * MIN_LEVEL_HEIGHT_IN_TILES
            );
        }
    }

    public function fillTop(offsetX:Int) {
        for(tileX in 0...MIN_LEVEL_WIDTH_IN_TILES) {
            walls.setTile(tileX + offsetX * MIN_LEVEL_WIDTH_IN_TILES, 0);
        }
    }

    public function fillBottom(offsetX:Int) {
        for(tileX in 0...MIN_LEVEL_WIDTH_IN_TILES) {
            walls.setTile(
                tileX + offsetX * MIN_LEVEL_WIDTH_IN_TILES,
                walls.rows - 1
            );
        }
    }

    public function updateGraphic() {
        wallTiles = new Tilemap(
            'graphics/walls2.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        groundTiles = new Tilemap(
            'graphics/grass2.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        pitTiles = new Tilemap(
            'graphics/pits.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        lockTiles = new Tilemap(
            'graphics/lockwalls.png',
            lockWalls.width, lockWalls.height,
            lockWalls.tileWidth, lockWalls.tileHeight
        );

        for(tileX in 0...lockWalls.columns) {
            for(tileY in 0...lockWalls.rows) {
                if(lockWalls.getTile(tileX, tileY)) {
                    lockTiles.setTile(tileX, tileY, 0);
                }
            }
        }

        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(pits.getTile(tileX, tileY)) {
                    if(
                        !pits.getTile(tileX - 1, tileY)
                        && !pits.getTile(tileX, tileY - 1)
                    ) {
                        pitTiles.setTile(tileX, tileY, 5);
                    }
                    else if(
                        !pits.getTile(tileX + 1, tileY)
                        && !pits.getTile(tileX, tileY - 1)
                    ) {
                        pitTiles.setTile(tileX, tileY, 7);
                    }
                    else if(
                        !pits.getTile(tileX - 1, tileY)
                        && !pits.getTile(tileX, tileY + 1)
                    ) {
                        pitTiles.setTile(tileX, tileY, 21);
                    }
                    else if(
                        !pits.getTile(tileX + 1, tileY)
                        && !pits.getTile(tileX, tileY + 1)
                    ) {
                        pitTiles.setTile(tileX, tileY, 23);
                    }
                    else if(!pits.getTile(tileX + 1, tileY)) {
                        pitTiles.setTile(tileX, tileY, 15);
                    }
                    else if(!pits.getTile(tileX - 1, tileY)) {
                        pitTiles.setTile(tileX, tileY, 13);
                    }
                    else if(!pits.getTile(tileX, tileY + 1)) {
                        pitTiles.setTile(tileX, tileY, 22);
                    }
                    else if(!pits.getTile(tileX, tileY - 1)) {
                        pitTiles.setTile(tileX, tileY, 6);
                    }
                    else {
                        pitTiles.setTile(tileX, tileY, 14);
                    }
                }
                else if(getTile(tileX, tileY)) {
                    if(
                        !getTile(tileX - 1, tileY, true)
                        && !getTile(tileX, tileY - 1, true)
                    ) {
                        wallTiles.setTile(tileX, tileY, 5);
                    }
                    else if(
                        !getTile(tileX + 1, tileY, true)
                        && !getTile(tileX, tileY - 1, true)
                    ) {
                        wallTiles.setTile(tileX, tileY, 7);
                    }
                    else if(
                        !getTile(tileX - 1, tileY, true)
                        && !getTile(tileX, tileY + 1, true)
                    ) {
                        wallTiles.setTile(tileX, tileY, 21);
                    }
                    else if(
                        !getTile(tileX + 1, tileY, true)
                        && !getTile(tileX, tileY + 1, true)
                    ) {
                        wallTiles.setTile(tileX, tileY, 23);
                    }
                    else if(!getTile(tileX + 1, tileY, true)) {
                        wallTiles.setTile(tileX, tileY, 15);
                    }
                    else if(!getTile(tileX - 1, tileY, true)) {
                        wallTiles.setTile(tileX, tileY, 13);
                    }
                    else if(!getTile(tileX, tileY + 1, true)) {
                        wallTiles.setTile(tileX, tileY, 22);
                    }
                    else if(!getTile(tileX, tileY - 1, true)) {
                        wallTiles.setTile(tileX, tileY, 6);
                    }
                    else {
                        wallTiles.setTile(tileX, tileY, 14);
                    }
                }
                if(!getTile(tileX, tileY)) {
                    if(
                        getTile(tileX - 1, tileY)
                        && getTile(tileX, tileY - 1)
                    ) {
                        groundTiles.setTile(tileX, tileY, 5);
                    }
                    else if(
                        getTile(tileX + 1, tileY)
                        && getTile(tileX, tileY - 1)
                    ) {
                        groundTiles.setTile(tileX, tileY, 7);
                    }
                    else if(
                        getTile(tileX - 1, tileY)
                        && getTile(tileX, tileY + 1)
                    ) {
                        groundTiles.setTile(tileX, tileY, 21);
                    }
                    else if(
                        getTile(tileX + 1, tileY)
                        && getTile(tileX, tileY + 1)
                    ) {
                        groundTiles.setTile(tileX, tileY, 23);
                    }
                    else if(getTile(tileX + 1, tileY)) {
                        groundTiles.setTile(tileX, tileY, 15);
                    }
                    else if(getTile(tileX - 1, tileY)) {
                        groundTiles.setTile(tileX, tileY, 13);
                    }
                    else if(getTile(tileX, tileY + 1)) {
                        groundTiles.setTile(tileX, tileY, 22);
                    }
                    else if(getTile(tileX, tileY - 1)) {
                        groundTiles.setTile(tileX, tileY, 6);
                    }
                    else {
                        if(Math.random() < 0.15) {
                            groundTiles.setTile(tileX, tileY, 46);
                        }
                        else {
                            groundTiles.setTile(tileX, tileY, 14);
                        }
                    }
                }
            }
        }
        addGraphic(wallTiles);
        addGraphic(groundTiles);
        addGraphic(pitTiles);
    }
}
