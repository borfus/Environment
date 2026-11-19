#Requires AutoHotkey v2.0

SplitPath(A_LineFile, , &MonitorCrosshairDirectory)
SettingsFilePath := MonitorCrosshairDirectory "\MonitorCrosshairSettings.ini"
CrosshairVcpCode := 0xE3
CrosshairOffStyleNumber := 0
AsusMonitorHardwareIdPrefix := "MONITOR\AUS"
OverlayTransparentKeyColor := "010101"
MonitorDefaultToNearest := 2
DisplayDeviceStructSizeInBytes := 840
DisplayDeviceHardwareIdOffsetInBytes := 328
PhysicalMonitorStructSizeInBytes := 264

CustomCrosshairOverlay := BuildCustomCrosshairOverlay()

Hotkey(ReadSetting("Hotkeys", "ToggleMonitorBuiltInCrosshair"), (*) => ToggleMonitorBuiltInCrosshair())
Hotkey(ReadSetting("Hotkeys", "ToggleCustomCrosshairOverlay"), (*) => ToggleCustomCrosshairOverlay())

ReadSetting(SectionName, SettingName) {
    return IniRead(SettingsFilePath, SectionName, SettingName)
}

ToggleMonitorBuiltInCrosshair() {
    PhysicalMonitorHandle := OpenAsusPhysicalMonitorHandle()
    try {
        CurrentStyleNumber := ReadMonitorCrosshairStyleNumber(PhysicalMonitorHandle)
        if CurrentStyleNumber = CrosshairOffStyleNumber {
            WriteMonitorCrosshairStyleNumber(PhysicalMonitorHandle, Integer(ReadSetting("MonitorBuiltInCrosshair", "StyleNumberToEnable")))
        } else {
            IniWrite(CurrentStyleNumber, SettingsFilePath, "MonitorBuiltInCrosshair", "StyleNumberToEnable")
            WriteMonitorCrosshairStyleNumber(PhysicalMonitorHandle, CrosshairOffStyleNumber)
        }
    } finally {
        DllCall("dxva2\DestroyPhysicalMonitor", "Ptr", PhysicalMonitorHandle)
    }
}

ToggleCustomCrosshairOverlay() {
    if DllCall("IsWindowVisible", "Ptr", CustomCrosshairOverlay.Hwnd) {
        CustomCrosshairOverlay.Hide()
        return
    }
    MonitorGet(FindAsusMonitorNumber(), &MonitorLeft, &MonitorTop, &MonitorRight, &MonitorBottom)
    CustomCrosshairOverlay.Show("NA Hide AutoSize")
    CustomCrosshairOverlay.GetPos(, , &OverlayWidth, &OverlayHeight)
    OverlayLeft := MonitorLeft + (MonitorRight - MonitorLeft - OverlayWidth) // 2
    OverlayTop := MonitorTop + (MonitorBottom - MonitorTop - OverlayHeight) // 2
    CustomCrosshairOverlay.Show("NA x" OverlayLeft " y" OverlayTop)
    WinSetAlwaysOnTop(true, CustomCrosshairOverlay)
}

BuildCustomCrosshairOverlay() {
    ClickThroughExtendedStyle := "+E0x20"
    NeverActivateExtendedStyle := "+E0x08000000"
    Overlay := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale " ClickThroughExtendedStyle " " NeverActivateExtendedStyle, "MonitorCrosshairOverlay")
    Overlay.BackColor := OverlayTransparentKeyColor
    Overlay.MarginX := 0
    Overlay.MarginY := 0
    Overlay.AddPicture("BackgroundTrans", MonitorCrosshairDirectory "\" ReadSetting("CustomCrosshairOverlay", "ImageFileName"))
    WinSetTransColor(OverlayTransparentKeyColor, Overlay)
    return Overlay
}

FindAsusMonitorNumber() {
    loop MonitorGetCount() {
        if InStr(ReadMonitorHardwareId(MonitorGetName(A_Index)), AsusMonitorHardwareIdPrefix)
            return A_Index
    }
    throw Error("No connected monitor has a hardware id containing " AsusMonitorHardwareIdPrefix)
}

ReadMonitorHardwareId(DisplayDeviceName) {
    DisplayDevice := Buffer(DisplayDeviceStructSizeInBytes, 0)
    NumPut("UInt", DisplayDeviceStructSizeInBytes, DisplayDevice)
    if !DllCall("EnumDisplayDevicesW", "Str", DisplayDeviceName, "UInt", 0, "Ptr", DisplayDevice, "UInt", 0)
        throw Error("EnumDisplayDevices failed for " DisplayDeviceName)
    return StrGet(DisplayDevice.Ptr + DisplayDeviceHardwareIdOffsetInBytes, "UTF-16")
}

OpenAsusPhysicalMonitorHandle() {
    MonitorGet(FindAsusMonitorNumber(), &MonitorLeft, &MonitorTop, &MonitorRight, &MonitorBottom)
    MonitorCenterX := (MonitorLeft + MonitorRight) // 2
    MonitorCenterY := (MonitorTop + MonitorBottom) // 2
    PackedCenterPoint := (MonitorCenterY << 32) | (MonitorCenterX & 0xFFFFFFFF)
    DisplayMonitorHandle := DllCall("MonitorFromPoint", "Int64", PackedCenterPoint, "UInt", MonitorDefaultToNearest, "Ptr")
    PhysicalMonitor := Buffer(PhysicalMonitorStructSizeInBytes, 0)
    if !DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "Ptr", DisplayMonitorHandle, "UInt", 1, "Ptr", PhysicalMonitor)
        throw Error("Could not open the ASUS monitor for DDC/CI control")
    return NumGet(PhysicalMonitor, 0, "Ptr")
}

ReadMonitorCrosshairStyleNumber(PhysicalMonitorHandle) {
    CurrentStyleNumber := 0
    MaximumStyleNumber := 0
    if !DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply", "Ptr", PhysicalMonitorHandle, "UChar", CrosshairVcpCode, "Ptr", 0, "UInt*", &CurrentStyleNumber, "UInt*", &MaximumStyleNumber)
        throw Error("The monitor did not answer the crosshair status request")
    return CurrentStyleNumber
}

WriteMonitorCrosshairStyleNumber(PhysicalMonitorHandle, StyleNumber) {
    if !DllCall("dxva2\SetVCPFeature", "Ptr", PhysicalMonitorHandle, "UChar", CrosshairVcpCode, "UInt", StyleNumber)
        throw Error("The monitor rejected crosshair style number " StyleNumber)
}
