#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

DPI_AWARENESS_PER_MONITOR_V2 := -4
DllCall("SetThreadDpiAwarenessContext", "ptr", DPI_AWARENESS_PER_MONITOR_V2, "ptr")
SetWinDelay -1
A_IconTip := "Spectacle (AutoHotkey)"

#!Left::   Half("left")
#!Right::  Half("right")
#!Up::     Half("top")
#!Down::   Half("bottom")
#!f::      Fullscreen()
#!c::      Center()
^!Left::   Quarter("tl")
^!Right::  Quarter("tr")
^+!Left::  Quarter("bl")
^+!Right:: Quarter("br")
^#!Left::  Display(-1)
^#!Right:: Display(1)
^#Left::   Third(-1)
^#Right::  Third(1)
^#+Left::  Resize(-1)
^#+Right:: Resize(1)
#!z::      Undo()
#+!z::     Redo()

#1:: GoToDesktop(1)
#2:: GoToDesktop(2)
#3:: GoToDesktop(3)
#4:: GoToDesktop(4)
#5:: GoToDesktop(5)

global Last := {hwnd: 0, action: "", step: 0, rect: ""}
global UndoStack := [], RedoStack := []

Half(side) {
    if !(hwnd := Target())
        return
    wa := WorkArea(hwnd)
    step := NextStep(hwnd, side, 3)
    frac := [1/2, 2/3, 1/3][step + 1]
    r := {x: wa.x, y: wa.y, w: wa.w, h: wa.h}
    switch side {
        case "left":   r.w := Round(wa.w * frac)
        case "right":  r.w := Round(wa.w * frac), r.x := wa.x + wa.w - r.w
        case "top":    r.h := Round(wa.h * frac)
        case "bottom": r.h := Round(wa.h * frac), r.y := wa.y + wa.h - r.h
    }
    Apply(hwnd, r, side, step)
}

Quarter(corner) {
    if !(hwnd := Target())
        return
    wa := WorkArea(hwnd)
    lw := wa.w // 2, th := wa.h // 2
    left := InStr(corner, "l"), top := InStr(corner, "t")
    r := {x: left ? wa.x : wa.x + lw, y: top ? wa.y : wa.y + th
        , w: left ? lw : wa.w - lw, h: top ? th : wa.h - th}
    Apply(hwnd, r, corner)
}

Fullscreen() {
    if !(hwnd := Target())
        return
    Apply(hwnd, WorkArea(hwnd), "full")
}

