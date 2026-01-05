package logger

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"

// @ref
// Global filter for logging. Messages below this level are ignored.
// Defaults to .Debug (all messages).
//
// Change this at runtime to toggle verbosity (e.g. logger.globalLogLevel = .Info).
globalLogLevel := log.Level.Debug

// prefix added to every log message to match the cli output
@(private = "file")
_LOG_PREFIX :: "\x1b[34m[ODIN]\x1b[0m "

// ansi color headers for different log levels
@(private = "file")
_LevelHeaders := [?]string {
	0 ..< 10 = "\x1b[32m[DEBUG] \x1b[0m",
	10 ..< 20 = "\x1b[36m[INFO] \x1b[0m",
	20 ..< 30 = "\x1b[33m[WARN] \x1b[0m",
	30 ..< 40 = "\x1b[31m[ERROR] \x1b[0m",
	40 ..< 50 = "\x1b[1;31m[FATAL] \x1b[0m",
}

// @ref
// Creates a new *Logger* instance configured with custom ANSI coloring.
// This is assigned to *context.logger* at the start of the application.
createInstance :: proc() -> log.Logger {
	return log.Logger{_consoleLoggerProc, nil, globalLogLevel, nil}
}

// @ref
// Custom assertion failure handler.
// Prints a formatted, colored error message before trapping the runtime.
// This is assigned to *context.assertion_failure_proc*.
assertionFailureProc :: proc(
	prefix, message: string,
	location: runtime.Source_Code_Location,
) -> ! {
	builder := strings.builder_make(context.temp_allocator)

	if prefix != "" {
		fmt.sbprint(&builder, prefix)
	}

	strings.write_string(&builder, "\x1b[4;35m[ASSERT]\x1b[0m")
	_writeLocationHeader(&builder, location)
	fmt.sbprint(&builder, message)
	fmt.sbprint(&builder, '\n')

	output := strings.to_string(builder)
	fmt.print(output)

	runtime.trap()
}

@(private = "file")
_consoleLoggerProc :: proc(
	data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location := #caller_location,
) {
	// early exit for unimportant messages
	if level < globalLogLevel {
		return
	}

	builder := strings.builder_make(context.temp_allocator)

	strings.write_string(&builder, _LOG_PREFIX)
	strings.write_string(&builder, _LevelHeaders[level])
	_writeLocationHeader(&builder, location)
	fmt.sbprint(&builder, text)
	fmt.sbprint(&builder, '\n')

	output := strings.to_string(builder)
	fmt.print(output)

	// break into debugger on errors if in debug mode
	when ODIN_DEBUG {
		if level >= log.Level.Error do runtime.trap()
	}

	if level == .Fatal do runtime.panic(output, loc = location)
}

@(private = "file")
_writeLocationHeader :: proc(builder: ^strings.Builder, location := #caller_location) {
	filename := location.file_path

	if lastSeparatorIndex := strings.last_index_byte(location.file_path, '/');
	   lastSeparatorIndex >= 0 {
		filename = location.file_path[lastSeparatorIndex + 1:]
	}

	fmt.sbprint(builder, filename)
	fmt.sbprint(builder, ":")
	fmt.sbprint(builder, location.line)
	fmt.sbprint(builder, ": ")
}
