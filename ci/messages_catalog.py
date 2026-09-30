"""Read stm32-cmake-yml message catalogs (spec 4.16.5, 4.16.6) without CMake.

The catalog is a CMake file with calls
``stm32_yml_msg_def(<code> [RETIRED] "<RU>" ["<EN>"])``. Only quoted arguments
with the escapes ``\\"``, ``\\\\``, ``\\n`` and ``\\t`` are supported, which is what
the catalog format allows.
"""

import re
from pathlib import Path

CODE = re.compile(r"^[IWE]\d{3}$")
LEVELS = {"I": "STATUS", "W": "WARNING", "E": "FATAL_ERROR"}
ESCAPES = {'"': '"', "\\": "\\", "n": "\n", "t": "\t"}
PARAM = re.compile(r"\{(\d+)\}")


class CatalogError(ValueError):
    pass


def _tokens(text, start, origin):
    """Yield (kind, value, line) tokens of one command call starting after '('."""
    index = start
    while True:
        while index < len(text) and text[index] in " \t\r\n":
            index += 1
        if index >= len(text):
            raise CatalogError(f"{origin}: unterminated stm32_yml_msg_def")
        line = text.count("\n", 0, index) + 1
        char = text[index]
        if char == ")":
            return
        if char == "#":
            index = text.index("\n", index) if "\n" in text[index:] else len(text)
            continue
        if char == '"':
            value, index = [], index + 1
            while True:
                if index >= len(text):
                    raise CatalogError(f"{origin}:{line}: unterminated string")
                char = text[index]
                if char == "\\":
                    escaped = text[index + 1:index + 2]
                    if escaped not in ESCAPES:
                        raise CatalogError(f"{origin}:{line}: unsupported escape \\{escaped}")
                    value.append(ESCAPES[escaped])
                    index += 2
                elif char == '"':
                    index += 1
                    break
                else:
                    value.append(char)
                    index += 1
            yield "string", "".join(value), line
        else:
            match = re.compile(r"[^\s()\"#]+").match(text, index)
            yield "word", match.group(0), line
            index = match.end()


def params(text):
    return sorted({int(number) for number in PARAM.findall(text)})


def load(path):
    """Return {code: {"retired", "ru", "en", "line"}} for one catalog file."""
    path = Path(path)
    text = path.read_text(encoding="utf-8")
    catalog = {}
    for match in re.finditer(r"^\s*stm32_yml_msg_def\s*\(", text, re.M):
        tokens = list(_tokens(text, match.end(), path))
        if not tokens or tokens[0][0] != "word" or not CODE.match(tokens[0][1]):
            raise CatalogError(f"{path}: invalid message code in {tokens[:1]}")
        code, line = tokens[0][1], tokens[0][2]
        rest = tokens[1:]
        retired = bool(rest) and rest[0] == ("word", "RETIRED", rest[0][2])
        if retired:
            rest = rest[1:]
        if not 1 <= len(rest) <= 2 or any(kind != "string" for kind, _, _ in rest):
            raise CatalogError(f"{path}:{line}: {code}: expected \"RU\" [\"EN\"]")
        if code in catalog:
            raise CatalogError(f"{path}:{line}: duplicate code {code}")
        catalog[code] = {"retired": retired, "ru": rest[0][1],
                         "en": rest[1][1] if len(rest) == 2 else "", "line": line}
    return catalog


def render(entry, lang, args):
    """Text as stm32_yml_msg prints it: the chosen language, Russian as fallback."""
    text = entry["en"] if lang == "en" and entry["en"] else entry["ru"]
    # One pass, like stm32_yml_msg: "{n}" inside an argument value is kept.
    def value(match):
        number = int(match.group(1))
        return args[number - 1] if 1 <= number <= len(args) else match.group(0)
    return PARAM.sub(value, text)


def level(code):
    return LEVELS[code[0]]
