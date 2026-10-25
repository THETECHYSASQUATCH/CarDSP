import math
import struct
import subprocess
import sys

executable = sys.argv[1]
def run(data, rate='48000', gain='-6'):
    return subprocess.run([executable, rate, gain], input=data, capture_output=True)

samples = [v for i in range(3000) for v in (0.2 * math.sin(i * 0.13), 0.0)]
result = run(struct.pack(f'{len(samples)}f', *samples))
assert result.returncode == 0, result.stderr
output = struct.unpack(f'{len(samples)}f', result.stdout)
assert all(math.isfinite(x) for x in output)
assert all(output[i] == 0 for i in range(1, len(output), 2)), 'channel bleed'
assert max(abs(x) for x in output) < 0.12, 'gain not applied'
assert run(b'').returncode == 0
assert run(b'\x00').returncode != 0
assert run(struct.pack('2f', float('nan'), 0)).returncode != 0
assert run(b'', rate='0').returncode != 0
assert run(b'', rate='48000junk').returncode != 0
assert run(b'', gain='inf').returncode != 0
print('PCM adapter: streaming, gain, stereo isolation and invalid input checks passed')
