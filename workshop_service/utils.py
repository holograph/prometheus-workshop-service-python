import re

SIZE_SUFFIX_SCALES = (
    (("g", "gb"), 10 ** 9),
    (("gi", "gib"), 2 ** 30),
    (("m", "mb"), 10 ** 6),
    (("mi", "mib"), 2 ** 20),
    (("k", "kb"), 10 ** 3),
    (("ki", "kib"), 2 ** 10),
)
SIZE_SUFFIX_SCALE_MAP = {
    key: scale
    for keys, scale in SIZE_SUFFIX_SCALES
    for key in keys
}
SIZE_SUFFIX_LIST=list(SIZE_SUFFIX_SCALE_MAP.keys())
SIZE_SUFFIX_LIST.sort(key=lambda k: len(k), reverse=True)
SIZE_SUFFIX_PATTERN = "|".join(SIZE_SUFFIX_LIST)
SIZE_PATTERN = re.compile(f"([0-9.-]+)({SIZE_SUFFIX_PATTERN})?", re.IGNORECASE)

def parse_size(size_str: str | None) -> int | None:
    if not size_str:
        return None
    if not (m := SIZE_PATTERN.match(size_str)):
        raise ValueError(f"Invalid size pattern '{size_str}'")
    [size, scale] = m.groups()
    size = float(size)
    scale = SIZE_SUFFIX_SCALE_MAP[scale.lower()] if scale else 1
    return int(size * scale)