Center() {
    if !(hwnd := Target())
        return
    wa := WorkArea(hwnd), cur := GetRect(hwnd)
    w := Min(cur.w, wa.w), h := Min(cur.h, wa.h)
    Apply(hwnd, {x: wa.x + (wa.w - w) // 2, y: wa.y + (wa.h - h) // 2, w: w, h: h}, "center")
}

Third(dir) {
    if !(hwnd := Target())
        return
    wa := WorkArea(hwnd)
    if Continues(hwnd, "third")
        idx := Mod(Last.step + dir + 3, 3)
    else
        idx := dir > 0 ? 0 : 2
    r := {x: wa.x, y: wa.y, w: wa.w, h: wa.h}
    if wa.w >= wa.h {
        a := Round(wa.w * idx / 3), b := Round(wa.w * (idx + 1) / 3)
        r.x := wa.x + a, r.w := b - a
    } else {
        a := Round(wa.h * idx / 3), b := Round(wa.h * (idx + 1) / 3)
        r.y := wa.y + a, r.h := b - a
    }
    Apply(hwnd, r, "third", idx)
}

Resize(dir) {
    if !(hwnd := Target())
        return
    wa := WorkArea(hwnd), cur := GetRect(hwnd)
    dx := Round(wa.w * 0.05) * dir, dy := Round(wa.h * 0.05) * dir
    l := Max(cur.x - dx, wa.x), t := Max(cur.y - dy, wa.y)
    r := Min(cur.x + cur.w + dx, wa.x + wa.w), b := Min(cur.y + cur.h + dy, wa.y + wa.h)
    if (r - l < 200 || b - t < 150)
        return
    Apply(hwnd, {x: l, y: t, w: r - l, h: b - t}, "resize")
}

Display(dir) {
    if !(hwnd := Target())
        return
    mons := SortedWorkAreas()
    if mons.Length < 2
        return
    from := WorkArea(hwnd), cur := GetRect(hwnd), i := 1
    for idx, m in mons
        if (m.x = from.x && m.y = from.y)
            i := idx
    to := mons[Mod(i - 1 + dir + mons.Length, mons.Length) + 1]
    w := Min(Round(cur.w * to.w / from.w), to.w), h := Min(Round(cur.h * to.h / from.h), to.h)
    x := to.x + Round((cur.x - from.x) * to.w / from.w), y := to.y + Round((cur.y - from.y) * to.h / from.h)
    x := Max(to.x, Min(x, to.x + to.w - w)), y := Max(to.y, Min(y, to.y + to.h - h))
    Apply(hwnd, {x: x, y: y, w: w, h: h}, "display")
}

Undo() {
    if !(hwnd := Target())
        return
    RestoreFromHistory(hwnd, UndoStack, RedoStack)
}

Redo() {
    if !(hwnd := Target())
        return
    RestoreFromHistory(hwnd, RedoStack, UndoStack)
}

RestoreFromHistory(hwnd, from, to) {
    global Last
    i := from.Length
    while i >= 1 {
        if from[i].hwnd = hwnd {
            entry := from.RemoveAt(i)
            to.Push({hwnd: hwnd, rect: GetRect(hwnd)})
            MoveVisible(hwnd, entry.rect)
            Last := {hwnd: 0, action: "", step: 0, rect: ""}
            return
        }
        i--
    }
}

Target() {
    hwnd := WinExist("A")
    if !hwnd
        return 0
    return IsShellWindow(hwnd) ? 0 : hwnd
}

IsShellWindow(hwnd) {
    cls := WinGetClass(hwnd)
    return cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd"
}

Apply(hwnd, r, action := "", step := 0) {
    global Last, RedoStack
    UndoStack.Push({hwnd: hwnd, rect: GetRect(hwnd)})
    if UndoStack.Length > 50
        UndoStack.RemoveAt(1)
    RedoStack := []
    MoveVisible(hwnd, r)
    Last := {hwnd: hwnd, action: action, step: step, rect: GetRect(hwnd)}
}

Continues(hwnd, action) {
    if (Last.hwnd != hwnd || Last.action != action)
        return false
    return SameRect(GetRect(hwnd), Last.rect)
}

SameRect(a, b) => a.x = b.x && a.y = b.y && a.w = b.w && a.h = b.h

NextStep(hwnd, action, n) => Continues(hwnd, action) ? Mod(Last.step + 1, n) : 0

GetRect(hwnd) {
    v := VisibleRect(hwnd)
    if !TiledFrames.Has(hwnd)
        return v
    border := TiledFrames[hwnd]
    return {x: v.x + border, y: v.y + border, w: v.w - 2 * border, h: v.h - 2 * border}
}

VisibleRect(hwnd) {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    buf := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", DWMWA_EXTENDED_FRAME_BOUNDS, "ptr", buf, "uint", 16) = 0 {
        l := NumGet(buf, 0, "int"), t := NumGet(buf, 4, "int")
        return {x: l, y: t, w: NumGet(buf, 8, "int") - l, h: NumGet(buf, 12, "int") - t}
    }
    WinGetPos(&x, &y, &w, &h, hwnd)
    return {x: x, y: y, w: w, h: h}
}

MoveVisible(hwnd, r) {
    if WinGetMinMax(hwnd) != 0
        WinRestore(hwnd)
    tiled := IsTiledRect(r, WorkAreaAt(r.x + r.w // 2, r.y + r.h // 2))
    border := tiled ? BorderThickness(hwnd) : 0
    WinGetPos(&x, &y, &w, &h, hwnd)
    v := VisibleRect(hwnd)
    invisibleLeft := v.x - x + border, invisibleTop := v.y - y + border
    invisibleRight := (x + w) - (v.x + v.w) + border, invisibleBottom := (y + h) - (v.y + v.h) + border
    WinMove(r.x - invisibleLeft, r.y - invisibleTop
        , r.w + invisibleLeft + invisibleRight, r.h + invisibleTop + invisibleBottom, hwnd)
    if tiled
        TileFrame(hwnd, border)
    else
        UntileFrame(hwnd)
}

MonitorOf(hwnd) {
    v := GetRect(hwnd)
    cx := v.x + v.w // 2, cy := v.y + v.h // 2
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (cx >= l && cx < r && cy >= t && cy < b)
            return A_Index
    }
    return 0
}

WorkArea(hwnd) {
    v := GetRect(hwnd)
    return WorkAreaAt(v.x + v.w // 2, v.y + v.h // 2)
}

WorkAreaAt(x, y) {
    monitor := MonitorGetPrimary()
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (x >= l && x < r && y >= t && y < b)
            monitor := A_Index
    }
    MonitorGetWorkArea(monitor, &l, &t, &r, &b)
    return {x: l, y: t, w: r - l, h: b - t}
}

SortedWorkAreas() {
    mons := []
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
        m := {x: l, y: t, w: r - l, h: b - t}
        i := 1
        while i <= mons.Length && (mons[i].x < m.x || (mons[i].x = m.x && mons[i].y < m.y))
            i++
        mons.InsertAt(i, m)
    }
    return mons
}

global TiledFrames := Map()
SetTimer RefreshTiledFrames, 500

IsTiledRect(r, wa) {
    edgesTouched := (Abs(r.x - wa.x) <= 1) + (Abs(r.y - wa.y) <= 1)
        + (Abs(r.x + r.w - wa.x - wa.w) <= 1) + (Abs(r.y + r.h - wa.y - wa.h) <= 1)
    return edgesTouched >= 2
}

BorderThickness(hwnd) {
    static DWMWA_VISIBLE_FRAME_BORDER_THICKNESS := 37
    thickness := 0
    hr := DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", DWMWA_VISIBLE_FRAME_BORDER_THICKNESS, "uint*", &thickness, "uint", 4)
    return hr = 0 ? thickness : 1
}

TileFrame(hwnd, border) {
    if !TiledFrames.Has(hwnd)
        SetFrame(hwnd, true)
    TiledFrames[hwnd] := border
}

UntileFrame(hwnd) {
    if !TiledFrames.Has(hwnd)
        return
    SetFrame(hwnd, false)
    TiledFrames.Delete(hwnd)
}

SetFrame(hwnd, tiled) {
    static DWMWA_WINDOW_CORNER_PREFERENCE := 33, DWMWCP_DEFAULT := 0, DWMWCP_DONOTROUND := 1
    static DWMWA_BORDER_COLOR := 34, DWMWA_COLOR_DEFAULT := 0xFFFFFFFF, DWMWA_COLOR_NONE := 0xFFFFFFFE
    corners := tiled ? DWMWCP_DONOTROUND : DWMWCP_DEFAULT
    border := tiled ? DWMWA_COLOR_NONE : DWMWA_COLOR_DEFAULT
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", DWMWA_WINDOW_CORNER_PREFERENCE, "int*", corners, "uint", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", DWMWA_BORDER_COLOR, "uint*", border, "uint", 4)
}

