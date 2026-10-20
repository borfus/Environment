#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
; Spectacle-style window management + Win+N virtual desktop switching.
; Spectacle modifiers translated: control -> Ctrl (^), option -> Win (#), command -> Alt (!)

DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")  ; per-monitor DPI aware v2
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

; ---------------------------------------------------------------- window actions

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

; Cycles through left/center/right thirds (top/middle/bottom on portrait screens).
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

; Moves the window to the previous/next monitor (ordered left to right), keeping its relative position and size.
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
    Restore(hwnd, UndoStack, RedoStack)
}

Redo() {
    if !(hwnd := Target())
        return
    Restore(hwnd, RedoStack, UndoStack)
}

; Pops the active window's most recent rect off `from`, saving its current rect onto `to`.
Restore(hwnd, from, to) {
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

; ---------------------------------------------------------------- helpers

Target() {
    hwnd := WinExist("A")
    if !hwnd
        return 0
    cls := WinGetClass(hwnd)
    if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd")
        return 0
    return hwnd
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

; True when the previous action was `action` on this window and it hasn't been moved since.
Continues(hwnd, action) {
    if (Last.hwnd != hwnd || Last.action != action)
        return false
    cur := GetRect(hwnd)
    return cur.x = Last.rect.x && cur.y = Last.rect.y && cur.w = Last.rect.w && cur.h = Last.rect.h
}

NextStep(hwnd, action, n) => Continues(hwnd, action) ? Mod(Last.step + 1, n) : 0

; Visible window bounds, excluding the invisible resize borders Windows 10/11 adds.
GetRect(hwnd) {
    buf := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", buf, "uint", 16) = 0 {
        l := NumGet(buf, 0, "int"), t := NumGet(buf, 4, "int")
        return {x: l, y: t, w: NumGet(buf, 8, "int") - l, h: NumGet(buf, 12, "int") - t}
    }
    WinGetPos(&x, &y, &w, &h, hwnd)
    return {x: x, y: y, w: w, h: h}
}

MoveVisible(hwnd, r) {
    if WinGetMinMax(hwnd) != 0
        WinRestore(hwnd)
    WinGetPos(&x, &y, &w, &h, hwnd)
    v := GetRect(hwnd)
    ol := v.x - x, ot := v.y - y, orr := (x + w) - (v.x + v.w), ob := (y + h) - (v.y + v.h)
    WinMove(r.x - ol, r.y - ot, r.w + ol + orr, r.h + ot + ob, hwnd)
}

; Index of the monitor containing the window's center, or 0 if it's off-screen.
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
    MonitorGetWorkArea(MonitorOf(hwnd) || MonitorGetPrimary(), &l, &t, &r, &b)
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

; ---------------------------------------------------------------- virtual desktops

; VirtualDesktopAccessor (github.com/Ciantic/VirtualDesktopAccessor) wraps the undocumented
; virtual desktop COM API. Windows updates can break it; if it fails to load we fall back to
; registry + Ctrl+Win+Left/Right switching, and skip pinning.
global VDA := A_ScriptDir "\VirtualDesktopAccessor\VirtualDesktopAccessor.dll"
global VDAOk := DllCall("LoadLibrary", "Str", VDA, "Ptr") && DllCall(VDA "\GetDesktopCount", "Int") > 0
global PinnedByUs := Map()
if VDAOk
    SetTimer PinSecondaryWindows, 500
else
    TrayTip "VirtualDesktopAccessor failed to load; secondary monitor pinning is off.", "Spectacle"
OnExit (*) => UnpinAll()

GoToDesktop(n) {
    if !VDAOk
        return GoToDesktopFallback(n)
    while DllCall(VDA "\GetDesktopCount", "Int") < n {
        Send "^#d"   ; creates a new desktop and switches to it
        Sleep 300
    }
    DllCall(VDA "\GoToDesktopNumber", "Int", n - 1, "Int")
}

; Keeps windows on non-primary monitors pinned to all desktops, so desktop switches only
; affect the primary monitor. Windows we pinned get unpinned when they move to the primary.
PinSecondaryWindows() {
    primary := MonitorGetPrimary()
    for hwnd in WinGetList() {
        if !IsManageable(hwnd)
            continue
        try mon := MonitorOf(hwnd)
        catch  ; window closed mid-scan
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

; Visible, titled, non-tool, non-minimized top-level windows on the current desktop.
IsManageable(hwnd) {
    try {
        if (WinGetTitle(hwnd) = "" || WinGetMinMax(hwnd) = -1)
            return false
        if !(WinGetStyle(hwnd) & 0x10000000) || (WinGetExStyle(hwnd) & 0x80)  ; WS_VISIBLE, WS_EX_TOOLWINDOW
            return false
        cls := WinGetClass(hwnd)
        if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd")
            return false
    } catch
        return false
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "uint*", &cloaked, "uint", 4)  ; DWMWA_CLOAKED
    return !cloaked
}

UnpinAll() {
    if !VDAOk
        return
    for hwnd in PinnedByUs
        if WinExist(hwnd)
            DllCall(VDA "\UnPinWindow", "Ptr", hwnd, "Int")
}

; Without the DLL: read the current desktop's position from the registry and step there
; with Ctrl+Win+Left/Right, creating desktops as needed.
GoToDesktopFallback(n) {
    loop 2 {
        d := DesktopState()
        if d.count >= n
            break
        loop n - d.count {
            Send "^#d"   ; creates a new desktop and switches to it
            Sleep 300
        }
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
