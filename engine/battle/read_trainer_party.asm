ReadTrainerParty:
	ld a, [wInBattleTowerBattle]
	bit IN_BATTLE_TOWER_BATTLE_F, a
	ret nz

	ld a, [wLinkMode]
	and a
	ret nz

	ld hl, wOTPartyCount
	xor a
	ld [hli], a
	dec a
	ld [hl], a

	ld hl, wOTPartyMons
	ld bc, PARTYMON_STRUCT_LENGTH * PARTY_LENGTH
	xor a
	call ByteFill

	ld a, [wOtherTrainerClass]
	cp CAL
	jr nz, .not_cal2
	ld a, [wOtherTrainerID]
	cp CAL2
	jr z, .cal2
	ld a, [wOtherTrainerClass]
.not_cal2

	dec a
	ld c, a
	ld b, 0
	ld hl, TrainerGroups
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, [wOtherTrainerID]
	ld b, a
.skip_trainer
	dec b
	jr z, .got_trainer
.loop
	ld a, [hli]
	cp -1
	jr nz, .loop
	jr .skip_trainer
.got_trainer

.skip_name
	ld a, [hli]
	cp "@"
	jr nz, .skip_name

	ld a, [hli]
	ld c, a
	ld b, 0
	ld d, h
	ld e, l
	ld hl, TrainerTypes
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, .done
	push bc
	jp hl

.done
	jp ComputeTrainerReward

.cal2
	ld a, BANK(sMysteryGiftTrainer)
	call OpenSRAM
	ld de, sMysteryGiftTrainer
	call TrainerType2
	call CloseSRAM
	jr .done

TrainerTypes:
; entries correspond to TRAINERTYPE_* constants
	dw TrainerType1 ; level, species
	dw TrainerType2 ; level, species, moves
	dw TrainerType3 ; level, species, item
	dw TrainerType4 ; level, species, item, moves

TrainerType1:
; normal (level, species)
	ld h, d
	ld l, e
.loop
	ld a, [hli]
	cp $ff
	ret z

	ld [wCurPartyLevel], a
	ld a, [hli]

; --- Start In-line Swap Logic ---
	ld c, a ; BACK UP original species FIRST.
	push hl
	ld hl, wTrainerClass
	ld a, [hl]
	cp RIVAL1
	jr z, .CheckSpecies_T1
	cp RIVAL2
	jr nz, .NotRival_T1
.CheckSpecies_T1:
	ld a, c ; Restore species to check
	cp CHIKORITA
	jr z, .DoSwap_T1
	cp BAYLEEF
	jr z, .DoSwap_T1
	cp MEGANIUM
	jr z, .DoSwap_T1
	cp CYNDAQUIL
	jr z, .DoSwap_T1
	cp QUILAVA
	jr z, .DoSwap_T1
	cp TYPHLOSION
	jr z, .DoSwap_T1
	cp TOTODILE
	jr z, .DoSwap_T1
	cp CROCONAW
	jr z, .DoSwap_T1
	cp FERALIGATR
	jr z, .DoSwap_T1
	jr .NotRival_T1 ; Not a starter, so don't swap
.DoSwap_T1:
	ld a, [wRivalStarterSpecies]
	and a
	jr z, .NotRival_T1
	pop hl
	jr .DoneSwap_T1
.NotRival_T1:
	ld a, c
	pop hl
.DoneSwap_T1:
; --- End In-line Swap Logic ---

	ld [wCurPartySpecies], a
	ld a, OTPARTYMON
	ld [wMonType], a
	push hl
	predef TryAddMonToParty
	pop hl
	jr .loop

TrainerType2:
; moves
	ld h, d
	ld l, e
.loop
	ld a, [hli]
	cp $ff
	ret z

	ld [wCurPartyLevel], a
	ld a, [hli]

; --- Start In-line Swap Logic ---
	ld c, a ; BACK UP original species FIRST.
	xor a   ; NOW, clear 'a' for the flag.
	ld [wDidSwapRivalMon], a
	push hl
	ld hl, wTrainerClass
	ld a, [hl]
	cp RIVAL1
	jr z, .CheckSpecies_T2
	cp RIVAL2
	jr nz, .NotRival_T2
