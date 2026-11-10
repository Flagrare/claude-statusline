#!/usr/bin/env bash
# Custom rows for the subagent panel (Claude Code's subagentStatusLine).
# One line per task: status, name, what it's doing, model + effort, elapsed
# time, tokens, and a sparkline of how fast it's been burning tokens lately.
#
#   ● Explore · Find the PR template in the repo… · sonnet high · 1m12s · 48k ▂▃▅▇▆
#
# Reads {"columns": N, "tasks": [...]} on stdin, writes {"id","content"} lines.
command -v jq &>/dev/null || exit 0
jq -c --argjson now "$(date +%s)" '
  def clean: if . == null then "" else tostring | gsub("[\u0000-\u001f\u007f]"; " ") end;
  def human: if . >= 1000000 then "\((. / 100000 | floor) / 10)M"
             elif . >= 1000 then "\(. / 1000 | floor)k" else "\(.)" end;
  def dur: if . < 60 then "\(.)s"
           elif . < 3600 then "\(. / 60 | floor)m\(. % 60 | tostring | if length < 2 then "0" + . else . end)s"
           else "\(. / 3600 | floor)h\((. % 3600) / 60 | floor)m" end;
  def spark:
    [range(1; length) as $i | (.[$i] - .[$i - 1]) | if . < 0 then 0 else . end] as $d
    | if ($d | length) < 2 or ($d | max) == 0 then ""
      else ($d | max) as $m
        | [$d[] | ["▁","▂","▃","▄","▅","▆","▇","█"][(. / $m * 7 | floor)]] | join("")
      end;
  def short_model:
    clean | ascii_downcase
    | if test("fable") then "fable" elif test("opus") then "opus"
      elif test("sonnet") then "sonnet" elif test("haiku") then "haiku"
      else sub("^claude-"; "") end;
  "\u001b[0m" as $R | "\u001b[38;5;240m" as $DIM |
  (.columns // 100) as $cols
  | .tasks[]? as $t
  | ($t.status // "" | clean) as $st
  | (if $st == "running" then "\u001b[33m●"
     elif $st == "completed" then "\u001b[32m✓"
     elif $st == "failed" then "\u001b[31m✗"
     else "\u001b[38;5;244m■" end) as $mark
  | (($t.name // $t.agentType // "agent") | clean) as $name
  | ([ ($t.model | if . then short_model else empty end),
       ($t.effort | if . then clean else empty end) ] | join(" ")) as $me
  | ((($now * 1000 - ($t.startTime // ($now * 1000))) / 1000 | floor) | if . < 0 then 0 else . end) as $el
  | (($t.tokenCount // 0) | floor) as $tok
  | (if ($t.contextWindowSize // 0) > 0 then " (\(($tok * 100 / $t.contextWindowSize) | floor)%)" else "" end) as $pct
  | (($t.tokenSamples // []) | spark) as $sp
  | ([ (if $me != "" then $me else empty end), ($el | dur), "\($tok | human)\($pct)" ] | join(" · ")
     + (if $sp != "" then " " + $sp else "" end)) as $tail
  | (($t.label // $t.description // "") | clean) as $label
  | ($cols - ($name | length) - ($tail | length) - 10) as $room
  | (if $room < 8 then ""
     elif ($label | length) > $room then " · " + $label[0:($room - 1)] + "…"
     else (if $label != "" then " · " + $label else "" end) end) as $lab
  | {id: ($t.id | clean),
     content: "\($mark)\($R) \($name)\($DIM)\($lab)\($R) \($DIM)· \($tail)\($R)"}
' 2>/dev/null
