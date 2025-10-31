from pathlib import Path
from typing import List, Dict


def loadDecimals(txt_path: Path) -> List[int]:
    decimals = set()
    text = txt_path.read_text(encoding="utf-8")

    for char in text:
        decimals.add(ord(char))

    return sorted(decimals)


def collapseToRanges(decimals: List[int]) -> List[Dict[str, int]]:
    if not decimals:
        return []

    ranges: List[Dict[str, int]] = []
    start = end = decimals[0]

    for cur in decimals[1:]:
        if cur == end + 1:
            end = cur
        else:
            ranges.append({"start": start, "end": end})
            start = end = cur

    ranges.append({"start": start, "end": end})
    return ranges


def getDecimalsFromFile(path):
    txt_file = Path(path)
    if not txt_file.is_file():
        raise FileNotFoundError(f"{txt_file} not found in the current directory")
        
    decimals = loadDecimals(txt_file)
    compact_ranges = collapseToRanges(decimals)

    return compact_ranges