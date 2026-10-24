; Version with threads

#APP_TITLE      = "Clickerlite"
#VERSION_MAJOR  = 0
#VERSION_MINOR  = 1
#VERSION_PATCH  = 0
#VERSION_STRING = "0.1.0"
#VERSION_NAME   = #APP_TITLE + " v" + #VERSION_STRING

#mainWindowID   =    0
#main_window_x  = 1200
#main_window_y  =  100
#main_window_w  =  310
#main_window_h  =  150

flags           = #PB_Window_SystemMenu
exit            = 0

Global StopClicker        = 0
Global isClickerUnable    = 0
Global ClickerThread      = 0 

; Legacy/Unused timer constants and test procedures (kept for reference)
#CLICKER_TIMER  =	200
#My_TIMER       =	150

Enumeration
	#gClickerCaption
	#gClickerX
	#gClickerY
	#gClickerDelay
	#gTextX
	#gTextY
	#gStart
EndEnumeration

Procedure alert(message.s = "", title.s = "")
	MessageRequester(title, message)
EndProcedure

Procedure Clicker(*value)
	; Fetch coordinates and click interval directly from GUI gadgets
	MouseX = Val(GetGadgetText(#gClickerX))
	MouseY = Val(GetGadgetText(#gClickerY))
	
	clickDelay = Val(GetGadgetText(#gClickerDelay))
	
	; Infinite loop performing rapid mouse clicks until the thread is killed or terminated
	Repeat
		SetCursorPos_(MouseX, MouseY)
		mouse_event_(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_LEFTDOWN, MouseX,MouseY,0,0)
		mouse_event_(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_LEFTUP, MouseX,MouseY,0,0)
		Delay(clickDelay)
	ForEver
	
	ProcedureReturn
	
	; NOTE: The code below is unreachable debug code left for testing purposes
	x = 1
	Repeat
		Debug x
		x = x + 1
	ForEver
	
EndProcedure

Procedure KeyMsg (msg.l, WPARAM.l, LPARAM.l)
	If (WPARAM = #WM_KEYDOWN Or WPARAM = #WM_SYSKEYDOWN)
	  
	  ; Parse keypress data from LPARAM via KBDLLHOOKSTRUCT 
	  ; and extract vkCode To determine which key was pressed
	  Protected *st_hook.KBDLLHOOKSTRUCT = LPARAM
		Protected sc = *st_hook\scanCode
		Protected vk = *st_hook\vkCode
		
		Select vk
			Case #VK_F2
				; F2: Capture current screen coordinates of the mouse cursor
				SetGadgetText(#gClickerX, Str(DesktopMouseX()))
				SetGadgetText(#gClickerY, Str(DesktopMouseY()))
			Case #VK_F8
				; F8: Start auto-clicker thread if not already running
				clickDelay = Val(GetGadgetText(#gClickerDelay))
					If isClickerUnable = 0
						isClickerUnable = 1
						ClickerThread = CreateThread(@Clicker(), 23)
					EndIf
			Case #VK_ESCAPE
				; Reserved for exit shortcut
			Case #VK_F4
				; F4: Immediately stop auto-clicker by terminating the active thread
				isClickerUnable = 0
				If ClickerThread > 0
					KillThread(ClickerThread)
				EndIf
		EndSelect
	EndIf
EndProcedure

Procedure MakeInterface()
	x = 0	:	y = 0	:	w = #main_window_w	:	h = 30
	TextGadget(#gClickerCaption, x, y, w, h, "Input parameters for the clicker:", #PB_Text_Center)
	If LoadFont(0, "Palatino Linotype", 13)
		SetGadgetFont(#gClickerCaption, FontID(0))
	EndIf
	
	x = 0	:	y = 30	:	w = 50	:	h = 30
	TextGadget(#PB_Any, x, y, w, h, "x: ", #PB_Text_Right)
	x = x+w	:	y = y	:	w = 100	:	h = 20
	SpinGadget (#gClickerX, x, y, w, h,  0,100000, #PB_Spin_Numeric)
	
	x = x+w	:	y = y	:	w = 50	:	h = 30
	TextGadget(#PB_Any, x, y, w, h, "y: ", #PB_Text_Right)
	x = x+w	:	y = y	:	w = 100	:	h = 20
	SpinGadget (#gClickerY, x, y, w, h,  0,100000, #PB_Spin_Numeric)
	
	SetGadgetText(#gClickerX, "1553")
	SetGadgetText(#gClickerY, "517")
	
	x = 0	:	y = y+30	:	w = 50	:	h = 30
	TextGadget(#PB_Any, x, y, w, h, "Delay: ", #PB_Text_Right)
	x = x+w	:	y = y	:	w = 100	:	h = 20
	SpinGadget (#gClickerDelay, x, y, w, h,  0,100000, #PB_Spin_Numeric)
	SetGadgetText(#gClickerDelay, "5")
	
	x = x+w+50	:	y = y	:	w = 100	:	h = 20
	
	ButtonGadget(#gStart, x, y, w, h, "START")
	
	x = 0	:	y = y+30	:	w = 250	:	h = 50
	TextGadget(#PB_Any, x, y, w, h, "Hover cursor and press [F2] to set coords." + #LF$ + 
	                                "                              [F8] To Start," + #LF$ + 
	                                "                              [F4] To Stop.", #PB_Text_Center)
	
EndProcedure

Procedure test()
	; Test function for legacy timer manipulation
	Debug StopClicker
	StopClicker = StopClicker + 1
	If StopClicker >10
		KillTimer_(WindowID(#mainWindowID), #My_TIMER)
		Debug "Timer is disabled"
	EndIf
	
EndProcedure

; Set a global low-level keyboard hook to intercept key presses across the entire system
; We pass a pointer to our callback function (KeyMsg) where key press events are processed.
Define KeyboardHook = SetWindowsHookEx_(#WH_KEYBOARD_LL, @KeyMsg(), GetModuleHandle_(#Null), 0)

If OpenWindow(#mainWindowID, #main_window_x, #main_window_y, #main_window_w, #main_window_h, #VERSION_NAME, flags)
	StickyWindow(#mainWindowID, 1) ; Keep the clicker window always on top of other windows
	MakeInterface() ; Build GUI elements (buttons, inputs, labels)
	
	Repeat
		Event=WaitWindowEvent()
		
		Select event
			Case #PB_Event_Gadget
				If EventGadget() = #gStart
					
					If isClickerUnable = 0
						isClickerUnable = 1
						ClickerThread = CreateThread(@Clicker(), 42)
					EndIf
					
				EndIf
				
		EndSelect
					
	Until Event=#PB_Event_CloseWindow
	
	; Unhook the global keyboard hook 
	; when the application is closing to release system resources
	UnhookWindowsHookEx_(KeyboardHook)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 125
; Folding = o
; EnableThread
; EnableXP
; Executable = Clickerlite.exe
; CompileSourceDirectory
; EnablePurifier
; IncludeVersionInfo
; VersionField0 = 0.1.0
; VersionField1 = 0.1.0
; VersionField2 = Vladyslav Nazarov
; VersionField3 = Clickerlite
; VersionField4 = 0.1.0
; VersionField5 = 0.1.0
; VersionField6 = Fast and lightweight clicker
; VersionField7 = clickerlite
; VersionField8 = clickerlite.pb
; VersionField9 = © 2026 Vladyslav Nazarov
; VersionField14 = https://github.com/vladnzv
; VersionField15 = VOS_DOS_WINDOWS32
; VersionField16 = VFT_APP
; VersionField17 = 0400 Process Or User Default Language
; EnableUnicode