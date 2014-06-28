import           System.IO
import           XMonad
import           XMonad.Actions.CycleWS
import           XMonad.Actions.SpawnOn
import           XMonad.Actions.UpdatePointer
import           XMonad.Actions.WindowGo
import           XMonad.Config.Azerty
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops
import           XMonad.Hooks.ManageDocks
import           XMonad.Hooks.ManageHelpers
import           XMonad.Hooks.UrgencyHook
import           XMonad.Layout.NoBorders
import           XMonad.Layout.Spiral
import           XMonad.Layout.Tabbed
import           XMonad.Util.EZConfig
import           XMonad.Util.Paste
import           XMonad.Util.Run              (spawnPipe)
import           XMonad.Util.Scratchpad
--import XMonad.Util.NamedScratchpad
import qualified XMonad.Layout.Fullscreen     as Fullscreen
import qualified XMonad.StackSet              as W

myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

-- Send applications to their dedicated Workspace
myManageHook = (composeAll
                [
                  manageSpawn,
                  className =? "virtualbox"  --> doShift "6",
                  className =? "hipchat"     --> doShift "6",
                  className =? "Xmessage"    --> doFloat,
                  isDialog                   --> doCenterFloat,
                  --className =? "zenity"      --> doFloat,
                  isFullscreen               --> (doF W.focusDown <+> doFullFloat)
                ]) <+> manageScratchPad

manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect l t w h)
  where
    h = 0.5     -- terminal height, 10%
    w = 1       -- terminal width, 100%
    t = 0       -- distance from top edge, 90%
    l = 1 - w   -- distance from left edge, 0%

spawnToWorkspace :: String -> String -> X ()
spawnToWorkspace workspace program = do
                                      spawn program
                                      windows $ W.greedyView workspace

--pads = [ NS "term" "urxvt -name scratchpad -e sh -l -c 'tmux has -t quake && tmux attach -t quake || tmux new -s quake'" (resource =? "scratchpad" <&&> className =? "URxvt") (customFloating $ W.RationalRect 0.2 0.6 0.6 0.4) ]

myLayout = (
    noBorders (Tall 1 (3/100) (1/2)) |||
    noBorders (Mirror (Tall 1 (3/100) (1/2))) |||
    noBorders (Full) |||
    noBorders (spiral (6/7))) |||
    noBorders (Fullscreen.fullscreenFull Full)

myStartupHook = do
    spawnOn "1" "urxvt"
    spawnOn "2" "chromium --proxy-server='socks5://localhost:9999' --proxy-bypass-list=localhost;127.0.0.1 --host-resolver-rules='MAP * ~NOTFOUND , EXCLUDE localhost' --user-agent='Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11'"
    spawnOn "3" "firefox-aurora"
    spawnToWorkspace "4" "urxvt -e pry"
    spawnToWorkspace "5" "urxvt -e tmux"
    spawnOn "7" "urxvt -e tmux-irc"
    spawnOn "8" "nemo"
    spawnOn "9" "surf https://www.google.com/calendar"
    spawnOn "0" "urxvt -e vim ~/Dropbox/todo/todo.txt"

myFocusedBorderColor = "#444444"
myNormalBorderColor = "#111111"
monokaiGreen = "#A6E22E"
monokaiBlue = "#66D9EF"

main = do
    xmproc <- spawnPipe "xmobar ~/.xmobarrc"
    xmonad $ withUrgencyHook NoUrgencyHook $ ewmh azertyConfig {
    terminal            = "urxvt",
    workspaces          = myWorkspaces,
    normalBorderColor   = myNormalBorderColor,
    focusedBorderColor  = myFocusedBorderColor,
    manageHook          = myManageHook,
    startupHook         = myStartupHook,
    layoutHook          = avoidStruts $ smartBorders $ myLayout,
    logHook             = dynamicLogWithPP $ xmobarPP
      { ppOutput          = hPutStrLn xmproc
      , ppTitle           = xmobarColor monokaiBlue "" . shorten 100
      , ppHiddenNoWindows = xmobarColor "grey" "" . wrap "" "" . noScratchPad
      , ppUrgent          = xmobarColor "black" "#FD971F" . wrap " "  " "
      , ppHidden          = xmobarColor "grey" "black" . noScratchPad
      , ppCurrent         = xmobarColor "black" monokaiBlue . wrap " " " "
      , ppVisible         = xmobarColor monokaiBlue ""
      , ppLayout          = xmobarColor "#999" "" . wrap "|" "|"
      , ppSep             = " · "
      },
    modMask = mod4Mask, -- Win key as modkey
    handleEventHook = fullscreenEventHook
} `additionalKeysP`
                        [
                          ("M-q", spawn "killall xmobar; xmonad --recompile && xmonad --restart")
                        --, ("M-z", namedScratchpadAction pads "term")
                        , ("M-z", scratchPad)
                        , ("M-b", sendMessage ToggleStruts)
                        , ("<Insert>", pasteSelection)
                        , ("M-x", spawn "slock")
                        , ("M-u", focusUrgent)
                        , ("M-p", spawn "dmenu_run_aliases -fn 'Liberation Mono-9:bold' -nb black -nf white -sf black -sb '#A6E22E' -b -i -f -h 21")
                        , ("<XF86AudioRaiseVolume>", spawn "amixer sset Master 3%+")
                        , ("<XF86AudioLowerVolume>", spawn "amixer sset Master 3%-")
                        , ("C-M-<Left>", prevWS )
                        , ("C-M-<Right>", nextWS )
                        , ("M-g", spawn "gmrun")
                        , ("M-o", spawn "notify-send foo; sleep 1; scrot -s")
                        , ("<XF86AudioMute>",        spawn "amixer sset Master toggle")
                        , ("C-q", kill)
                        ]
                        where
                          scratchPad = scratchpadSpawnActionTerminal "urxvt -depth 32 -bg rgba:0000/0000/0000/dddd"
                          noScratchPad ws = if ws == "NSP" then "" else ws
