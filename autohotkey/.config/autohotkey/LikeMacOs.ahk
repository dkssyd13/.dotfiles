; AutoHotkey 스크립트 상단에 추가
#NoEnv
#SingleInstance Force
SetTitleMatchMode 2
SendMode Input

; Ctrl + Left Arrow를 Home으로 매핑 (줄의 시작으로 이동)
^Left::Send {Home}

; Ctrl + Right Arrow를 End로 매핑 (줄의 끝으로 이동)
^Right::Send {End}

; Ctrl + Shift + Left  → Shift + Home
^+Left::Send +{Home}

; Ctrl + Shift + Right  → Shift + End
^+Right::Send +{End}

; Win + Backspace로 단어 삭제
#Backspace::
Send ^{Left}
Send +^{Right}
Send {Delete}
return

; Ctrl + Backspace로 현재 줄 삭제 (Home → Shift + End → Delete)
^Backspace::
Send +{Home}
Send {Delete}
return

; Win + Left/Right Arrow를 Ctrl + Left/Right Arrow로 매핑
#Left::
    Send ^{Left}     ; Win + Left → Ctrl + Left
return
#Right::
    Send ^{Right}   ; Win + Right → Ctrl + Right
return

; Win + Shift + Left  → Ctrl + Shift + Left
#+Left::
    Send ^+{Left}
return

; Win + Shift + Right → Ctrl + Shift + Right
#+Right::
    Send ^+{Right}
return