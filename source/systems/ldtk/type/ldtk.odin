package ldtk_type

import "core:encoding/json"

import "../../../types/gmath"

WorldLayout :: enum {
	null,
	Free, // use worldX and worldY
	GridVania, // use worldX and worldY (but it snaps to grid)
	LinearHorizontal, // use index to position horizontally
	LinearVertical, // use index to position vertically
}

BackgroundPosition :: struct {
	cropRect:  [4]f32 `json:"cropRect"`,
	scale:     [dynamic]f32 `json:"scale"`,
	topLeftPx: [dynamic]int `json:"topLeftPx"`,
}

Neighbour :: struct {
	direction: string `json:"dir"`,
	levelIid:  string `json:"levelIid"`,
}

Flip :: enum {
	flipX, // flip tile horizontally
	flipY, // flip tile vertically
}

ExtraIntGridInfo :: struct {
	color:      string `json:"color"`,
	groupUid:   int `json:"groupUid"`,
	identifier: Maybe(string) `json:"identifier"`,
	tile:       Maybe(TilesetRectangle) `json:"tile"`,
	value:      int `json:"value"`,
}

IntGridInfo :: struct {
	color:      Maybe(string) `json:"color"`,
	identifier: Maybe(string) `json:"identifier"`,
	uid:        int `json:"uid"`,
}

TileRenderMode :: enum {
	Cover,
	FitInside,
	Repeat,
	Stretch,
	FullSizeCropped,
	FullSizeUncropped,
	NineSlice,
}

TilesetDefinitionCustomData :: struct {
	data:   string `json:"data"`,
	tileId: int `json:"tileId"`,
}

EmbedAtlas :: enum {
	null,
	LdtkIcons,
}

EnumTag :: struct {
	enumValueId: string `json:"enumValueId"`,
	tileIds:     [dynamic]int `json:"tileIds"`,
}

TilesetRectangle :: struct {
	height:     int `json:"h"`,
	tilesetUid: int `json:"tilesetUid"`,
	width:      int `json:"w"`,
	x:          int `json:"x"`,
	y:          int `json:"y"`,
}

EnumValueDefinition :: struct {
	color:    int `json:"color"`,
	id:       string `json:"id"`,
	tileRect: Maybe(TilesetRectangle) `json:"tileRect"`,
}

Toc :: struct {
	identifier:    string `json:"identifier"`,
	instancesData: [dynamic]TocInstanceData `json:"instancesData"`,
	instances:     [dynamic]EntityInstanceReference `json:"instances"`,
}

TocInstanceData :: struct {
	fields:   string `json:"fields"`,
	pxHeight: int `json:"heiPx"`,
	iids:     EntityInstanceReference `json:"iids"`,
	pxWidth:  int `json:"widPx"`,
	worldX:   int `json:"worldX"`,
	worldY:   int `json:"worldY"`,
}

EntityInstanceReference :: struct {
	entityIid: string `json:"entityIid"`,
	layerIid:  string `json:"layerIid"`,
	levelIid:  string `json:"levelIid"`,
	worldIid:  string `json:"worldIid"`,
}

Root :: struct {
	backgroundColor: string `json:"bgColor"`,
	definitions:     Definitions `json:"defs"`,
	externalLevels:  bool `json:"externalLevels"`,
	iid:             string `json:"iid"`,
	jsonVersion:     string `json:"jsonVersion"`,
	levels:          [dynamic]Level `json:"levels"`,
	toc:             [dynamic]Toc `json:"toc"`,
	worldGridHeight: Maybe(int) `json:"worldGridHeight"`,
	worldGridWidth:  Maybe(int) `json:"worldGridWidth"`,
	worldLayout:     Maybe(WorldLayout) `json:"worldLayout"`,
	worlds:          [dynamic]World `json:"worlds"`,
}

