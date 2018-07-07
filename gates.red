Red [
	Author: "Toomas Vooglaid"
	First-version: 2018-07-06
	Last-edit: 2018-07-07
	Licence: "Free usage"
	Purpose: "Studying logic circuits"
	Needs: View
	File: %gates.red
]
clear-reactions
ctx: context [
	diff: 0x0
	up?: no
	pos: 0x0
	con: none
	calc2: func [gate logic fn /x /local res][
		gate/draw/2: pick [white red] gate/extra/true?: logic either x [
			res: 0
			foreach input gate/extra/in [res: res + make integer! input/extra/true?]
		][
			fn collect [foreach input gate/extra/in [keep input/extra/true?]]
		]
	]
	calculate: func [gate][
		switch gate/options/style [
			_and [calc2 gate :to-logic :all]
			_or [calc2 gate :to-logic :any]
			_not [calc2 gate :not :any]
			_nand [calc2 gate :not :all]
			_nor [calc2 gate :not :any]
			_xor [calc2/x gate :odd? none]
			_xnor [calc2/x gate :even? none]
		]
	] 
	gate-style: [
		type: 'base 
		size: 25x25 
		color: glass 
		flags: 'all-over 
		actors: [
			on-create: func [face event][
				face/extra: make deep-reactor! [type: 'gate in: copy [] out: copy [] true?: yes]
				face/menu: either face/options/style = '_var [
					["True" _true "False" _false "Delete" _delete] 
				][
					["Delete" _delete] 
				]
			] 
			on-down: func [face event][
				either event/ctrl? [ 
					insert face/parent/pane layout/only compose/deep/only [
						at 0x0 box (face/parent/size) draw [pen black line (face/offset + 12x12) (face/offset + 12x12)] 
						with [
							extra: compose [type: 'connection from: (face) to: (none) true?: (yes)]
							menu: ["Delete" _delete]
						] 
						on-menu [switch event/picked [_delete [
							remove find face/extra/from/extra/out face
							remove find face/extra/to/extra/in face
							remove find face/parent/pane face
						]] 'done] 
						react (copy/deep [
							face/extra/true?: face/extra/from/extra/true?
							face/draw/2: either face/extra/true? ['green]['red]
							unless none? face/extra/to [calculate face/extra/to]
						])
					]
					append face/extra/out face/parent/pane/1
				][
					move find face/parent/pane face tail face/parent/pane 
					diff: event/offset
				]
			] 
			on-over: func [face event][ 
				if all [event/down? not event/ctrl?] [
					face/offset: face/offset - diff + event/offset
					foreach edge face/extra/in [edge/draw/5: face/offset + 12x12]
					foreach edge face/extra/out [edge/draw/4: face/offset + 12x12]
				]
				if up? [
					face/parent/pane/1/draw/5: face/offset + 12x12
					face/parent/pane/1/extra/to: face 
					append face/extra/in face/parent/pane/1 
					calculate face
					up?: no
				]
			] 
			on-up: func [face event][if event/ctrl? [up?: yes]] 
			on-menu: func [face event][
				switch event/picked [
					_true [face/extra/true?: yes face/draw/5: 'green]
					_false [face/extra/true?: no face/draw/5: 'red]
					_delete [
						foreach con face/extra/out [
							remove find con/extra/to/extra/in con 
							remove find con/parent/pane con
						]
						foreach con face/extra/in [
							remove find con/extra/from/extra/out con 
							remove find con/parent/pane con
						]
						remove find face/parent/pane face
					]
				] 'done
			]
		] 
	]
	gates: [
		_var: [circle 12x12 10 fill-pen green circle 12x12 7]
		_and: [fill-pen white shape [move 0x2 line 10x2 arc 10x22 10 10 180 sweep line 0x22]]
		_or: [fill-pen white shape [move 0x2 arc 20x12 20 20 45 sweep arc 0x22 20 20 45 sweep arc 0x2 20 20 60]]
		_not: [fill-pen white shape [move 0x2 line 20x12 arc 20x13 2 2 360 sweep large line 0x22]]
		_nand: [fill-pen white shape [move 0x2 line 10x2 arc 20x12 10 10 90 sweep arc 20x13 2 2 360 sweep large arc 10x22 10 10 90 sweep line 0x22]]
		_nor: [fill-pen white shape [move 0x2 arc 20x12 20 20 45 sweep arc 20x13 2 2 360 sweep large arc 0x22 20 20 45 sweep arc 0x2 20 20 60]]
		_xor: [fill-pen white shape [move 0x2 arc 20x12 20 20 45 sweep arc 0x22 20 20 45 sweep arc 0x2 20 20 60	move 2x0 arc 2x24 22 22 60 sweep move 0x2]]
		_xnor: [fill-pen white shape [move 0x2 arc 20x12 20 20 45 sweep arc 20x13 2 2 360 sweep large arc 0x22 20 20 45 sweep arc 0x2 20 20 60 move 2x0 arc 2x24 22 22 60 sweep move 0x2]]
	]
	extend system/view/VID/styles compose/deep collect [
		foreach [gate shape] gates [keep compose/deep/only [(gate) [template: [(to-paren [copy/deep gate-style]) draw: (shape)]]]]
	]
	win: view/flags/options/no-wait [
		size 500x300
		pan: panel 500x300 [] all-over with [
			menu: ["Insert" ["var" _var "and" _and "or" _or "not" _not "nand" _nand "nor" _nor "xor" _xor "xnor" _xnor]]
		]
		on-over [
			if all [event/down? and event/ctrl?][face/pane/1/draw/5: event/offset + event/face/offset]
			pos: event/offset
		]
		on-menu [append face/pane layout/only reduce ['at pos event/picked]]
	][resize][actors: object [on-resizing: func [face event][
		pan/size: face/size 
		foreach-face/with pan [face/extra face/size: pan/size][face/extra/type = 'connection]
	]]]
]