RefreshTiledFrames() {
    for hwnd in [TiledFrames*] {
        if !WinExist(hwnd) {
            TiledFrames.Delete(hwnd)
            continue
        }
        try {
            if !IsTiledRect(GetRect(hwnd), WorkArea(hwnd))
                UntileFrame(hwnd)
        }
    }
}

RestoreAllFrames() {
    for hwnd in TiledFrames
        if WinExist(hwnd)
            SetFrame(hwnd, false)
}

global VDA := A_ScriptDir "\VirtualDesktopAccessor\VirtualDesktopAccessor.dll"
global VDAOk := DllCall("LoadLibrary", "Str", VDA, "Ptr") && DllCall(VDA "\GetDesktopCount", "Int") > 0
global PinnedByUs := Map()
if VDAOk
    SetTimer PinSecondaryWindows, 500
else
    TrayTip "VirtualDesktopAccessor failed to load; secondary monitor pinning is off.", "Spectacle"
OnExit (*) => (UnpinAll(), RestoreAllFrames(), 0)

GoToDesktop(n) {
    if !VDAOk
        return GoToDesktopFallback(n)
    while DllCall(VDA "\GetDesktopCount", "Int") < n
        CreateDesktop()
    DllCall(VDA "\GoToDesktopNumber", "Int", n - 1, "Int")
}

CreateDesktop() {
    Send "^#d"
    Sleep 300
}

PinSecondaryWindows() {
    primary := MonitorGetPrimary()
    for hwnd in WinGetList() {
        if !IsManageable(hwnd)
            continue
        try mon := MonitorOf(hwnd)
        catch
            continue
        if !mon
            continue
        if (mon != primary && !PinnedByUs.Has(hwnd)) {
            if !DllCall(VDA "\IsPinnedWindow", "Ptr", hwnd, "Int") {
                DllCall(VDA "\PinWindow", "Ptr", hwnd, "Int")
                PinnedByUs[hwnd] := true
            }
        } else if (mon = primary && PinnedByUs.Has(hwnd)) {
            DllCall(VDA "\UnPinWindow", "Ptr", hwnd, "Int")
            PinnedByUs.Delete(hwnd)
        }
    }
    for hwnd in [PinnedByUs*]
        if !WinExist(hwnd)
            PinnedByUs.Delete(hwnd)
}

IsManageable(hwnd) {
    static WS_VISIBLE := 0x10000000, WS_EX_TOOLWINDOW := 0x80, DWMWA_CLOAKED := 14
    try {
        if (WinGetTitle(hwnd) = "" || WinGetMinMax(hwnd) = -1)
            return false
        if !(WinGetStyle(hwnd) & WS_VISIBLE) || (WinGetExStyle(hwnd) & WS_EX_TOOLWINDOW)
            return false
        if IsShellWindow(hwnd)
            return false
    } catch
        return false
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", DWMWA_CLOAKED, "uint*", &cloaked, "uint", 4)
    return !cloaked
}

UnpinAll() {
    if !VDAOk
        return
    for hwnd in PinnedByUs
        if WinExist(hwnd)
            DllCall(VDA "\UnPinWindow", "Ptr", hwnd, "Int")
}

GoToDesktopFallback(n) {
    loop 2 {
        d := DesktopState()
        if d.count >= n
            break
        loop n - d.count
            CreateDesktop()
    }
    d := DesktopState()
    if !d.current
        return
    diff := n - d.current
    loop Abs(diff) {
        Send diff > 0 ? "^#{Right}" : "^#{Left}"
        Sleep 60
    }
}

DesktopState() {
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops"
    ids := RegRead(key, "VirtualDesktopIDs", "")
    cur := RegRead(key, "CurrentVirtualDesktop", "")
    count := StrLen(ids) // 32
    if count <= 1
        return {count: 1, current: 1}
    loop count
        if SubStr(ids, (A_Index - 1) * 32 + 1, 32) = cur
            return {count: count, current: A_Index}
    return {count: count, current: 0}
}
