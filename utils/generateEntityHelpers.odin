package utils

import "core:fmt"
import "core:os"
import "core:path/filepath"

SearchContext :: struct {
	files:       ^[dynamic]string,
	isDirectory: bool,
}

main :: proc() {
	generateDataFile(
		"source/game/entities",
		"source/systems/entities/type/generated_entity.odin",
		"EntityName",
		"entity_type",
	)
}

getData :: proc(info: os.File_Info, inErr: os.Error, userData: rawptr) -> (os.Error, bool) {
	if inErr != os.ERROR_NONE {
		fmt.eprintln("Error accessing ", info.fullpath)
		return inErr, false
	}

	ctx := cast(^SearchContext)userData

	if info.is_dir == ctx.isDirectory {
		name := filepath.stem(info.fullpath)
		append(ctx.files, name)
	}

	return os.ERROR_NONE, false
}

generateDataFile :: proc(src, dst, type: string, pack: string = "game_types") -> [dynamic]string {
	foundFiles := make([dynamic]string)

	ctx := SearchContext {
		files       = &foundFiles,
		isDirectory = false,
	}

	filepath.walk(src, getData, &ctx)

	if len(foundFiles) == 0 {
		fmt.println("No files found in: ", src)
		return {}
	}

	f, err := os.open(dst, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
	if err != nil {
		fmt.eprintln("Error on asset generation output: ", err)
	}
	defer os.close(f)

	fmt.fprintln(f, "//NOTE: Machine generated in generateAssets.odin")
	fmt.fprintln(f, "")
	fmt.fprintln(f, "package", pack)
	fmt.fprintln(f, "")
	fmt.fprintln(f, type, ":: enum {")
	fmt.fprintln(f, "\tnil,")
	for name in foundFiles {
		fmt.fprintln(f, "  ", name, ",", sep = "")
	}
	fmt.fprintln(f, "}")

	return foundFiles
}
