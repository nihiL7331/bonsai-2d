package ldtk_type

import "core:encoding/json"

import "../../../types/gmath"

COLLISIONS_LAYER_IDENTIFIER :: "Collisions"
INTGRID_WALL_VALUE :: 1

WorldLayout :: enum {
	null,
	Free, // use worldX and worldY
	GridVania, // use worldX and worldY (but it snaps to grid)
	LinearHorizontal, // use index to position horizontally
	LinearVertical, // use index to position vertically
}

BackgroundPosition :: struct {
	cropRect:  [4]f32 `json:"cropRect"`, // cropX, cropY, cropWidth, cropHeight
	scale:     [2]f32 `json:"scale"`, // scaleX, scaleY - scale of cropped background image
	topLeftPx: [2]int `json:"topLeftPx"`, // x, y - top left pixel coordinate of cropped background iamge
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

Flip :: enum {
	flipX, // flip tile horizontally
	flipY, // flip tile vertically
}

ExtraIntGridInfo :: struct {
	color:      string `json:"color"`, // color in hex
	groupUid:   int `json:"groupUid"`, // parent group identifier (0 if none)
	identifier: Maybe(string) `json:"identifier"`, // user defined unique identifier
	tile:       Maybe(TilesetRectangle) `json:"tile"`,
	value:      int `json:"value"`, // intgrid value itself
}

IntGridInfo :: struct {
	color:      Maybe(string) `json:"color"`, // user defined color
	identifier: Maybe(string) `json:"identifier"`, // user defined string identifier
	uid:        int `json:"uid"`, // group unique id
}

// how the entity tile is rendered inside the entity bounds
TileRenderMode :: enum {
	Cover,
	FitInside,
	Repeat,
	Stretch,
	FullSizeCropped,
	FullSizeUncropped,
	NineSlice,
}

// one instance of custom tile metadata
TilesetDefinitionCustomData :: struct {
	data:   string `json:"data"`,
	tileId: int `json:"tileId"`,
}

EmbedAtlas :: enum {
	null,
	LdtkIcons, // uses internal LDtk atlas image
}

EnumTag :: struct {
	enumValueId: string `json:"enumValueId"`,
	tileIds:     [dynamic]int `json:"tileIds"`,
}

TilesetRectangle :: struct {
	height:     int `json:"h"`, // height in pixels
	tilesetUid: int `json:"tilesetUid"`, // uid of the tileset
	width:      int `json:"w"`, // width in pixels
	x:          int `json:"x"`, // x pixels coordinate of the top-left corner in the tileset image
	y:          int `json:"y"`, // y pixels coordinate of the top-left corner in the tileset image
}

EnumValueDefinition :: struct {
	color:    int `json:"color"`, // optional color
	id:       string `json:"id"`, // enum id value
	tileRect: Maybe(TilesetRectangle) `json:"tileRect"`, // optional tileset rectangle to represent this value
}

Toc :: struct {
	identifier:    string `json:"identifier"`,
	instancesData: [dynamic]TocInstanceData `json:"instancesData"`,
	instances:     [dynamic]EntityInstanceReference `json:"instances"`, // will be removed and replaced on 1.7.0+ with instancesData
}

TocInstanceData :: struct {
	fields:   json.Object `json:"fields"`, // object containing the values of all entity fields with the exportToToc option enabled. depends on actual field value types
	pxHeight: int `json:"heiPx"`,
	iids:     EntityInstanceReference `json:"iids"`, // iid information of this instance
	pxWidth:  int `json:"widPx"`,
	worldX:   int `json:"worldX"`,
	worldY:   int `json:"worldY"`,
}

// this object describes the "location" of an EntityInstance in the project worlds.
EntityInstanceReference :: struct {
	entityIid: string `json:"entityIid"`, // iid of the refered EntityInstance
	layerIid:  string `json:"layerIid"`, // iid of the LayerInstance containing the refered EntityInstance
	levelIid:  string `json:"levelIid"`, // iid of the Level containing the refered EntityInstance
	worldIid:  string `json:"worldIid"`, // iid of the World containing the refered EntityInstance
}

// root of the project
Root :: struct {
	backgroundColor: string `json:"bgColor"`, // project background color
	definitions:     Definitions `json:"defs"`, // a structure containing all the defintions of this project
	externalLevels:  bool `json:"externalLevels"`, // if true one file will be saved for the project and one file in a sub-folder for each level
	iid:             string `json:"iid"`, // unique project identifier
	jsonVersion:     string `json:"jsonVersion"`, // file format version
	levels:          [dynamic]Level `json:"levels"`, // all levels. order of this array is relevant for LinearHorizontal and LinearVertical
	toc:             [dynamic]Toc `json:"toc"`, // array of all instances of entities that have their exportToToc flag enabled
	worldGridHeight: Maybe(int) `json:"worldGridHeight"`, // height of the grid in pixels. [will move to worlds array after "multi-worlds" update] (only GridVania)
	worldGridWidth:  Maybe(int) `json:"worldGridWidth"`, // width of the grid in pixels. [will move to worlds array after "multi-worlds" update] (only GridVania)
	worldLayout:     Maybe(WorldLayout) `json:"worldLayout"`, // describes how levels are organized. [will move to worlds array after "multi-worlds" update]
	worlds:          [dynamic]World `json:"worlds"`, // empty unless multi-worlds enabled TODO: support multi-worlds
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
	backgroundPosition:     Maybe(BackgroundPosition) `json:"__bgPos"`, // position informations of the background image if there's one
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
	layerDefinitionUid:   int `json:"layerDefUid"`, // reference to the layer definition uid
	levelId:              int `json:"levelId"`, // referende to the uid of the level containing this layer instance
	overrideTilesetUid:   Maybe(int) `json:"overrideTilesetUid"`, // can use another tileset by overriding the tileset uid here
	pxOffsetX:            int `json:"pxOffsetX"`, // x offset in pixels to render this layer (prefer using total offset x)
	pxOffsetY:            int `json:"pxOffsetY"`, // y offset in pixels to render this layer (prefer using total offset y)
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
	pivot:          [2]f32 `json:"__pivot"`, // pivot coordinates of the entity (0-1 values)
	smartColor:     string `json:"__smartColor"`, // the entity "smart" color guessed from either entity definiton or one of its field instances
	tags:           [dynamic]string `json:"__tags"`, // array of tags defined in this entity definition
	tile:           Maybe(TilesetRectangle) `json:"__tile"`, // optional TilesetRectangle used to display this entity
	rawWorldX:      Maybe(int) `json:"__worldX"`, // x world coordinate in pixels (only GridVania, Free)
	rawWorldY:      Maybe(int) `json:"__worldY"`, // y world coordinate in pixels (only GridVania, Free)
	definitionUid:  int `json:"defUid"`, // reference of the entity definition uid
	fieldInstances: [dynamic]FieldInstance `json:"fieldInstances"`, // an array of all custom field and their values
	height:         int `json:"height"`, // entity height in pixels
	iid:            string `json:"iid"`, // unique instance identifier
	pxPosition:     [2]int `json:"px"`, // pixel coordinates in current level coordinate space (dont forget optional layer offsets)
	width:          int `json:"width"`, // entity width in pixels
	//ADDITIONAL (not from LDtk)
	worldPosition:  gmath.Vec2Int, // world position using its levels position and its y position in level with y flip
}

FieldInstance :: struct {
	identifier:    string `json:"__identifier"`, // field definition identifier
	tile:          Maybe(TilesetRectangle) `json:"__tile"`, // optional TilesetRectangle used to display this field
	type:          json.Value `json:"__type"`, // type of the field, such as int, f32, string, enum, bool, etc.
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
	entities:      [dynamic]EntityDefinition `json:"entities"`, // all entities definitions, including their custom fields
	enums:         [dynamic]EnumDefinition `json:"enums"`, // all internal enums
	externalEnums: [dynamic]EnumDefinition `json:"externalEnums"`, // the same as enums, but they have a relativePath to point to an external source file
	layers:        [dynamic]LayerDefinition `json:"layers"`, // all layer definitions
	levelFields:   [dynamic]string `json:"levelFields"`, // all custom fields available to all levels
	tilesets:      [dynamic]TilesetDefinition `json:"tilesets"`, // all tilesets
}

LayerDefinition :: struct {
	type:                         string `json:"__type"`, // type of the layer (IntGrid, Entities, Tiles, AutoLayer)
	autoSourceLayerDefinitionUid: Maybe(int) `json:"autoSourceLayerDefUid"`, // (only AutoLayer)
	displayOpacity:               f32 `json:"displayOpacity"`, // opacity of the layer (0 - 1)
	gridSize:                     int `json:"gridSize"`, // width and height of the grid in pixels
	identifier:                   string `json:"identifier"`, // user defined unique identifier
	intGridValues:                [dynamic]ExtraIntGridInfo `json:"intGridValues"`, // an array that defines extra otpional info for each IntGrid value
	intGridValuesGroups:          [dynamic]IntGridInfo `json:"intGridValuesGroups"`, // group informations for IntGrid values
	parallaxFactorX:              f32 `json:"parallaxFactorX"`, // parallax horizontal factor (from -1 to 1, defaults to 0), affects the x scrolling speed of this layer
	parallaxFactorY:              f32 `json:"parallaxFactorY"`, // parallax vertical factor (from -1 to 1, defaults to 0), affects the y scrolling speed of this layer
	parallaxScaling:              bool `json:"parallaxScaling"`, // if true (default), a layer with a parallax factor will also be scaled up/down accordingly
	pxOffsetX:                    int `json:"pxOffsetX"`, // x offset of the layer in pixels
	pxOffsetY:                    int `json:"pxOffsetY"`, // y offset of the layer in pixels
	tilesetDefinitionUid:         Maybe(int) `json:"tilesetDefUid"`, // reference to the default tileset uid being used by this layer definition (only Tile/AutoLayer)
	uid:                          int `json:"uid"`, // unique int identifier
}

EntityDefinition :: struct {
	color:            string `json:"color"`, // base entity color
	height:           int `json:"height"`, // pixel height
	identifier:       string `json:"identifier"`, // user defined unique identifier
	nineSliceBorders: [dynamic]int `json:"nineSliceBorders"`, // an array of 4 dimensions for the up/right/down/left borders (in this order) when using 9-slice mode for TileRenderMode.
	pivotX:           f32 `json:"pivotX"`, // pivot x coordinate (0 - 1)
	pivotY:           f32 `json:"pivotY"`, // pivot y coordinate (0 - 1)
	tileRect:         Maybe(TilesetRectangle) `json:"tileRect"`, // object representing a rectangle from an existing Tileset
	tileRenderMode:   TileRenderMode `json:"tileRenderMode"`, // enum describing how the entity tile is rendered inside the entity bounds.
	tilesetId:        Maybe(int) `json:"tilesetId"`, // tileset id used for optional tile display
	uiTileRect:       Maybe(TilesetRectangle) `json:"uiTileRect"`, // this tile overrides the one defined in tileRect in the UI
	uid:              int `json:"uid"`, // unique int identifier
	width:            int `json:"width"`, // pixel width
}

// the tileset definition is the most important part among project definitions
// it contains some extra informations about each integrated tileset
TilesetDefinition :: struct {
	gridHeight:        int `json:"__cHei"`, // grid-based height
	gridWidth:         int `json:"__cWid"`, // grid-based width
	customData:        [dynamic]TilesetDefinitionCustomData `json:"customData"`, // array of custom tile metadata
	embedAtlas:        Maybe(EmbedAtlas) `json:"embedAtlas"`, // if set, it means that this atlas uses an internal LDtk atlas image instead of a loaded one
	enumTags:          [dynamic]EnumTag `json:"enumTags"`, // tileset tags using enum values specified by tagsSourceEnumId. 1 element per enum value, which contains an array of all tile ids that are tagged with it
	identifier:        string `json:"identifier"`, // user defined unique identifier
	padding:           int `json:"padding"`, // distance in pixels from image borders
	pxHeight:          int `json:"pxHei"`, // image height in pixels
	pxWidth:           int `json:"pxWid"`, // image width in pixels
	relativePath:      Maybe(string) `json:"relPath"`, // path to the source file relative to the current project json file
	spacing:           int `json:"spacing"`, // space in pixels between all tiles
	tags:              [dynamic]string `json:"tags"`, // array of user-defined tags to organize the tilesets
	tagsSourceEnumUid: Maybe(int) `json:"tagsSourceEnumUid"`, // optional enum definition uid used for this tileset meta-data
	tileGridSize:      int `json:"tileGridSize"`,
	uid:               int `json:"uid"`, // int unique identifier
}

EnumDefinition :: struct {
	externalRelativePath: Maybe(string) `json:"externalRelPath"`, // relative path to the external file providing this enum
	iconTilesetUid:       Maybe(int) `json:"iconTilesetUid"`, // tileset uid if provided
	identifier:           string `json:"identifier"`, // user defined unique identifier
	tags:                 [dynamic]string `json:"tags"`, // array of user-defined tags to organize the enums
	uid:                  int `json:"uid"`, // unique int identifier
	values:               [dynamic]EnumValueDefinition `json:"values"`, // all possible enum values with their optional Tile infos
}
