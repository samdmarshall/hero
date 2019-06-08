# =======
# Imports
# =======

import os
import tables
import parsecfg
import parseopt
import sequtils
import strutils
import terminal
import algorithm
import strformat
# =====
# Types
# =====

type
  Subcommand = enum
    None,
    Usage,
    Version,
    Update,
    Status

type
  Settings = object
    root: string

  Link = object
    original: string
    linkpath: string


# =========
# Functions
# =========

proc progName(): string =
  result = "Hero"

proc usage(): void =
  echo("usage: " & progName() & " [-v|--version] [-h|--help] [status|update]")

proc versionInfo(): void =
  echo(progname() & " v0.2")

proc parseSettings(settings: OrderedTableRef[string, string]): Settings =
  var config = Settings(root: getCurrentDir())
  for setting, value in settings.pairs():
    case setting
    of "root":
      config.root = expandTilde(value)
    else:
      discard
  return config

proc initSettings(settings: Config): seq[Link] =
  var links = newSeq[Link]()
  var config: Settings
  for section, contents in settings.pairs():
    case section
    of "general":
      config = parseSettings(contents)
    of "links":
      for original_path, link_path in contents.pairs():
        let full_original_path = joinPath(config.root, original_path)
        let full_link_path  = expandTilde(link_path)
        let link_item = Link(original: full_original_path, linkpath: full_link_path)
        links.add(link_item)
  return links

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

var subcommand = None

let hero_config_path = getConfigDir().joinPath("hero/hero.ini")

if not existsFile(hero_config_path):
  echo("Unable to load settings file at path: " & hero_config_path)
  quit(QuitFailure)

let configuration = loadConfig(hero_config_path)

var parser = initOptParser()
for kind, key, value in parser.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": subcommand = Usage
    of "version", "v": subcommand = Version
    else: discard
  of cmdArgument:
    case key
    of "update": subcommand = Update
    of "status": subcommand = Status
    else: discard
  else: discard

var links = initSettings(configuration)

case subcommand
of None, Usage:
  usage()
  quit(QuitSuccess)
of Version:
  versionInfo()
  quit(QuitSuccess)
else:
  var lengths = map(links, proc(x:Link): int = x.linkpath.len)
  var ordered = lengths.sorted(system.cmp[int], Descending)[0] + 1
  for item in links:
    let valid_link = symlinkExists(item.linkpath)
    let link_status =
      if not valid_link: "$1 X $2" % [ansiForegroundColorCode(fgRed, true), ansiResetCode]
      else: "$1-->$2" % [ansiForegroundColorCode(fgGreen, true), ansiResetCode]
    case subcommand
    of Status:
      let classifier =
        if item.original.existsDir(): "/"
        else: ""
      let spacer = " ".repeat(ordered - item.linkpath.len)
      echo fmt"{item.linkpath}{spacer}{link_status} {item.original}{classifier}"
    of Update:
      if not valid_link:
        createSymlink(item.original, item.linkpath)
    else:
      discard