World :: struct {
	identifier:      string `json:"identifier"`,
	iid:             string `json:"iid"`,
	levels:          [dynamic]Level `json:"levels"`,
	worldGridHeight: int `json:"worldGridHeight"`,
	worldGridWidth:  int `json:"worldGridWidth"`,
	worldLayout:     WorldLayout `json:"worldLayout"`,
}

Level :: struct {
	backgroundColor:        string `json:"__bgColor"`,
	backgroundPosition:     Maybe(BackgroundPosition) `json:"__bgPos"`,
	neighbours:             [dynamic]Neighbour `json:"__neighbours"`,
	backgroundRelativePath: Maybe(string) `json:"bgRelPath"`,
	externalRelativePath:   Maybe(string) `json:"externalRelPath"`,
	fieldInstances:         [dynamic]FieldInstance `json:"fieldInstances"`,
	identifier:             string `json:"identifier"`,
	iid:                    string `json:"iid"`,
	layerInstances:         Maybe([dynamic]LayerInstance) `json:"layerInstances"`,
	pxHeight:               int `json:"pxHei"`,
	pxWidth:                int `json:"pxWid"`,
	uid:                    int `json:"uid"`,
	worldDepth:             int `json:"worldDepth"`,
	rawWorldX:              int `json:"worldX"`,
	rawWorldY:              int `json:"worldY"`,
	//ADDITIONAL (not from LDtk)
	worldPosition:          gmath.Vec2Int,
}

LayerInstance :: struct {
	gridHeight:           int `json:"__cHei"`,
	gridWidth:            int `json:"__cWid"`,
	gridSize:             int `json:"__gridSize"`,
	identifier:           string `json:"__identifier"`,
	opacity:              f32 `json:"__opacity"`,
	pxTotalOffsetX:       int `json:"__pxTotalOffsetX"`,
	pxTotalOffsetY:       int `json:"__pxTotalOffsetY"`,
	tilesetDefinitionUid: Maybe(int) `json:"__tilesetDefUid"`,
	tilesetRelativePath:  Maybe(string) `json:"__tilesetRelPath"`,
	type:                 string `json:"__type"`,
	autoLayerTiles:       [dynamic]TileInstance `json:"autoLayerTiles"`,
	entityInstances:      [dynamic]EntityInstance `json:"entityInstances"`,
	gridTiles:            [dynamic]TileInstance `json:"gridTiles"`,
	iid:                  string `json:"iid"`,
	intGrid:              [dynamic]int `json:"intGridCsv"`,
	layerDefinitionUid:   int `json:"layerDefUid"`,
	levelId:              int `json:"levelId"`,
	overrideTilesetUid:   Maybe(int) `json:"overrideTilesetUid"`,
	pxOffsetX:            int `json:"pxOffsetX"`,
	pxOffsetY:            int `json:"pxOffsetY"`,
	visible:              bool `json:"visible"`,
}

TileInstance :: struct {
	opacity:        f32 `json:"a"`,
	flip:           bit_set[Flip] `json:"f"`,
	pxPosition:     [dynamic]int `json:"px"`,
	sourcePosition: [dynamic]int `json:"src"`,
	tileId:         int `json:"t"`,
}

EntityInstance :: struct {
	grid:           [dynamic]int `json:"__grid"`,
	identifier:     string `json:"__identifier"`,
	pivot:          [dynamic]f32 `json:"__pivot"`,
	smartColor:     string `json:"__smartColor"`,
	tags:           [dynamic]string `json:"__tags"`,
	tile:           Maybe(TilesetRectangle) `json:"__tile"`,
	rawWorldX:      Maybe(int) `json:"__worldX"`,
	rawWorldY:      Maybe(int) `json:"__worldY"`,
	definitionUid:  int `json:"defUid"`,
	fieldInstances: [dynamic]FieldInstance `json:"fieldInstances"`,
	height:         int `json:"height"`,
	iid:            string `json:"iid"`,
	pxPosition:     [dynamic]int `json:"px"`,
	width:          int `json:"width"`,
	//ADDITIONAL (not from LDtk)
	worldPosition:  gmath.Vec2Int,
}

