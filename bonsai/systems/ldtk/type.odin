package ldtk

import "core:encoding/json"

import "bonsai:types/gmath"

COLLISIONS_LAYER_IDENTIFIER :: "Collisions"
INTGRID_WALL_VALUE :: 1

FieldInstanceType :: union {
	int,
	f32,
	bool,
	string,
	gmath.Vec2,
	gmath.Vec4,
}

WorldLayout :: enum {
	null,
	Free, // use worldX and worldY
	GridVania, // use worldX and worldY (but it snaps to grid)
	LinearHorizontal, // use index to position horizontally
	LinearVertical, // use index to position vertically
}

Flip :: enum {
	flipX, // flip tile horizontally
	flipY, // flip tile vertically
}

EmbedAtlas :: enum {
	null,
	LdtkIcons, // uses internal LDtk atlas image
}

Neighbour :: struct {
	// direction values:
	// 'n', 's', 'w', 'e', but also:
	// '<' - neighbour depth is lower
	// '>' - neighbour depth is greater
	// 'o' - levels overlap and share the same world depth
	// can be 'nw', 'ne', 'sw', 'se' too
	direction: string `json:"dir"`,
	levelIid:  string `json:"levelIid"`, // neighbour instance identifier
}

// root of the project
Root :: struct {
	backgroundColor: string `json:"bgColor"`, // project background color
	definitions:     Definitions `json:"defs"`, // a structure containing all the defintions of this project
	externalLevels:  bool `json:"externalLevels"`, // if true one file will be saved for the project and one file in a sub-folder for each level
	iid:             string `json:"iid"`, // unique project identifier
	levels:          [dynamic]Level `json:"levels"`, // all levels. order of this array is relevant for LinearHorizontal and LinearVertical
	worldGridHeight: Maybe(int) `json:"worldGridHeight"`, // height of the grid in pixels. [will move to worlds array after "multi-worlds" update] (only GridVania)
	worldGridWidth:  Maybe(int) `json:"worldGridWidth"`, // width of the grid in pixels. [will move to worlds array after "multi-worlds" update] (only GridVania)
	worldLayout:     Maybe(WorldLayout) `json:"worldLayout"`, // describes how levels are organized. [will move to worlds array after "multi-worlds" update]
	worlds:          [dynamic]World `json:"worlds"`, // empty unless multi-worlds enabled TODO: support multi-worlds
	//ADDITIONAL (not from LDtk)
	entities:        map[string]^EntityInstance, // hash map for entities
}

// right now only available as a preview. will be used when will move to multi-worlds
World :: struct {
	identifier:      string `json:"identifier"`, // user defined unique identifier
	iid:             string `json:"iid"`, // unique instance identifier
	levels:          [dynamic]Level `json:"levels"`, // all levels from this world. order of this array is relevant for LinearHorizontal and LinearVertical
	worldGridHeight: int `json:"worldGridHeight"`, // height of the world grid in pixels (only GridVania)
	worldGridWidth:  int `json:"worldGridWidth"`, // width of the world grid in pixels (only GridVania)
	worldLayout:     WorldLayout `json:"worldLayout"`, // enum that describes how levels are organized in this project
}

// this section contains all the level data
Level :: struct {
	backgroundColor:        string `json:"__bgColor"`, // background color of the level
	neighbours:             [dynamic]Neighbour `json:"__neighbours"`, // array listing all other levels touching this one on the world map (only GridVania, Free)
	backgroundRelativePath: Maybe(string) `json:"bgRelPath"`, // optional relative path to the level background image
	externalRelativePath:   Maybe(string) `json:"externalRelPath"`, // not null if "save levels separately" is enabled
	fieldInstances:         [dynamic]FieldInstance `json:"fieldInstances"`, // array containing this level custom field values
	identifier:             string `json:"identifier"`, // user defined unique identifier
	iid:                    string `json:"iid"`, // unique instance identifier
	layerInstances:         Maybe([dynamic]LayerInstance) `json:"layerInstances"`, // array containing all layer instances (if "save levels separately" is enabled, this is null) [sorted in display order]
	pxHeight:               int `json:"pxHei"`, // height of the level in pixels
	pxWidth:                int `json:"pxWid"`, // width of the level in pixels
	uid:                    int `json:"uid"`, // unique int identifier
	worldDepth:             int `json:"worldDepth"`, // index that represents the depth of the level in the world. default is 0, greater means "above", lower means "below".
	rawWorldX:              int `json:"worldX"`, // world x coordinate in pixels. (only GridVania, Free)
	rawWorldY:              int `json:"worldY"`, // world y coordinate in pixels. (only GridVania, Free)
	//ADDITIONAL (not from LDtk)
	worldPosition:          gmath.Vec2Int, // world position in pixels. (equal to {rawWorldX, rawWorldY} if GridVania, Free, else sum of prior levels width/heights)
	colliders:              [dynamic]gmath.Rect, // array of rects, containing collider data generated in load time (minX, minY, maxX, maxY)
}

