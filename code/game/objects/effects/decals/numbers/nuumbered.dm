/**
 * Returns a subtype of /obj/effect/turf_decal/number according to the arguments num and shift_mode.
 *
 * num - must be an integer in [0, 9] and determines the number displayed by the returned decal type.
 * shift_mode - must be NONE, EAST, or WEST:
 * - If NONE is passed, the returned decal will be centered.
 * - If EAST is passed, the returned decal will be shifted to the right.
 * - If WEST is passed, the returned decal will be shifted to the left.
 */
/proc/get_number_decal(num, shift_mode)
	RETURN_TYPE(/obj/effect/turf_decal/number)
	switch(shift_mode)
		if(NONE)
			switch(num)
				if(1)
					return /obj/effect/turf_decal/number/one
				if(2)
					return /obj/effect/turf_decal/number/two
				if(3)
					return /obj/effect/turf_decal/number/three
				if(4)
					return /obj/effect/turf_decal/number/four
				if(5)
					return /obj/effect/turf_decal/number/five
				if(6)
					return /obj/effect/turf_decal/number/six
				if(7)
					return /obj/effect/turf_decal/number/seven
				if(8)
					return /obj/effect/turf_decal/number/eight
				if(9)
					return /obj/effect/turf_decal/number/nine
				if(0)
					return /obj/effect/turf_decal/number/zero
		if(EAST)
			switch(num)
				if(1)
					return /obj/effect/turf_decal/number/right_one
				if(2)
					return /obj/effect/turf_decal/number/right_two
				if(3)
					return /obj/effect/turf_decal/number/right_three
				if(4)
					return /obj/effect/turf_decal/number/right_four
				if(5)
					return /obj/effect/turf_decal/number/right_five
				if(6)
					return /obj/effect/turf_decal/number/right_six
				if(7)
					return /obj/effect/turf_decal/number/right_seven
				if(8)
					return /obj/effect/turf_decal/number/right_eight
				if(9)
					return /obj/effect/turf_decal/number/right_nine
				if(0)
					return /obj/effect/turf_decal/number/right_zero
		if(WEST)
			switch(num)
				if(1)
					return /obj/effect/turf_decal/number/left_one
				if(2)
					return /obj/effect/turf_decal/number/left_two
				if(3)
					return /obj/effect/turf_decal/number/left_three
				if(4)
					return /obj/effect/turf_decal/number/left_four
				if(5)
					return /obj/effect/turf_decal/number/left_five
				if(6)
					return /obj/effect/turf_decal/number/left_six
				if(7)
					return /obj/effect/turf_decal/number/left_seven
				if(8)
					return /obj/effect/turf_decal/number/left_eight
				if(9)
					return /obj/effect/turf_decal/number/left_nine
				if(0)
					return /obj/effect/turf_decal/number/left_zero



// centered number decals

/obj/effect/turf_decal/number/one
	icon_state = "1"

/obj/effect/turf_decal/number/two
	icon_state = "2"

/obj/effect/turf_decal/number/three
	icon_state = "3"

/obj/effect/turf_decal/number/four
	icon_state = "4"

/obj/effect/turf_decal/number/five
	icon_state = "5"

/obj/effect/turf_decal/number/six
	icon_state = "6"

/obj/effect/turf_decal/number/seven
	icon_state = "7"

/obj/effect/turf_decal/number/eight
	icon_state = "8"

/obj/effect/turf_decal/number/nine
	icon_state = "9"

/obj/effect/turf_decal/number/zero
	icon_state = "0"

// right-shifted number decals (1s digit)
/obj/effect/turf_decal/number/right_one
	icon_state = "-1"

/obj/effect/turf_decal/number/right_two
	icon_state = "-2"

/obj/effect/turf_decal/number/right_three
	icon_state = "-3"

/obj/effect/turf_decal/number/right_four
	icon_state = "-4"

/obj/effect/turf_decal/number/right_five
	icon_state = "-5"

/obj/effect/turf_decal/number/right_six
	icon_state = "-6"

/obj/effect/turf_decal/number/right_seven
	icon_state = "-7"

/obj/effect/turf_decal/number/right_eight
	icon_state = "-8"

/obj/effect/turf_decal/number/right_nine
	icon_state = "-9"

/obj/effect/turf_decal/number/right_zero
	icon_state = "-0"

// left-shifted number decals (10s digit)
/obj/effect/turf_decal/number/left_one
	icon_state = "1-"

/obj/effect/turf_decal/number/left_two
	icon_state = "2-"

/obj/effect/turf_decal/number/left_three
	icon_state = "3-"

/obj/effect/turf_decal/number/left_four
	icon_state = "4-"

/obj/effect/turf_decal/number/left_five
	icon_state = "5-"

/obj/effect/turf_decal/number/left_six
	icon_state = "6-"

/obj/effect/turf_decal/number/left_seven
	icon_state = "7-"

/obj/effect/turf_decal/number/left_eight
	icon_state = "8-"

/obj/effect/turf_decal/number/left_nine
	icon_state = "9-"

/obj/effect/turf_decal/number/left_zero
	icon_state = "0-"

/obj/effect/turf_decal/dash
	icon_state = "dash"
