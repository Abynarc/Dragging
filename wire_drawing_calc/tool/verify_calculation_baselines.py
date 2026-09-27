"""Check immutable calculation oracles before testing a changed implementation."""
from pathlib import Path
import hashlib

APP = Path(__file__).resolve().parents[1]
EXPECTED = {
    'test/fixtures/calculations_v3_0_0_11.json': 'd1b564ab0c90ce5772cf03f474e3dc5b5bbe20c40a8a5b8116c1b8431b219317',
    'test/fixtures/raw_calculations_step4.json': '8ae5dcf69198734013781763eca33b902f1f5c6cc00cd83262bb57ba9b8a26e0',
    'test/reference/original_app.dart': '848d3536da0d8d973219ada0261870c348b27212b528d3ff56b7ae81e9469c18',
}
for name, expected in EXPECTED.items():
    actual = hashlib.sha256((APP / name).read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f'Historical oracle changed: {name}. Do not regenerate expected values to match new code.')
print('All 3 calculation oracles match their frozen SHA-256 hashes.')
