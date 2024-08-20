from workshop_service.utils import parse_size


def test_parse_no_suffix():
    assert parse_size("100") == 100


def test_parse_with_suffixes():
    assert parse_size("100b") == 100
    assert parse_size("100k") == 100e3
    assert parse_size("100kb") == 100e3
    assert parse_size("100ki") == 1024 * 100
    assert parse_size("100kib") == 1024 * 100
    assert parse_size("100m") == 100e6
    assert parse_size("100mb") == 100e6
    assert parse_size("100mi") == 1024 * 1024 * 100
    assert parse_size("100mib") == 1024 * 1024 * 100
    assert parse_size("100g") == 100e9
    assert parse_size("100gb") == 100e9
    assert parse_size("100gi") == 1024 * 1024 * 1024 * 100
    assert parse_size("100gib") == 1024 * 1024 * 1024 * 100


def test_assert_mixed_case():
    assert parse_size("100kIB") == 1024 * 100


def test_negative_size():
    assert parse_size("-100kb") == -100e3


def test_fractional_size():
    assert parse_size("0.7kb") == 700
