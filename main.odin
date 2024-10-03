package main

import "core:fmt"
import "core:mem"
import "core:os"
import rl "vendor:raylib"

DISPLAY_WIDTH :: 64
DISPLAY_HEIGHT :: 32
DISPLAY_SCALE :: 16

FONT_ADDRESS :: 0x50
FONT_SIZE :: 0x50
FONT_CHARACTER_SIZE :: 0x5

ROM_ADDRESS :: 0x200
ROM_SIZE :: 0xE00

TARGET_FPS :: 60
OPS_PER_SECOND :: 700
DEFAULT_OPS_PER_FRAME :: OPS_PER_SECOND / TARGET_FPS

// carry flag
F :: 0xF

font := []u8 {
	0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	0x20, 0x60, 0x20, 0x20, 0x70, // 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	0xF0, 0x80, 0xF0, 0x80, 0x80,  // F
}

Chip :: struct {
    memory: [4096]u8,
    display: [DISPLAY_WIDTH][DISPLAY_HEIGHT]bool,
    stack: [16]u16,

    SP: u8, // stack pointer
    V: [16]u8, // registers
    I: u16, // index
    PC: u16, // program counter

    delay_timer: u8,
	sound_timer: u8,

    opcodes_per_frame: u8,
}

chip_init :: proc() -> (Chip, bool) {
    chip := Chip{}
    copy(chip.memory[FONT_ADDRESS:FONT_ADDRESS + FONT_SIZE], font)

	file, file_err := os.open("./rom/PONG")
	if file_err != os.ERROR_NONE {
		fmt.println("failed to open rom file")
		os.close(file)
		return chip, false
	}

	_, read_err := os.read(file, chip.memory[ROM_ADDRESS:ROM_ADDRESS + ROM_SIZE])
	if read_err != os.ERROR_NONE {
		fmt.println("failed to read data from rom")
		os.close(file)
		return chip, false
	}

    chip.PC = ROM_ADDRESS
    chip.opcodes_per_frame = DEFAULT_OPS_PER_FRAME
    return chip, true
}

