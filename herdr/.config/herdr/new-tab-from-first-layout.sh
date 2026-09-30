#!/bin/sh

set -eu

herdr_bin=${HERDR_BIN_PATH:-herdr}
workspace_id=${HERDR_ACTIVE_WORKSPACE_ID:-${HERDR_WORKSPACE_ID:-}}
workspace_cwd=${HERDR_ACTIVE_PANE_CWD:-}
socket_path=${HERDR_SOCKET_PATH:-}
focus_new_tab=${HERDR_LAYOUT_FOCUS:-true}

fail() {
  "$herdr_bin" notification show "Main + AI agent tab failed" --body "$1" >/dev/null 2>&1 || true
  exit 1
}

[ -n "$workspace_id" ] || fail "No active Herdr workspace was found."
[ -n "$socket_path" ] && [ -S "$socket_path" ] || fail "The Herdr API socket is unavailable."
command -v jq >/dev/null 2>&1 || fail "jq is required to create the tab layout."
command -v nc >/dev/null 2>&1 || fail "nc is required to create the tab layout."

case "$focus_new_tab" in
  true|false) ;;
  *) fail "HERDR_LAYOUT_FOCUS must be true or false." ;;
esac

if [ -z "$workspace_cwd" ]; then
  panes_json=$("$herdr_bin" pane list --workspace "$workspace_id" 2>/dev/null) || \
    fail "The workspace panes could not be read."
  workspace_cwd=$(printf '%s\n' "$panes_json" | jq -er '
    .result.panes[0]
    | if ((.foreground_cwd // "") | length) > 0 then .foreground_cwd else .cwd end
  ') || fail "The workspace working directory could not be resolved."
fi

[ -d "$workspace_cwd" ] || fail "The workspace working directory does not exist."

# Use one portable template everywhere. Cloning each target workspace's first
# tab would produce a one-pane result in a newly created workspace.
layout_root=$(jq -cn --arg cwd "$workspace_cwd" '
  {
    type: "split",
    direction: "right",
    ratio: 0.75,
    first: {type: "pane", label: "Main", cwd: $cwd},
    second: {type: "pane", label: "AI agent", cwd: $cwd}
  }
')

apply_request=$(jq -cn \
  --arg id "main-agent-layout-apply" \
  --arg workspace_id "$workspace_id" \
  --argjson focus "$focus_new_tab" \
  --argjson root "$layout_root" \
  '{
    id: $id,
    method: "layout.apply",
    params: {workspace_id: $workspace_id, focus: $focus, root: $root}
  }')
apply_response=$(printf '%s\n' "$apply_request" | nc -U -w 2 "$socket_path") || \
  fail "The Main + AI agent tab could not be created."

printf '%s\n' "$apply_response" | jq -e '
  .error == null and .result.type == "layout_apply"
' >/dev/null || fail "Herdr rejected the Main + AI agent layout."

# layout.apply's focus only moves the server's focus; attached clients keep
# their own view unless an explicit tab.focus follows.
if [ "$focus_new_tab" = true ]; then
  new_tab_id=$(printf '%s\n' "$apply_response" | jq -er '.result.layout.tab_id') || \
    fail "The new tab id could not be read."
  "$herdr_bin" tab focus "$new_tab_id" >/dev/null 2>&1 || \
    fail "The new Main + AI agent tab could not be focused."
fi