.CheckSpecies_T2:
	ld a, c ; Restore species to check
	cp CHIKORITA
	jr z, .DoSwap_T2
	cp BAYLEEF
	jr z, .DoSwap_T2
	cp MEGANIUM
	jr z, .DoSwap_T2
	cp CYNDAQUIL
	jr z, .DoSwap_T2
	cp QUILAVA
	jr z, .DoSwap_T2
	cp TYPHLOSION
	jr z, .DoSwap_T2
	cp TOTODILE
	jr z, .DoSwap_T2
	cp CROCONAW
	jr z, .DoSwap_T2
	cp FERALIGATR
	jr z, .DoSwap_T2
	jr .NotRival_T2 ; Not a starter, so don't swap
.DoSwap_T2:
	ld a, [wRivalStarterSpecies]
	and a
	jr z, .NotRival_T2
	ld c, a
	ld a, 1
	ld [wDidSwapRivalMon], a
	ld a, c
	pop hl
	jr .DoneSwap_T2
.NotRival_T2:
	ld a, c
	pop hl
.DoneSwap_T2:
; --- End In-line Swap Logic ---

	ld [wCurPartySpecies], a
	ld a, OTPARTYMON
	ld [wMonType], a

	push hl
	predef TryAddMonToParty
	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl

	ld a, [wDidSwapRivalMon]
	and a
	jr nz, .loop

	ld b, NUM_MOVES
.copy_moves
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy_moves

	push hl

	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1Species
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, MON_PP
	add hl, de
	push hl
	ld hl, MON_MOVES
	add hl, de
	pop de

	ld b, NUM_MOVES
.copy_pp
	ld a, [hli]
	and a
	jr z, .copied_pp

	push hl
	push bc
	dec a
	ld hl, Moves + MOVE_PP
	ld bc, MOVE_LENGTH
	call AddNTimes
	ld a, BANK(Moves)
	call GetFarByte
	pop bc
	pop hl

	ld [de], a
	inc de
	dec b
	jr nz, .copy_pp
.copied_pp

	pop hl
	jp .loop

TrainerType3:
; item
	ld h, d
	ld l, e
.loop
	ld a, [hli]
	cp $ff
	ret z

	ld [wCurPartyLevel], a
	ld a, [hli]

; --- Start In-line Swap Logic ---
	ld c, a ; BACK UP original species FIRST.
	push hl
	ld hl, wTrainerClass
	ld a, [hl]
	cp RIVAL1
	jr z, .CheckSpecies_T3
	cp RIVAL2
	jr nz, .NotRival_T3
.CheckSpecies_T3:
	ld a, c ; Restore species to check
	cp CHIKORITA
	jr z, .DoSwap_T3
	cp BAYLEEF
	jr z, .DoSwap_T3
	cp MEGANIUM
	jr z, .DoSwap_T3
	cp CYNDAQUIL
	jr z, .DoSwap_T3
	cp QUILAVA
	jr z, .DoSwap_T3
	cp TYPHLOSION
	jr z, .DoSwap_T3
	cp TOTODILE
	jr z, .DoSwap_T3
	cp CROCONAW
	jr z, .DoSwap_T3
	cp FERALIGATR
	jr z, .DoSwap_T3
	jr .NotRival_T3 ; Not a starter, so don't swap
.DoSwap_T3:
	ld a, [wRivalStarterSpecies]
	and a
	jr z, .NotRival_T3
	pop hl
	jr .DoneSwap_T3
.NotRival_T3:
	ld a, c
	pop hl
.DoneSwap_T3:
; --- End In-line Swap Logic ---

	ld [wCurPartySpecies], a
	ld a, OTPARTYMON
	ld [wMonType], a
	push hl
	predef TryAddMonToParty
	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1Item
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	jr .loop

TrainerType4:
; item + moves
	ld h, d
	ld l, e
.loop
	ld a, [hli]
	cp $ff
	ret z

	ld [wCurPartyLevel], a
	ld a, [hli]

; --- Start In-line Swap Logic ---
	ld c, a ; BACK UP original species FIRST.
	xor a   ; NOW, clear 'a' for the flag.
	ld [wDidSwapRivalMon], a
	push hl
	ld hl, wTrainerClass
	ld a, [hl]
	cp RIVAL1
	jr z, .CheckSpecies_T4
	cp RIVAL2
	jr nz, .NotRival_T4