FieldInstance :: struct {
	identifier:    string `json:"__identifier"`,
	tile:          Maybe(TilesetRectangle) `json:"__tile"`,
	type:          string `json:"__type"`,
	value:         json.Value `json:"__value"`,
	definitionUid: int `json:"defUid"`,
}

Definitions :: struct {
	entities:      [dynamic]EntityDefinition `json:"entities"`,
	enums:         [dynamic]EnumDefinition `json:"enums"`,
	externalEnums: [dynamic]EnumDefinition `json:"externalEnums"`,
	layers:        [dynamic]LayerDefinition `json:"layers"`,
	tilesets:      [dynamic]TilesetDefinition `json:"tilesets"`,
}

LayerDefinition :: struct {
	type:                         string `json:"__type"`,
	autoSourceLayerDefinitionUid: Maybe(int) `json:"autoSourceLayerDefUid"`,
	displayOpacity:               f32 `json:"displayOpacity"`,
	gridSize:                     int `json:"gridSize"`,
	identifier:                   string `json:"identifier"`,
	intGridValues:                [dynamic]ExtraIntGridInfo `json:"intGridValues"`,
	intGridValuesGroups:          [dynamic]IntGridInfo `json:"intGridValuesGroups"`,
	parallaxFactorX:              f32 `json:"parallaxFactorX"`,
	parallaxFactorY:              f32 `json:"parallaxFactorY"`,
	parallaxScaling:              bool `json:"parallaxScaling"`,
	pxOffsetX:                    int `json:"pxOffsetX"`,
	pxOffsetY:                    int `json:"pxOffsetY"`,
	tilesetDefinitionUid:         Maybe(int) `json:"tilesetDefUid"`,
	uid:                          int `json:"uid"`,
}

EntityDefinition :: struct {
	color:            string `json:"color"`,
	height:           int `json:"height"`,
	identifier:       string `json:"identifier"`,
	nineSliceBorders: [dynamic]int `json:"nineSliceBorders"`,
	pivotX:           f32 `json:"pivotX"`,
	pivotY:           f32 `json:"pivotY"`,
	tileRect:         Maybe(TilesetRectangle) `json:"tileRect"`,
	tileRenderMode:   TileRenderMode `json:"tileRenderMode"`,
	tilesetId:        Maybe(int) `json:"tilesetId"`,
	uiTileRect:       Maybe(TilesetRectangle) `json:"uiTileRect"`,
	uid:              int `json:"uid"`,
	width:            int `json:"width"`,
}

TilesetDefinition :: struct {
	gridHeight:        int `json:"__cHei"`,
	gridWidth:         int `json:"__cWid"`,
	customData:        [dynamic]TilesetDefinitionCustomData `json:"customData"`,
	embedAtlas:        Maybe(EmbedAtlas) `json:"embedAtlas"`,
	enumTags:          [dynamic]EnumTag `json:"enumTags"`,
	identifier:        string `json:"identifier"`,
	padding:           int `json:"padding"`,
	pxHeight:          int `json:"pxHei"`,
	pxWidth:           int `json:"pxWid"`,
	relativePath:      Maybe(string) `json:"relPath"`,
	spacing:           int `json:"spacing"`,
	tags:              [dynamic]string `json:"tags"`,
	tagsSourceEnumUid: Maybe(int) `json:"tagsSourceEnumUid"`,
	tileGridSize:      int `json:"tileGridSize"`,
	uid:               int `json:"uid"`,
}

EnumDefinition :: struct {
	externalRelativePath: Maybe(string) `json:"externalRelPath"`,
	iconTilesetUid:       Maybe(int) `json:"iconTilesetUid"`,
	identifier:           string `json:"identifier"`,
	tags:                 [dynamic]string `json:"tags"`,
	uid:                  int `json:"uid"`,
	values:               [dynamic]EnumValueDefinition `json:"values"`,
}