LayerInstance :: struct {
	gridHeight:           int `json:"__cHei"`, // grid-based height
	gridWidth:            int `json:"__cWid"`, // grid-based width
	gridSize:             int `json:"__gridSize"`, // grid size (size of tile)
	identifier:           string `json:"__identifier"`, // layer definition identifier
	opacity:              f32 `json:"__opacity"`, // layer opacity as float [0-1]
	pxTotalOffsetX:       int `json:"__pxTotalOffsetX"`, // total layer x pixel offset, including both instance and definition offsets
	pxTotalOffsetY:       int `json:"__pxTotalOffsetY"`, // total layer y pixel offset, including both instance and definition offsets
	tilesetDefinitionUid: Maybe(int) `json:"__tilesetDefUid"`, // definition uid of corresponding tileset, if any (only tile/auto layers)
	tilesetRelativePath:  Maybe(string) `json:"__tilesetRelPath"`, // relative path to corresponding tileset, if any (only tile/auto layers)
	type:                 string `json:"__type"`, // layer type (possible: IntGrid, Entities, Tiles, AutoLayer)
	autoLayerTiles:       [dynamic]TileInstance `json:"autoLayerTiles"`, // array containing all tiles generated by autolayer rules. sorted in display order. (only auto layers)
	entityInstances:      [dynamic]EntityInstance `json:"entityInstances"`,
	gridTiles:            [dynamic]TileInstance `json:"gridTiles"`,
	iid:                  string `json:"iid"`, // unique layer instance identifier
	intGrid:              [dynamic]int `json:"intGridCsv"`, // list of all values in the intgrid layer stored in CSV format (left->right, top->bottom) (0 means empty)
	levelId:              int `json:"levelId"`, // referende to the uid of the level containing this layer instance
	overrideTilesetUid:   Maybe(int) `json:"overrideTilesetUid"`, // can use another tileset by overriding the tileset uid here
	visible:              bool `json:"visible"`, // layer instance visibility
}

// this structure represents a single tile from a given tileset
TileInstance :: struct {
	opacity:        f32 `json:"a"`, // alpha/opacity of the tile (0-1, defaults to 1)
	flip:           bit_set[Flip] `json:"f"`, // flip bits a 2-bits integer (bit 0 - x flip, bit 1 - y flip)
	pxPosition:     [2]int `json:"px"`, // pixel coordinates of the tile in the layer (dont forget optional layer offsets)
	sourcePosition: [2]int `json:"src"`, // pixel coordinates of the tile in the tileset
	tileId:         int `json:"t"`, // tile id in the corresponding tileset
}

EntityInstance :: struct {
	grid:           [2]int `json:"__grid"`, // grid-based coordinates
	identifier:     string `json:"__identifier"`, // entity definition identifier
	rawWorldX:      Maybe(int) `json:"__worldX"`, // x world coordinate in pixels (only GridVania, Free)
	rawWorldY:      Maybe(int) `json:"__worldY"`, // y world coordinate in pixels (only GridVania, Free)
	fieldInstances: [dynamic]FieldInstance `json:"fieldInstances"`, // an array of all custom field and their values
	height:         int `json:"height"`, // entity height in pixels
	iid:            string `json:"iid"`, // unique instance identifier
	pxPosition:     [2]int `json:"px"`, // pixel coordinates in current level coordinate space (dont forget optional layer offsets)
	width:          int `json:"width"`, // entity width in pixels
	//ADDITIONAL (not from LDtk)
	worldPosition:  gmath.Vec2Int, // world position using its levels position and its y position in level with y flip
	customFields:   map[string]FieldInstanceType,
}

FieldInstance :: struct {
	identifier:    string `json:"__identifier"`, // field definition identifier
	type:          string `json:"__type"`, // type of the field, such as int, f32, string, enum, bool, etc.
	value:         json.Value `json:"__value"`, // actual value of the field instance. type varies depending on type:
	// for classic types (int, f32, bool, string, path) you just get the actual value with the expected type,
	// for color the value is a hexadecimal string using #rrggbb format (convertible to gmath.Vec4 with color helper)
	// for enum, the value is a string representing the selected enum value (convertible via core:reflect)
	// for point, the value is a GridPoint object
	// for tile, the value is a TilesetRectangle object
	// for EntityRef, the value is an EntityReferenceInfos object
	// if the field is an array, then this value will also be an array
	definitionUid: int `json:"defUid"`, // reference of the field definition uid
}

// mostly can ignore this stuff
// it contains data that are mostly important to the editor
// only 2 definition types that might be useful are tilesets and enums
Definitions :: struct {
	tilesets: [dynamic]TilesetDefinition `json:"tilesets"`, // all tilesets
}

// the tileset definition is the most important part among project definitions
// it contains some extra informations about each integrated tileset
TilesetDefinition :: struct {
	gridHeight:   int `json:"__cHei"`, // grid-based height
	gridWidth:    int `json:"__cWid"`, // grid-based width
	embedAtlas:   Maybe(EmbedAtlas) `json:"embedAtlas"`, // if set, it means that this atlas uses an internal LDtk atlas image instead of a loaded one
	identifier:   string `json:"identifier"`, // user defined unique identifier
	padding:      int `json:"padding"`, // distance in pixels from image borders
	pxHeight:     int `json:"pxHei"`, // image height in pixels
	pxWidth:      int `json:"pxWid"`, // image width in pixels
	relativePath: Maybe(string) `json:"relPath"`, // path to the source file relative to the current project json file
	spacing:      int `json:"spacing"`, // space in pixels between all tiles
	tileGridSize: int `json:"tileGridSize"`,
	uid:          int `json:"uid"`, // int unique identifier
}
