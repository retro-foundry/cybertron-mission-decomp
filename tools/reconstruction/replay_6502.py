"""Small, strict 6502 replay core for bounded Cybertron contract routines.

Only opcodes required by the selected replay are implemented. Encountering any
other opcode is an error, so expanding a replay requires an explicit audit of
the newly executed instruction semantics.
"""


class Replay6502:
    def __init__(self, memory: bytearray, jsr_handler=None):
        if len(memory) != 0x10000:
            raise ValueError("Replay6502 requires a 64K memory image")
        self.memory = memory
        self.jsr_handler = jsr_handler
        self.a = 0
        self.x = 0
        self.y = 0
        self.pc = 0
        self.carry = False
        self.zero = False
        self.negative = False

    def _fetch(self) -> int:
        value = self.memory[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return value

    def _word(self) -> int:
        low = self._fetch()
        return low | self._fetch() << 8

    def _flags(self, value: int) -> int:
        value &= 0xFF
        self.zero = value == 0
        self.negative = bool(value & 0x80)
        return value

    def _compare(self, register: int, value: int) -> None:
        self.carry = register >= value
        self._flags(register - value)

    def _branch(self, condition: bool) -> None:
        displacement = self._fetch()
        if condition:
            if displacement & 0x80:
                displacement -= 0x100
            self.pc = (self.pc + displacement) & 0xFFFF

    def run_subroutine(self, address: int, max_steps: int = 100000) -> int:
        self.pc = address
        for steps in range(1, max_steps + 1):
            opcode_address = self.pc
            opcode = self._fetch()
            if opcode == 0x60:  # RTS
                return steps
            if opcode == 0x85:  # STA zp
                self.memory[self._fetch()] = self.a
            elif opcode == 0x8D:  # STA abs
                self.memory[self._word()] = self.a
            elif opcode == 0x86:  # STX zp
                self.memory[self._fetch()] = self.x
            elif opcode == 0xA2:  # LDX #imm
                self.x = self._flags(self._fetch())
            elif opcode == 0xA4:  # LDY zp
                self.y = self._flags(self.memory[self._fetch()])
            elif opcode == 0xAC:  # LDY abs
                self.y = self._flags(self.memory[self._word()])
            elif opcode == 0xA5:  # LDA zp
                self.a = self._flags(self.memory[self._fetch()])
            elif opcode == 0xAD:  # LDA abs
                self.a = self._flags(self.memory[self._word()])
            elif opcode == 0xFE:  # INC abs,X
                target = (self._word() + self.x) & 0xFFFF
                self.memory[target] = self._flags(self.memory[target] + 1)
            elif opcode == 0xBD:  # LDA abs,X
                self.a = self._flags(self.memory[(self._word() + self.x) & 0xFFFF])
            elif opcode == 0xBC:  # LDY abs,X
                self.y = self._flags(self.memory[(self._word() + self.x) & 0xFFFF])
            elif opcode == 0xA6:  # LDX zp
                self.x = self._flags(self.memory[self._fetch()])
            elif opcode == 0xC9:  # CMP #imm
                self._compare(self.a, self._fetch())
            elif opcode == 0xC0:  # CPY #imm
                self._compare(self.y, self._fetch())
            elif opcode == 0x90:  # BCC rel
                self._branch(not self.carry)
            elif opcode == 0xF0:  # BEQ rel
                self._branch(self.zero)
            elif opcode == 0x30:  # BMI rel
                self._branch(self.negative)
            elif opcode == 0xD0:  # BNE rel
                self._branch(not self.zero)
            elif opcode == 0xA9:  # LDA #imm
                self.a = self._flags(self._fetch())
            elif opcode == 0x9D:  # STA abs,X
                self.memory[(self._word() + self.x) & 0xFFFF] = self.a
            elif opcode == 0xE8:  # INX
                self.x = self._flags(self.x + 1)
            elif opcode == 0xE6:  # INC zp
                target = self._fetch()
                self.memory[target] = self._flags(self.memory[target] + 1)
            elif opcode == 0xCA:  # DEX
                self.x = self._flags(self.x - 1)
            elif opcode == 0xE0:  # CPX #imm
                self._compare(self.x, self._fetch())
            elif opcode == 0xA0:  # LDY #imm
                self.y = self._flags(self._fetch())
            elif opcode == 0xAA:  # TAX
                self.x = self._flags(self.a)
            elif opcode == 0x8A:  # TXA
                self.a = self._flags(self.x)
            elif opcode == 0x29:  # AND #imm
                self.a = self._flags(self.a & self._fetch())
            elif opcode == 0xB9:  # LDA abs,Y
                self.a = self._flags(self.memory[(self._word() + self.y) & 0xFFFF])
            elif opcode == 0x88:  # DEY
                self.y = self._flags(self.y - 1)
            elif opcode == 0x10:  # BPL rel
                self._branch(not self.negative)
            elif opcode == 0x20:  # JSR abs
                target = self._word()
                if self.jsr_handler is None or not self.jsr_handler(self, target):
                    raise AssertionError(
                        f"unhandled JSR ${target:04X} at ${opcode_address:04X}"
                    )
            elif opcode == 0x18:  # CLC
                self.carry = False
            elif opcode == 0x38:  # SEC
                self.carry = True
            elif opcode == 0x79:  # ADC abs,Y
                value = self.memory[(self._word() + self.y) & 0xFFFF]
                total = self.a + value + int(self.carry)
                self.carry = total > 0xFF
                self.a = self._flags(total)
            elif opcode == 0x69:  # ADC #imm
                value = self._fetch()
                total = self.a + value + int(self.carry)
                self.carry = total > 0xFF
                self.a = self._flags(total)
            elif opcode == 0xE9:  # SBC #imm
                value = self._fetch()
                total = self.a - value - int(not self.carry)
                self.carry = total >= 0
                self.a = self._flags(total)
            elif opcode == 0x4C:  # JMP abs (tail-call handler may end replay)
                target = self._word()
                if self.jsr_handler is not None and self.jsr_handler(self, target):
                    return steps
                self.pc = target
            elif opcode == 0xEE:  # INC abs
                target = self._word()
                self.memory[target] = self._flags(self.memory[target] + 1)
            elif opcode == 0xC6:  # DEC zp
                target = self._fetch()
                self.memory[target] = self._flags(self.memory[target] - 1)
            else:
                raise AssertionError(
                    f"unsupported opcode ${opcode:02X} at ${opcode_address:04X}"
                )
        raise AssertionError(f"replay at ${address:04X} exceeded {max_steps} steps")
