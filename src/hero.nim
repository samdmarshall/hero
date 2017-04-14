# =======
# Imports
# =======

import os
import tables
import parsecfg
import parseopt2


# =====
# Types
# =====

type
  Subcommand = enum
    None,
    Check,
    Update

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
  result = getAppFilename().extractFilename()

proc usage(): void =
  echo("usage: " & progName() & " [-v|--version] [-h|--help] [check|update]")
  quit(QuitSuccess)

proc versionInfo(): void =
  echo(progname() & " v0.1")
  quit(QuitSuccess)

proc parseSettings(settings: OrderedTableRef[string, string]): Settings =
  var config = Settings(root: getCurrentDir())
  for setting, value in settings.pairs():
    case setting
    of "root":
      config.root = expandTilde(value)
    else:
      discard
  return config

proc parseLinks(data: OrderedTableRef[string, string]): seq[Link] =
  return @[]

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

let base_path =
  if not existsEnv("XDG_CONFIG_HOME"):
    getEnv("XDG_CONFIG_HOME")
  else:
    expandTilde("~/.config")
let hero_config_path = base_path.joinPath("hero/hero.ini")

if not existsFile(hero_config_path):
  echo("Unable to load settings file at path: " & hero_config_path)
  quit(QuitFailure)

let configuration = loadConfig(hero_config_path)

for kind, key, value in getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h":
      usage()
    of "version", "v":
      versionInfo()
    else:
      discard
  of cmdArgument:
    case key
    of "update":
      subcommand = Update
    of "check":
      subcommand = Check
    else:
      discard
  else:
    discard

let links = initSettings(configuration)

case subcommand
of None:
  usage()
else:
  for item in links:
    let valid_link = symlinkExists(item.linkpath)
    if not valid_link:
      case subcommand
      of Check:
        echo("Failure: [" & item.original & " -> " & item.linkpath & "] not linked!")
        quit(QuitFailure)
      of Update:
        createSymlink(item.original, item.linkpath)
      else:
        discard
