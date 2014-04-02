import System.IO
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Actions.WindowGo
import XMonad.Config.Azerty
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.Paste
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import qualified XMonad.Layout.Fullscreen as Fullscreen
import XMonad.Layout.NoBorders
import XMonad.Layout.Spiral
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig
import XMonad.Util.Run(spawnPipe)
import qualified XMonad.StackSet as W
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.UrgencyHook

myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

spawnToWorkspace :: String -> String -> X ()
spawnToWorkspace workspace program = do
                                     spawn program
                                     windows $ W.greedyView workspace

-- Send applications to their dedicated Workspace
myManageHook = composeAll
                [
                  className =? "virtualbox"  --> doShift "6",
                  className =? "irc"         --> doShift "7",
                  className =? "hipchat"     --> doShift "8",
                  className =? "todo"        --> doShift "0",
                  className =? "Xmessage"    --> doFloat,
                  isDialog                   --> doCenterFloat,
                  --className =? "zenity"      --> doFloat,
                  isFullscreen               --> (doF W.focusDown <+> doFullFloat)
                ]

myLayout = (
    Tall 1 (3/100) (1/2) |||
    Mirror (Tall 1 (3/100) (1/2)) |||
    Full |||
    spiral (6/7)) |||
    noBorders (Fullscreen.fullscreenFull Full)

myStartupHook = do
    spawnOn "1" "xterm"
    spawnOn "2" "chromium --proxy-server='socks5://localhost:9999' --host-resolver-rules='MAP * ~NOTFOUND , EXCLUDE localhost' --user-agent='Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11'"
    spawnOn "3" "firefox-aurora"
    spawnOn "4" "xterm"
    spawnOn "5" "xterm -class system"
    spawnOn "6" "skype"
    spawnOn "7" "xterm -class irc -e tmuxinator chat"
    spawnOn "0" "xterm -class todo -e vim ~/Dropbox/todo/todo.txt"
    spawnToWorkspace "9" "surf https://www.google.com/calendar"

myFocusedBorderColor = "#444444"
myNormalBorderColor = "#000000"
monokaiGreen = "#A6E22E"
monokaiBlue = "#66D9EF"

main = do
    xmproc <- spawnPipe "xmobar ~/.xmobarrc"
    xmonad $ withUrgencyHook NoUrgencyHook $ ewmh azertyConfig {
    terminal            = "xterm",
    workspaces          = myWorkspaces,
    normalBorderColor   = myNormalBorderColor,
    focusedBorderColor  = myFocusedBorderColor,
    manageHook          = myManageHook,
    startupHook         = myStartupHook,
    layoutHook          = avoidStruts $ smartBorders $ myLayout,
    logHook             = dynamicLogWithPP $ xmobarPP
      { ppOutput          = hPutStrLn xmproc
      , ppTitle           = xmobarColor monokaiBlue "" . shorten 100
      , ppHiddenNoWindows = xmobarColor "grey" "" . wrap "" ""
      , ppUrgent          = xmobarColor "black" "#FD971F" . wrap ""  ""
      , ppCurrent         = xmobarColor monokaiBlue "" . wrap "" ""
      , ppVisible         = xmobarColor "grey" "" . wrap "(" ")"
      , ppLayout          = xmobarColor "#999" "" . wrap "|" "|"
      , ppSep             = " · "
      },
    modMask = mod4Mask, -- Win key as modkey
    handleEventHook = fullscreenEventHook
} `additionalKeysP`
                        [
                          ("M-q", spawn "killall xmobar; xmonad --recompile && xmonad --restart")
                        , ("M-b", sendMessage ToggleStruts)
                        , ("<Insert>", pasteSelection)
                        , ("M-x", spawn "slock")
                        , ("M-u", focusUrgent)
                        , ("M-p", spawn "dmenu_run_aliases -fn 'Liberation Sans-10' -nb black -nf white -sf black -sb '#A6E22E' -i -f -h 24")
                        , ("<XF86AudioRaiseVolume>", spawn "amixer sset Master 3%+")
                        , ("<XF86AudioLowerVolume>", spawn "amixer sset Master 3%-")
                        , ("C-M-<Left>", prevWS )
                        , ("C-M-<Right>", nextWS )
                        , ("M-g", runOrRaise "gvim" (className =? "Gvim"))
                        , ("M-o", spawn "notify-send foo; sleep 1; scrot -s")
                        , ("<XF86AudioMute>",        spawn "amixer sset Master toggle")
                        , ("C-q", kill)
                        ]
