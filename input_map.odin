package main

import rl "vendor:raylib"

input_map: [16]bool
input_update :: proc() {
    // Key press
    if rl.IsKeyPressed(rl.KeyboardKey.X) {
        input_map[0] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.ONE) {
        input_map[1] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.TWO) {
        input_map[2] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.THREE) {
        input_map[3] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.Q) {
        input_map[4] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.W) {
        input_map[5] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.E) {
        input_map[6] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.A) {
        input_map[7] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.S) {
        input_map[8] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.D) {
        input_map[9] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.Z) {
        input_map[10] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.C) {
        input_map[11] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.FOUR) {
        input_map[12] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.R) {
        input_map[13] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.F) {
        input_map[14] = true
    }
    if rl.IsKeyPressed(rl.KeyboardKey.V) {
        input_map[15] = true
    }

    // Key release
    if rl.IsKeyReleased(rl.KeyboardKey.X) {
        input_map[0] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.ONE) {
        input_map[1] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.TWO) {
        input_map[2] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.THREE) {
        input_map[3] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.Q) {
        input_map[4] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.W) {
        input_map[5] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.E) {
        input_map[6] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.A) {
        input_map[7] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.S) {
        input_map[8] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.D) {
        input_map[9] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.Z) {
        input_map[10] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.C) {
        input_map[11] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.FOUR) {
        input_map[12] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.R) {
        input_map[13] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.F) {
        input_map[14] = false
    }
    if rl.IsKeyReleased(rl.KeyboardKey.V) {
        input_map[15] = false
    }
}

is_key_down :: proc(key: u8) -> bool {
    assert(key >= 0x0 && key <= 0xF)
    return input_map[key]
}
