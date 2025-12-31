package logger

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"

// can be changed to any to filter logging, "Debug" means all messages
globalLogLevel := log.Level.Debug

// use ANSI color coding since it's widely supported (both on web and desktop)
// and makes it easier to see important debug messages.
// customize to your likings!
// basic ANSI color table:
// \x1b[X;CCm
// X - attribute (can also leave empty and delete semicolon to not use any)
// 0 - none
// 1 - bold
// 4 - underline
// 5 - blink on
// 21 - bold off
// 24 - underline off
// 25 - blink off
// CC - color (add 60 to make color light, add 10 to set background color)
// 30 - black
// 31 - red
// 32 - green
// 33 - yellow
// 34 - blue
// 35 - purple
// 36 - cyan
// 37 - white
PREFIX :: "\x1b[34m[ODIN]\x1b[0m "

@(private)
_LevelHeaders := [?]string {
	0 ..< 10 = "\x1b[32m[DEBUG] \x1b[0m",
	10 ..< 20 = "\x1b[36m[INFO] \x1b[0m",
	20 ..< 30 = "\x1b[33m[WARN] \x1b[0m",
	30 ..< 40 = "\x1b[31m[ERROR] \x1b[0m",
	40 ..< 50 = "\x1b[1;31m[FATAL] \x1b[0m",
}

logger :: proc() -> log.Logger {
	return log.Logger{loggerProc, nil, globalLogLevel, nil}
}

// called for assert
assertionFailureProc :: proc(
	prefix, message: string,
	location: runtime.Source_Code_Location,
) -> ! {
	builder := strings.builder_make(context.temp_allocator)

	if prefix != "" {
		fmt.sbprint(&builder, prefix)
	}

	strings.write_string(&builder, "\x1b[4;35m[ASSERT]\x1b[0m")
	_doLocationHeader(&builder, location)
	fmt.sbprint(&builder, message)
	fmt.sbprint(&builder, '\n')

	output := strings.to_string(builder)
	fmt.print(output)

	runtime.trap()
}

loggerProc :: proc(
	data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location := #caller_location,
) {
	if level < globalLogLevel { 	// filter unimportant messages
		return
	}

	builder := strings.builder_make(context.temp_allocator)

	strings.write_string(&builder, PREFIX)
	strings.write_string(&builder, _LevelHeaders[level])
	_doLocationHeader(&builder, location)
	fmt.sbprint(&builder, text)
	fmt.sbprint(&builder, '\n')

	output := strings.to_string(builder)
	fmt.print(output)

	when ODIN_DEBUG {
		if level >= log.Level.Error do runtime.trap()
	}
	if level == .Fatal do runtime.panic(output, loc = location)
}

@(private)
_doLocationHeader :: proc(builder: ^strings.Builder, location := #caller_location) {
	filename := location.file_path

	lastSeparatorIndex := 0
	for rune, index in location.file_path {
		if rune == '/' {
			lastSeparatorIndex = index + 1
		}
	}
	filename = location.file_path[lastSeparatorIndex:]

	fmt.sbprint(builder, filename)
	fmt.sbprint(builder, ":")
	fmt.sbprint(builder, location.line)
	fmt.sbprint(builder, ": ")
}
