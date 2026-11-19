#Requires AutoHotkey v2.0

SplitPath(A_LineFile, , &MonitorCrosshairDirectory)
SettingsFilePath := MonitorCrosshairDirectory "\MonitorCrosshairSettings.ini"
CrosshairVcpCode := 0xE3
CrosshairOffStyleNumber := 0
AsusMonitorHardwareIdPrefix := "MONITOR\AUS"
MonitorDefaultToNearest := 2
DisplayDeviceStructSizeInBytes := 840
DisplayDeviceHardwareIdOffsetInBytes := 328
PhysicalMonitorStructSizeInBytes := 264
GdiplusPixelFormat32bppPremultipliedArgb := 0xE200B
GdiplusLockBitsReadIntoCallerBuffer := 0x5
BlendFunctionUsingPerPixelAlpha := 0x01FF0000
UpdateLayeredWindowUsingAlphaChannel := 2
ShowWindowWithoutActivating := 4

CustomCrosshairImage := LoadImageIntoPremultipliedMemoryDeviceContext(MonitorCrosshairDirectory "\" ReadSetting("CustomCrosshairOverlay", "ImageFileName"))
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
    OverlayLeft := MonitorLeft + (MonitorRight - MonitorLeft - CustomCrosshairImage.Width) // 2
    OverlayTop := MonitorTop + (MonitorBottom - MonitorTop - CustomCrosshairImage.Height) // 2
    DrawCustomCrosshairOverlayAt(OverlayLeft, OverlayTop)
    DllCall("ShowWindow", "Ptr", CustomCrosshairOverlay.Hwnd, "Int", ShowWindowWithoutActivating)
    WinSetAlwaysOnTop(true, CustomCrosshairOverlay)
}

BuildCustomCrosshairOverlay() {
    ClickThroughExtendedStyle := "+E0x20"
    LayeredWindowExtendedStyle := "+E0x80000"
    NeverActivateExtendedStyle := "+E0x08000000"
    return Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale " ClickThroughExtendedStyle " " LayeredWindowExtendedStyle " " NeverActivateExtendedStyle, "MonitorCrosshairOverlay")
}

DrawCustomCrosshairOverlayAt(OverlayLeft, OverlayTop) {
    PackedOverlayPosition := (OverlayTop << 32) | (OverlayLeft & 0xFFFFFFFF)
    PackedOverlaySize := (CustomCrosshairImage.Height << 32) | CustomCrosshairImage.Width
    if !DllCall("UpdateLayeredWindow"
        , "Ptr", CustomCrosshairOverlay.Hwnd
        , "Ptr", 0
        , "Int64*", PackedOverlayPosition
        , "Int64*", PackedOverlaySize
        , "Ptr", CustomCrosshairImage.DeviceContext
        , "Int64*", 0
        , "UInt", 0
        , "UInt*", BlendFunctionUsingPerPixelAlpha
        , "UInt", UpdateLayeredWindowUsingAlphaChannel)
        throw Error("UpdateLayeredWindow failed with Windows error " A_LastError)
}

LoadImageIntoPremultipliedMemoryDeviceContext(ImageFilePath) {
    if !FileExist(ImageFilePath)
        throw Error("Crosshair image not found: " ImageFilePath)
    DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    GdiplusStartupInput := Buffer(24, 0)
    NumPut("UInt", 1, GdiplusStartupInput)
    GdiplusToken := 0
    ThrowIfGdiplusFailed(DllCall("gdiplus\GdiplusStartup", "UPtr*", &GdiplusToken, "Ptr", GdiplusStartupInput, "Ptr", 0, "Int"), "GdiplusStartup")
    try {
        GdiplusBitmap := 0
        ThrowIfGdiplusFailed(DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", ImageFilePath, "Ptr*", &GdiplusBitmap, "Int"), "GdipCreateBitmapFromFile")
        try {
            ImageWidth := 0
            ImageHeight := 0
            ThrowIfGdiplusFailed(DllCall("gdiplus\GdipGetImageWidth", "Ptr", GdiplusBitmap, "UInt*", &ImageWidth, "Int"), "GdipGetImageWidth")
            ThrowIfGdiplusFailed(DllCall("gdiplus\GdipGetImageHeight", "Ptr", GdiplusBitmap, "UInt*", &ImageHeight, "Int"), "GdipGetImageHeight")

            TopDownBitmapInfoHeader := Buffer(40, 0)
            NumPut("UInt", 40, "Int", ImageWidth, "Int", -ImageHeight, "UShort", 1, "UShort", 32, TopDownBitmapInfoHeader)
            DibPixelBits := 0
            DibSectionHandle := DllCall("CreateDIBSection", "Ptr", 0, "Ptr", TopDownBitmapInfoHeader, "UInt", 0, "Ptr*", &DibPixelBits, "Ptr", 0, "UInt", 0, "Ptr")
            if !DibSectionHandle
                throw Error("CreateDIBSection failed for " ImageFilePath)

            LockRectangle := Buffer(16, 0)
            NumPut("Int", 0, "Int", 0, "Int", ImageWidth, "Int", ImageHeight, LockRectangle)
            PremultipliedPixelData := Buffer(32, 0)
            NumPut("UInt", ImageWidth, "UInt", ImageHeight, "Int", ImageWidth * 4, "Int", GdiplusPixelFormat32bppPremultipliedArgb, "Ptr", DibPixelBits, PremultipliedPixelData)
            ThrowIfGdiplusFailed(DllCall("gdiplus\GdipBitmapLockBits", "Ptr", GdiplusBitmap, "Ptr", LockRectangle, "UInt", GdiplusLockBitsReadIntoCallerBuffer, "Int", GdiplusPixelFormat32bppPremultipliedArgb, "Ptr", PremultipliedPixelData, "Int"), "GdipBitmapLockBits")
            ThrowIfGdiplusFailed(DllCall("gdiplus\GdipBitmapUnlockBits", "Ptr", GdiplusBitmap, "Ptr", PremultipliedPixelData, "Int"), "GdipBitmapUnlockBits")

            MemoryDeviceContext := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
            DllCall("SelectObject", "Ptr", MemoryDeviceContext, "Ptr", DibSectionHandle, "Ptr")
            return {DeviceContext: MemoryDeviceContext, Width: ImageWidth, Height: ImageHeight}
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "Ptr", GdiplusBitmap)
        }
    } finally {
        DllCall("gdiplus\GdiplusShutdown", "UPtr", GdiplusToken)
    }
}

ThrowIfGdiplusFailed(GdiplusStatus, GdiplusFunctionName) {
    if GdiplusStatus != 0
        throw Error(GdiplusFunctionName " failed with GDI+ status " GdiplusStatus)
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