chip_opcode :: proc(using chip: ^Chip) -> bool {
    opcode: u16 = (u16(memory[PC]) << 8) | u16(memory[PC + 1])

    optype: u8 = u8(opcode >> 12)      // first 4 bits
    X: u8 = u8((opcode & 0x0F00) >> 8) // second 4 bits
    Y: u8 = u8((opcode & 0x00F0) >> 4) // third 4 bits
    N: u8 = u8(opcode & 0x000F)        // last 4 bits
    NN: u8 = u8(opcode & 0x00FF)       // last 8 bits
	NNN: u16 = opcode & 0x0FFF         // last 12 bits

    PC += 2
    fmt.printf("current opcode: 0x%x\n", opcode)
    switch optype {
    case 0x0:
        if NN == 0xE0 {
            // clear display
            mem.zero(&display, DISPLAY_WIDTH * DISPLAY_HEIGHT)
        } else if NN == 0xEE {
            // return from subroutine
            SP -= 1
            PC = stack[SP]
            stack[SP] = 0
        }
    case 0x1:
        // jump
        PC = NNN
    case 0x2:
        // call subroutine
        stack[SP] = PC
		SP += 1
		PC = NNN
    case 0x3:
        // skip next instruction if VX == NN
        if V[X] == NN {
            PC += 2
        }
    case 0x4:
        // skip next instruction if VX != NN
        if V[X] != NN {
            PC += 2
        }

    case 0x5:
        // skip next instruction if VX == VY
        if V[X] == V[Y] {
            PC += 2
        }

    case 0x6:
        // set VX = NN
        V[X] = NN

    case 0x7:
        // set VX = VX + NN
        V[X] += NN

    case 0x8:
        switch N {

        // set VX == VY
        case 0x0:
            V[X] = V[Y]

        // set VX = VX OR VY
        case 0x1:
            V[X] |= V[Y]

        // set VX = VX AND VY
        case 0x2:
            V[X] &= V[Y]

        // set VX = VX XOR VY
        case 0x3:
            V[X] ~= V[Y]

        // set VX = VX + VY, set VF = carry
        case 0x4:
            sum: u16 = u16(V[X]) + u16(V[Y])
            if sum > 255 {
                V[F] = 1
            } else {
                V[F] = 0
            }
            V[X] = u8(sum)

        // set VX = VX - VY, set VF = NOT borrow
        case 0x5:
            if V[X] > V[Y] {
                V[F] = 1
            } else {
                V[F] = 0
            }
            V[X] -= V[Y]

        // set VX = VX SHR 1
        case 0x6:
            if V[X] & 0x1 == 1 {
                V[F] = 1
            } else {
                V[F] = 0
            }
            V[X] >>= 1

        // set VX = VY - VX, set VF = NOT borrow
        case 0x7:
            if V[Y] > V[X] {
                V[F] = 1
            } else {
                V[F] = 0
            }
            V[X] = V[Y] - V[X]

        // set VX = VX SHL 1
        case 0xE:
            V[F] = V[Y] >> 7
            V[X] <<= 1

        case:
            fmt.printf("unknown opcode: 0x%x\n", opcode)
            return false
        }

    // skip next instruction if VX != VY
    case 0x9:
        if V[X] != V[Y] {
            PC += 2
        }

    // set I == NNN
    case 0xA:
        I = NNN

    // jump to location nnn + V0
    case 0xB:
        PC = u16(V[0]) + NNN

    // set VX = random byte AND NN
    case 0xC:
        V[X] = u8(rl.GetRandomValue(0, 255)) & NN

    // display n-byte sprite starting at memory location I at (VX, VY), set VF = collision
    case 0xD:
        V[F] = 0
        x_pos := V[X] % DISPLAY_WIDTH
        y_pos := V[Y] % DISPLAY_HEIGHT

        for row in 0..<N {
            pixel_y_pos := y_pos + row
            if pixel_y_pos >= DISPLAY_HEIGHT {
                break
            }

            sprite_row: u8 = memory[I + u16(row)]

            for col in 0..<8 {
                pixel_x_pos := x_pos + u8(col)
                if pixel_x_pos >= DISPLAY_WIDTH {
                    break
                }

                should_swap_pixel: bool = bool((sprite_row >> (7 - u8(col))) & 1)
                pixel_is_on: bool = display[pixel_x_pos][pixel_y_pos]

                if should_swap_pixel {
                    if pixel_is_on {
                        display[pixel_x_pos][pixel_y_pos] = false
                        V[F] = 1
                    } else {
                        display[pixel_x_pos][pixel_y_pos] = true
                    }
                }
            }
        }

    case 0xE:
        if NN == 0x9E && is_key_down(V[X]) {
            // skip next instruction if key with the value of VX is pressed
            PC += 2
        } else if NN == 0xA1 && !is_key_down(V[X]) {
            // skip next instruction if key with the value of VX is not pressed
            PC += 2
        } else {
            fmt.printf("unknown opcode: 0x%x\n", opcode)
            return false
        }

    case 0xF:
        switch NN {

        // set VX = delay timer
        case 0x07:
            V[X] = delay_timer

        // wait for key press, store the value of the key in VX
        case 0x0A:
            for key in 0x0..=0xF {
                if is_key_down(u8(key)) {
                    V[X] = u8(key)
                    return true
                }
            }
            PC -= 2

        // set delay timer = VX
        case 0x15:
            delay_timer = V[X]

        // set sound timer = VX
        case 0x18:
            sound_timer = V[X]

        // set I = I + VX
        case 0x1E:
            I += u16(V[X])

        // set I = location of sprite for digit VX
        case 0x29:
            I = FONT_ADDRESS + u16(V[X]) * FONT_CHARACTER_SIZE

        // store BCD representation of VX in memory locations I, I+1 and I+2
        case 0x33:
            value: u8 = V[X]

            ones: u8 = value % 10
            value /= 10

            tens: u8 = value % 10
            value /= 10

            hundreds: u8 = value

            memory[I] = hundreds
            memory[I + 1] = tens
            memory[I + 2] = ones

        // store registers from V0 to VX in memory starting at location I
        case 0x55:
            for val, index in V[0:X+1] {
                memory[I + u16(index)] = val
            }

        // read registers from V0 to VX from memory starting at location I
        case 0x65:
            for index: u8 = 0; index <= X; index += 1 {
                V[index] = memory[I + u16(index)];
            }

        case:
            fmt.printf("unknown opcode: 0x%x\n", opcode)
            return false
        }

    case:
        fmt.printf("unknown opcode: 0x%x\n", opcode)
        return false
    }

    return true
}

chip_update :: proc(chip: ^Chip) {
    input_update()
    for i in 0..=chip.opcodes_per_frame {
        if !chip_opcode(chip) {
            break
        }
        // decrement timers
        delay: i16 = i16(chip.delay_timer) - 1
        delay = max(delay, 0)
        chip.delay_timer = u8(delay)

        sound: i16 = i16(chip.sound_timer) - 1
        sound = max(sound, 0)
        chip.sound_timer = u8(sound)
    }
}

draw :: proc(using chip: ^Chip) {
    rl.BeginDrawing()
 	rl.ClearBackground(rl.BLACK)

	for y in 0..<DISPLAY_HEIGHT {
		for x in 0..<DISPLAY_WIDTH {
            if display[x][y] {
				rl.DrawRectangle(i32(x) * DISPLAY_SCALE, i32(y) * DISPLAY_SCALE, DISPLAY_SCALE, DISPLAY_SCALE, rl.WHITE)
            }
		}
	}

    rl.EndDrawing()
}

main :: proc() {
    chip, success := chip_init()
    if !success {
        fmt.println("failed to start up chip8 emulator")
        os.exit(1)
    }

    rl.InitWindow(DISPLAY_WIDTH * DISPLAY_SCALE, DISPLAY_HEIGHT * DISPLAY_SCALE, "chip8")
    defer rl.CloseWindow()

    rl.SetTargetFPS(TARGET_FPS)

    for !rl.WindowShouldClose() {
        chip_update(&chip)
        draw(&chip)
    }
}