.CheckSpecies_T4:
	ld a, c ; Restore species to check
	cp CHIKORITA
	jr z, .DoSwap_T4
	cp BAYLEEF
	jr z, .DoSwap_T4
	cp MEGANIUM
	jr z, .DoSwap_T4
	cp CYNDAQUIL
	jr z, .DoSwap_T4
	cp QUILAVA
	jr z, .DoSwap_T4
	cp TYPHLOSION
	jr z, .DoSwap_T4
	cp TOTODILE
	jr z, .DoSwap_T4
	cp CROCONAW
	jr z, .DoSwap_T4
	cp FERALIGATR
	jr z, .DoSwap_T4
	jr .NotRival_T4 ; Not a starter, so don't swap
.DoSwap_T4:
	ld a, [wRivalStarterSpecies]
	and a
	jr z, .NotRival_T4
	ld c, a
	ld a, 1
	ld [wDidSwapRivalMon], a
	ld a, c
	pop hl
	jr .DoneSwap_T4
.NotRival_T4:
	ld a, c
	pop hl
.DoneSwap_T4:
; --- End In-line Swap Logic ---

	ld [wCurPartySpecies], a

	ld a, OTPARTYMON
	ld [wMonType], a

	push hl
	predef TryAddMonToParty
	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1Item
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl

	ld a, [hli]
	ld [de], a

	push hl
	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	pop hl

	ld a, [wDidSwapRivalMon]
	and a
	jp nz, .loop

	ld b, NUM_MOVES
.copy_moves
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy_moves

	push hl

	ld a, [wOTPartyCount]
	dec a
	ld hl, wOTPartyMon1
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, MON_PP
	add hl, de

	push hl
	ld hl, MON_MOVES
	add hl, de
	pop de

	ld b, NUM_MOVES
.copy_pp
	ld a, [hli]
	and a
	jr z, .copied_pp

	push hl
	push bc
	dec a
	ld hl, Moves + MOVE_PP
	ld bc, MOVE_LENGTH
	call AddNTimes
	ld a, BANK(Moves)
	call GetFarByte
	pop bc
	pop hl

	ld [de], a
	inc de
	dec b
	jr nz, .copy_pp
.copied_pp

	pop hl
	jp .loop

ComputeTrainerReward:
	ld hl, hProduct
	xor a
	ld [hli], a
	ld [hli], a ; hMultiplicand + 0
	ld [hli], a ; hMultiplicand + 1
	ld a, [wEnemyTrainerBaseReward]
	ld [hli], a ; hMultiplicand + 2
	ld a, [wCurPartyLevel]
	ld [hl], a ; hMultiplier
	call Multiply
	ld hl, wBattleReward
	xor a
	ld [hli], a
	ldh a, [hProduct + 2]
	ld [hli], a
	ldh a, [hProduct + 3]
	ld [hl], a
	ret

Battle_GetTrainerName::
	ld a, [wInBattleTowerBattle]
	bit IN_BATTLE_TOWER_BATTLE_F, a
	ld hl, wOTPlayerName
	jp nz, CopyTrainerName

	ld a, [wOtherTrainerID]
	ld b, a
	ld a, [wOtherTrainerClass]
	ld c, a

GetTrainerName::
	ld a, c
	cp CAL
	jr nz, .not_cal2

	ld a, BANK(sMysteryGiftTrainerHouseFlag)
	call OpenSRAM
	ld a, [sMysteryGiftTrainerHouseFlag]
	and a
	call CloseSRAM
	jr z, .not_cal2

	ld a, BANK(sMysteryGiftPartnerName)
	call OpenSRAM
	ld hl, sMysteryGiftPartnerName
	call CopyTrainerName
	jp CloseSRAM

.not_cal2
	dec c
	push bc
	ld b, 0
	ld hl, TrainerGroups
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop bc

.loop
	dec b
	jr z, CopyTrainerName

.skip
	ld a, [hli]
	cp $ff
	jr nz, .skip
	jr .loop

CopyTrainerName:
	ld de, wStringBuffer1
	push de
	ld bc, NAME_LENGTH
	call CopyBytes
	pop de
	ret

IncompleteCopyNameFunction: ; unreferenced
; Copy of CopyTrainerName but without "call CopyBytes"
	ld de, wStringBuffer1
	push de
	ld bc, NAME_LENGTH
	pop de
	ret

INCLUDE "data/trainers/parties.asm"
