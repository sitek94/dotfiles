#!/usr/bin/env sh

# Credits to @mickaelperrin
# https://gist.github.com/mickaelperrin/4b72fa46dec0aa8935b170685dac507d


# TODO: Deleting empty spaces
# Ideas: https://stackoverflow.com/questions/66892255/how-to-write-applescript-to-that-closes-a-desktop-space

MONITORS=$(yabai -m query --displays | jq '.[].index')
MONITORS_COUNT=$(yabai -m query --displays | jq '. | length')

debug() {
  echo "$@" 1>&2;
}

delete_all_spaces() {
  for monitor in ${MONITORS[@]}; do
    local FOCUS_SPACE=$(yabai -m query --spaces --display $monitor | jq '.[0].index')
    debug "Focusing space $FOCUS_SPACE"
    yabai -m space --focus "$FOCUS_SPACE"
    while [ $(yabai -m query --spaces --display $monitor | jq '. | length') -ne 1 ]; do
      local SPACE_ID=$(yabai -m query --spaces --display $monitor | jq '.[-1].index')
      debug "Deleting space $SPACE_ID"
      yabai -m space --destroy "$SPACE_ID"
    done
  done
}

name_first_space() {
  local SPACE_ID=$(get_first_space_of_monitor $1)
  debug "Name space ($SPACE_ID): $2"
  yabai -m space "$SPACE_ID"  --label "$2"
}

name_space() {
  local SPACE_ID=$(yabai -m query --spaces --display $1 | jq '[.[] | select (.label=="")] | .[0] | .index')
  debug "Name space ($SPACE_ID): $2"
  yabai -m space "$SPACE_ID" --label "$2"
}

get_first_space_of_monitor() {
  yabai -m query --spaces --display $1 | jq '.[0].index'
}

create_space_on_monitor() {
  local FIRST_SPACE=$(get_first_space_of_monitor $1)
  debug "Create space after $FIRST_SPACE"
  yabai -m space --create $FIRST_SPACE
  name_space $1 "$2"
}


# The scripting-addition must be loaded manually if you are running yabai on macOS.
# Injection is performed when the config is executed during startup.
# https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)
sudo yabai --load-sa

# Layout: bsp, stack or float
yabai -m config layout bsp

# Where new window should spawn
yabai -m config window_placement second_child

# Padding
yabai -m config top_padding    12
yabai -m config bottom_padding 12
yabai -m config left_padding   12
yabai -m config right_padding  12
yabai -m config window_gap     12


# Recreate all spaces
# -----------------------------------------------------------
delete_all_spaces
# -----------------------------------------------------------

if [ "$MONITORS_COUNT" = "3" ];then
  name_first_space $LAPTOP_MONITOR "terminal 1"
  create_space_on_monitor $LAPTOP_MONITOR "terminal 2"
  create_space_on_monitor $LAPTOP_MONITOR "terminal 3"
  create_space_on_monitor $LAPTOP_MONITOR "music"
  create_space_on_monitor $LAPTOP_MONITOR "messages"

  name_first_space $SIDE_MONITOR "web"
  create_space_on_monitor $SIDE_MONITOR "arc"

  name_first_space $MAIN_MONITOR "code 1"
  create_space_on_monitor $MAIN_MONITOR "code 2"
  create_space_on_monitor $MAIN_MONITOR "dotfiles"


elif [ "$MONITORS_COUNT" = "2" ];then
  name_first_space $LAPTOP_MONITOR "terminal 1"4
  create_space_on_monitor $LAPTOP_MONITOR "terminal 2"
  create_space_on_monitor $LAPTOP_MONITOR "terminal 3"
  create_space_on_monitor $LAPTOP_MONITOR "music"
  create_space_on_monitor $LAPTOP_MONITOR "messages"

  name_first_space $CENTRAL_MONITOR "web"
  create_space_on_monitor $CENTRAL_MONITOR "arc"
  create_space_on_monitor $CENTRAL_MONITOR "code 1"
  create_space_on_monitor $CENTRAL_MONITOR "code 2"
  create_space_on_monitor $CENTRAL_MONITOR "dotfiles"

else 
  name_first_space $LAPTOP_MONITOR "terminal 1"
  create_space_on_monitor $LAPTOP_MONITOR "terminal 2"
  create_space_on_monitor $LAPTOP_MONITOR "terminal 3"
  create_space_on_monitor $LAPTOP_MONITOR "music"
  create_space_on_monitor $LAPTOP_MONITOR "code 1"
  create_space_on_monitor $LAPTOP_MONITOR "code 2"
  create_space_on_monitor $LAPTOP_MONITOR "dotfiles"
  create_space_on_monitor $LAPTOP_MONITOR "web"
  create_space_on_monitor $LAPTOP_MONITOR "arc"
  create_space_on_monitor $LAPTOP_MONITOR "messages"

fi


# Main windows rules
# -----------------------------------------------------------
yabai -m rule --add app="^(Safari|Google Chrome|Brave|Arc)$" display=web
yabai -m rule --add app="^Warp$" display=$LAPTOP_MONITOR
yabai -m rule --add app="^(Discord|Messages|Slack|WhatsApp|)$" space=messages
# make JetBrains products popup windows float
apps='^(IntelliJ IDEA|WebStorm|GoLand|PyCharm)$'
yabai -m rule --add app="JetBrains Toolbox" manage=off
yabai -m rule --add app="${apps}" manage=off
yabai -m rule --add app="${apps}" title="( – )" manage=on display=$MAIN_MONITOR


# Subwindows rules
# -----------------------------------------------------------
# Disable specific apps
yabai -m rule --add app="^(Password|Archive Utility|Calculator|Finder|Kap|Karabiner-Elements|Microsoft Teams|Music|Raycast|System Information|System Preferences|System Settings|Todoist)$" manage=off layer=above

# yabai -m rule --add title="^$" manage=off
# yabai -m rule --add app="^" manage=off
# yabai -m rule --add app="^Finder$" manage=off
# yabai -m rule --add app="^Kap$" manage=off
# yabai -m rule --add app="^Karabiner-Elements$" manage=off
# yabai -m rule --add app="^Microsoft Teams$" manage=off
# yabai -m rule --add app="^Music$" manage=off
# yabai -m rule --add app="^Raycast*" manage=off
# yabai -m rule --add app="^System Information$" manage=off
# yabai -m rule --add app="^System Preferences$" manage=off
# yabai -m rule --add app="^System Settings$" manage=off
# yabai -m rule --add app="^Todoist$" manage=off

# yabai -m rule --add title="Preferences$" manage=off
# yabai -m rule --add title="Rename" manage=off
# yabai -m rule --add title="Settings$" manage=off


# Events
# -----------------------------------------------------------
yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
# refocus when window is closed
yabai -m signal --add event=window_destroyed action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"
yabai -m signal --add event=application_terminated action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"


# Mouse settings
# -----------------------------------------------------------
yabai -m config mouse_follows_focus on      # Move mouse to the window that is focused
# yabai -m config mouse_modifier alt + shift   # Set mouse interaction modifier key (default: fn)
yabai -m config mouse_action1 move          # Set modifier + left-click drag to move window (default: move)
yabai -m config mouse_action2 resize        # Set modifier + right-click drag to resize window (default: resize)
yabai -m config mouse_drop_action swap      # Whenever a window is dragged to a center of another window swap them

