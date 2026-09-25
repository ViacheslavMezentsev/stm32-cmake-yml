# Executed by Renode's IronPython at the exported BKPT, before the instruction.
# Only bridges SYS_EXIT_EXTENDED; it does not supply expected guest results.
import json
from Antmicro.Renode.Peripherals.CPU import RegisterValue

operation = int(self.GetRegister(0).RawValue)
arguments = int(self.GetRegister(1).RawValue)
if operation != 0x20 or arguments % 4 or not 0x20000000 <= arguments <= 0x20004FF8:
    result = {'error': 'Invalid SYS_EXIT_EXTENDED operation or RAM argument block'}
else:
    result = {'operation': operation,
              'reason': int(machine.SystemBus.ReadDoubleWord(arguments)),
              'status': int(machine.SystemBus.ReadDoubleWord(arguments + 4))}
with open(result_path, 'w') as destination:
    json.dump(result, destination)
self.SetRegister(15, RegisterValue.Create(int(self.PC.RawValue) + 2, 32))
self.IsHalted = True
