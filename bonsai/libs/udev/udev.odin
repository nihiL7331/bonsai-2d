#+ build linux

package desktop_linux

import "core:c"

Context :: distinct rawptr
Device :: distinct rawptr
Monitor :: distinct rawptr

foreign import udevLib "system:udev"

@(default_calling_convention = "c")
foreign udevLib {
	@(link_name = "udev_new")
	new :: proc() -> Context ---
	@(link_name = "udev_unref")
	unreference :: proc(ctx: Context) ---

	@(link_name = "udev_device_get_devnode")
	getDeviceNode :: proc(device: Device) -> cstring ---
	@(link_name = "udev_device_get_action")
	getDeviceAction :: proc(device: Device) -> cstring ---
	@(link_name = "udev_device_unref")
	unreferenceDevice :: proc(device: Device) ---

	@(link_name = "udev_monitor_new_from_netlink")
	createMonitor :: proc(ctx: Context, name: cstring) -> Monitor ---
	@(link_name = "udev_monitor_filter_add_match_subsystem_devtype")
	addMonitorFilterMatch :: proc(monitor: Monitor, subsystem: cstring, devtype: cstring) -> c.int ---
	@(link_name = "udev_monitor_enable_receiving")
	enableMonitorReceiving :: proc(monitor: Monitor) -> c.int ---
	@(link_name = "udev_monitor_get_fd")
	getMonitorFileDescriptor :: proc(monitor: Monitor) -> c.int ---
	@(link_name = "udev_monitor_receive_device")
	receiveMonitorDevice :: proc(monitor: Monitor) -> Device ---
	@(link_name = "udev_monitor_unref")
	unreferenceMonitor :: proc(monitor: Monitor) ---
}
