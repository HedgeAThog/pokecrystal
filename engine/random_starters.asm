SECTION "RandomizeStarters", ROMX

RandomizeStarters::
    ; This function will select three unique random Pokémon
    ; and store them in wRandomStarter1, wRandomStarter2, and wRandomStarter3.

.loop1
    call GetRandomPokemonID
    ld [wRandomStarter1], a
.loop2
    call GetRandomPokemonID
    ld b, a
    ld a, [wRandomStarter1]
    cp b
    jr z, .loop2 ; If it's the same as starter 1, try again
    ld a, b
    ld [wRandomStarter2], a
.loop3
    call GetRandomPokemonID
    ld b, a
    ld a, [wRandomStarter1]
    cp b
    jr z, .loop3 ; If it's the same as starter 1, try again
    ld a, [wRandomStarter2]
    cp b
    jr z, .loop3 ; If it's the same as starter 2, try again
    ld a, b
    ld [wRandomStarter3], a
    ret

GetRandomPokemonID:
    ; This subroutine returns a random Pokémon ID in register 'a'
    ; It will keep trying until it gets a valid, non-glitch Pokémon.
.loop
    call Random ; Get a random byte in 'a'
    cp NUM_POKEMON + 1
    jr nc, .loop ; If the ID is too high, try again
    and a
    jr z, .loop ; If the ID is 0 (egg), try again
    ret