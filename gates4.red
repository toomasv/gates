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
	boxing?: no
	s: found: point: circ: name: rate: style: con: ofs: none
	calc2: func [gate logic fn /x /local res out][
		either gate/extra/type = '_bulb [
			gate/draw/10/4: pick [0 254] logic fn collect [
				foreach input gate/extra/in [keep input/extra/true?]
			]
		][
			gate/draw/2: pick [white red] out: logic either x [
				res: 0
				foreach input gate/extra/in [res: res + make integer! input/extra/true?]
			][
				fn collect [foreach input gate/extra/in [keep input/extra/true?]]
			]
			unless find [_sum _cout] gate/extra/type [
				gate/extra/true?: out
			]
			out
		]
	]
	calculate: func [gate][
		switch gate/extra/type [
			_and [calc2 gate :to-logic :all]
			_or [calc2 gate :to-logic :any]
			_not [calc2 gate :not :any]
			_nand [calc2 gate :not :all]
			_nor [calc2 gate :not :any]
			_xor [calc2/x gate :odd? none]
			_xnor [calc2/x gate :even? none]
			_join [calc2 gate :to-logic :all]
			_bulb [calc2 gate :to-logic :all]
			_in-gate [
				switch gate/parent/extra/type [
					_full-adder [calc2 gate :to-logic :all]
					_adder-8 []
					_edge-DFF [calc2 gate :to-logic :all]
				]
			]
			_clock-gate [gate/extra/changed?: yes calc2 gate :to-logic :all]
		]
	] 
	calculate2: func [sum cout a b c][
		sum/draw/2: pick [white red] sum/extra/true?: a/true? xor b/true? xor c/true?
		;odd? sum reduce [
		;	make integer! a/true? make integer! b/true? make integer! c/true?
		;]
		cout/draw/2: pick [white red] cout/extra/true?: (a/true? and b/true?) or (c/true? and (a/true? xor b/true?))
	]
	calculate3: func [q ~q d clk][
		if clk/true? and clk/changed? [
			q/draw/2: pick [white red] q/extra/true?: d/extra/true?
			~q/draw/2: pick [white red] ~q/extra/true?: not d/extra/true?
			clk/changed?: no
			d/draw/2: pick [white red] d/extra/true?: not d/extra/true?
		]
	]
	ask-name: func [what] [
		name: either what = 'new [none][either object? what [what/text][form what]]
		view/flags compose [
			namef: field (any [name copy ""]) focus on-enter [name: face/text unview]
			return
			button "OK" [name: namef/text unview] 
			button "Cancel" [name: none unview]
		][modal popup]
		if object? what [what/text: name]
		name
	]
	expunge: func [face /from pane][pane: any [pane face/parent/pane] remove find pane face] 
	connector: [
		at 0x0 box (pan/size) draw [
			pen black spline (
				ofs: face/offset 
				ofs: switch/default face/extra/type [
					_sum _cout _out-gate [ofs + face/parent/offset + 5]
				][
					ofs + 12
				]
			) (ofs) 
		]
		with [
			extra: [type: 'connection from: (face) to: (none) true?: (yes)]
			menu: ["Delete" _delete "Add point" _add "Remove point" _remove]
		]
		on-menu [
			switch event/picked [
				_delete [
					expunge/from face face/extra/from/extra/out
					expunge/from face face/extra/to/extra/in
					expunge face
				]
				_add [
					found: next find/tail face/draw 'spline
					print [event/offset found/-1 found/1 within? event/offset found/-1 found/1 - found/-1]
					while [
						not within? event/offset 
							_min: min found/-1 found/1 
							(quote (max found/-1 found/1)) - _min
					][found: next found]
					insert found event/offset 
					append face/draw compose [circle (quote (event/offset)) 1]
					
				]
				_remove [
					found: skip find face/draw 'spline 2
					parse found [
						some [
							s: pair! if (quote (within? event/offset s/1 - 3 6x6)) [
								if (quote (s/-1 = 'circle)) (quote (remove/part back s 3)) 
							| 	(quote (remove s))
							]
						| 	skip
						]
					]
				]
			] 'done
		]
		on-down [
			point: circ: none
			parse face/draw [some [
				s: pair! if (quote (within? event/offset s/1 - 3 6x6)) [
					if (quote (s/-1 = 'circle)) (quote (circ: s))
				|	(quote (point: s))
				]
			| 	skip
			]]
			'done
		]
		all-over on-over [
			if all [event/down? point] [
				point/1: circ/1: event/offset
			]
			'done
		]
		react (copy/deep [
			face/extra/true?: face/extra/from/extra/true?
			face/draw/2: pick [green red] face/extra/true?
			unless none? face/extra/to [calculate face/extra/to]
		])
	]
	gate-create: [face/extra: make deep-reactor! [type: 'gate in: copy [] out: copy [] true?: yes]]
	
	extend system/view/VID/styles [
		gate: [
			template: [
				type: 'base 
				size: 25x25 
				color: glass 
				flags: 'all-over 
				actors: [
					on-create: func [face event] [
						face/extra: make deep-reactor! copy/deep [type: 'gate in: [] out: [] true?: yes]
					]
					on-down: func [face event] [
						either event/ctrl? [
							insert face/parent/pane layout/only compose/deep/only bind connector :on-down
							append face/extra/out face/parent/pane/1
						][
							either all [face/extra/type = '_var event/shift?] [
								face/extra/true?: not face/extra/true?
								face/draw/5: pick [green red] face/extra/true?
							][
								move find face/parent/pane face tail face/parent/pane 
								diff: event/offset
							]
						] 'done
					]
					on-over: func [face event] [ 
						unless boxing? [
							case [
								all [event/down? not event/ctrl?] [
									face/offset: round/to face/offset - diff + event/offset 5
									foreach edge face/extra/in [
										if found: either pair? last edge/draw [
											back tail edge/draw
										][
											back find edge/draw 'circle
										][
											found/1: face/offset + 12x12
										]
									]
									foreach edge face/extra/out [
										if found: find/tail edge/draw 'spline [
											found/1: face/offset + 12x12
										]
									]
								]
								all [event/down? event/ctrl?][
									pan/pane/1/draw/5: event/offset + event/face/offset
								]
							]
							if up? [
								pan/pane/1/draw/5: face/offset + 12x12
								pan/pane/1/extra/to: face 
								append face/extra/in pan/pane/1 
								calculate face
								up?: no
							] 
						] 'done 
					]
					on-up: func [face event] [if event/ctrl? [up?: yes]] 
					on-menu: func [face event] [
						switch event/picked [
							_true [face/extra/true?: yes face/draw/5: 'green]
							_false [face/extra/true?: no face/draw/5: 'red]
							_delete [
								foreach con face/extra/out [
									expunge/from con con/extra/to/extra/in
									expunge con
								]
								foreach con face/extra/in [
									expunge/from con con/extra/from/extra/out
									expunge con
								]
								expunge face
							]
							_n [face/draw/4: -90]
							_e [face/draw/4: 0]
							_s [face/draw/4: 90]
							_w [face/draw/4: 180]
							_stop [rate: face/rate face/rate: none]
							_go [face/rate: rate]
							_rate [face/rate: load ask-name face/rate]
							_show [probe body-of face/actors]
						] 'done
					]
					on-time: func [face event][face/extra/true?: not face/extra/true?]
				]
			]
		]
		in-gate: [
			template: [
				type: 'base
				size: 10x10
				color: glass
				flags: 'all-over
				draw: copy gates/_in-gate
				actors: [
					on-create: func [face event] [
						face/extra: make deep-reactor! [type: '_in-gate in: copy [] out: copy [] true?: yes]
					]
					on-over: func [face event][
						if up? [
							con: pan/pane/1
							con/draw/5: face/offset + face/parent/offset + 5x5
							con/extra/to: face 
							append face/extra/in con 
							calculate face
							up?: no
						] 'done
					]
				]
			]
		]
		clock-gate: [
			template: [
				type: 'base
				size: 10x10
				color: glass
				flags: 'all-over
				draw: copy gates/_clock-gate
				actors: [
					on-create: func [face event] [
						face/extra: make deep-reactor! [type: '_clock-gate in: copy [] out: copy [] true?: yes changed?: no]
					]
					on-over: func [face event][
						if up? [
							con: pan/pane/1
							con/draw/5: face/offset + face/parent/offset + 0x4
							con/extra/to: face 
							append face/extra/in con 
							calculate face
							up?: no
						] 'done
					]
				]
			]
		]
		out-gate: [
			template: [
				type: 'base
				size: 10x10
				color: glass
				flags: 'all-over
				draw: copy gates/_out-gate
				actors: [
					on-create: func [face event] [
						face/extra: make deep-reactor! [type: '_out-gate in: copy [] out: copy [] true?: yes]
					]
					on-down: func [face event][
						if event/ctrl? [
							insert pan/pane layout/only compose/deep/only bind connector :on-down
							append face/extra/out pan/pane/1
						]
						'done
					]
					on-over: func [face event][
						if all [event/down? event/ctrl?][
							pan/pane/1/draw/5: event/offset + event/face/offset + event/face/parent/offset
						]
					]
					on-up: func [face event] [if event/ctrl? [up?: yes]]
				]
			]
		]
		full-adder: [
			template: [
				type: 'base 
				size: 50x50 
				color: glass 
				flags: 'all-over 
				pane: copy []
				actors: [
					on-create: func [face event] [
						face/extra: copy/deep [type: '_full-adder in: [] out: []]
					]
					on-down: func [face event] [
						unless event/ctrl? [
							move find face/parent/pane face tail face/parent/pane 
							diff: event/offset
						] 'done
					]
					on-over: func [face event] [ 
						unless boxing? [
							if all [event/down? not event/ctrl?] [
								face/offset: round/to face/offset - diff + event/offset 5
								foreach-face face [
									switch face/extra/type [
										_gate-in [
											foreach edge face/extra/in [
												found: either pair? last edge/draw [
													back tail edge/draw
												][
													back find edge/draw 'circle
												]
												found/1: face/offset + face/parent/offset + 5
											]
										]
										_sum _cout [
											foreach edge face/extra/out [
												found: find/tail edge/draw 'spline
												found/1: face/offset + face/parent/offset + 5
											]
										]
									]
								]
							]
						] 'done 
					] 
					on-menu: func [face event] [
						switch event/picked [
							_delete [
								foreach con face/extra/out [
									expunge/from con con/extra/to/extra/in
									expunge con
								]
								foreach con face/extra/in [
									expunge/from con con/extra/from/extra/out
									expunge con
								]
								expunge face
							]
							_n [face/draw/4: -90]
							_e [face/draw/4: 0]
							_s [face/draw/4: 90]
							_w [face/draw/4: 180]
						] 'done
					]					
				]
			]
			init: [append face/pane layout/only [
				at 8x0 in-gate at 32x0 in-gate at 40x17 in-gate
				at 22x40 out-gate at 0x17 out-gate
			]]
		]
		adder8: [
			template: [
				type: 'base 
				size: 50x50 
				color: glass 
				flags: 'all-over 
				pane: copy []
				actors: [
					on-create: func [face event] [
						face/extra: copy/deep [type: '_adder8 in: [] out: []]
					]
					on-down: func [face event] [
						unless event/ctrl? [
							move find face/parent/pane face tail face/parent/pane 
							diff: event/offset
						] 'done
					]
					on-over: func [face event] [ 
						unless boxing? [
							if all [event/down? not event/ctrl?] [
								face/offset: round/to face/offset - diff + event/offset 5
								foreach-face face [
									switch face/extra/type [
										_gate-in [
											foreach edge face/extra/in [
												found: either pair? last edge/draw [
													back tail edge/draw
												][
													back find edge/draw 'circle
												]
												found/1: face/offset + face/parent/offset + 5
											]
										]
										_sum _cout [
											foreach edge face/extra/out [
												found: find/tail edge/draw 'spline
												found/1: face/offset + face/parent/offset + 5
											]
										]
									]
								]
							]
						] 'done 
					] 
					on-menu: func [face event] [
						switch event/picked [
							_delete [
								foreach con face/extra/out [
									expunge/from con con/extra/to/extra/in
									expunge con
								]
								foreach con face/extra/in [
									expunge/from con con/extra/from/extra/out
									expunge con
								]
								expunge face
							]
							_n [face/draw/4: -90]
							_e [face/draw/4: 0]
							_s [face/draw/4: 90]
							_w [face/draw/4: 180]
						] 'done
					]					
				]
			]
			init: [append face/pane layout/only [
				at 8x0 in-gate at 32x0 in-gate at 40x17 in-gate
				at 22x40 out-gate at 0x17 out-gate
			]]
		]
		edge-DFF: [
			template: [
				type: 'base 
				size: 50x50 
				color: glass 
				flags: 'all-over 
				pane: copy []
				actors: [
					on-create: func [face event] [
						face/extra: copy/deep [type: '_edge-DFF in: [] out: []]
					]
					on-down: func [face event] [
						unless event/ctrl? [
							move find face/parent/pane face tail face/parent/pane 
							diff: event/offset
						] 'done
					]
					on-over: func [face event] [ 
						unless boxing? [
							if all [event/down? not event/ctrl?] [
								face/offset: round/to face/offset - diff + event/offset 5
								foreach-face face [
									switch face/extra/type [
										_in-gate [
											foreach edge face/extra/in [
												found: either pair? last edge/draw [
													back tail edge/draw
												][
													back find edge/draw 'circle
												]
												found/1: face/offset + face/parent/offset + 5
											]
										]
										_clock-gate [
											foreach edge face/extra/in [
												found: either pair? last edge/draw [
													back tail edge/draw
												][
													back find edge/draw 'triangle
												]
												found/1: face/offset + face/parent/offset + 0x4
											]
										]
										_out-gate [
											foreach edge face/extra/out [
												found: find/tail edge/draw 'spline
												found/1: face/offset + face/parent/offset + 5
											]
										]
									]
								]
							]
						] 'done 
					] 
					on-menu: func [face event] [
						switch event/picked [
							_delete [
								foreach con face/extra/out [
									expunge/from con con/extra/to/extra/in
									expunge con
								]
								foreach con face/extra/in [
									expunge/from con con/extra/from/extra/out
									expunge con
								]
								expunge face
							]
							_n [face/draw/4: -90]
							_e [face/draw/4: 0]
							_s [face/draw/4: 90]
							_w [face/draw/4: 180]
						] 'done
					]					
				]
			]
			init: [append face/pane layout/only [
				at 0x8 in-gate at 2x32 clock-gate 
				at 40x8 out-gate at 40x32 out-gate
			]]
		]
	]
	gates: [
		_var: [circle 12x12 10 fill-pen green circle 12x12 7]
		_and: [fill-pen white rotate 0 12x12 shape [
			move 0x2 line 10x2 arc 10x22 10 10 180 sweep line 0x22]
		]
		_or: [fill-pen white rotate 0 12x12 shape [
			move 0x2 arc 20x12 20 20 45 sweep arc 0x22 20 20 45 sweep arc 0x2 20 20 60]
		]
		_not: [fill-pen white rotate 0 12x12 pen gray triangle 6x6 18x12 6x18 circle 19x12 2]
		_nand: [fill-pen white rotate 0 12x12 shape [
			move 0x2 line 10x2 arc 20x12 10 10 90 sweep arc 20x13 2 2 360 sweep large arc 10x22 10 10 90 sweep line 0x22]
		]
		_nor: [fill-pen white rotate 0 12x12 shape [
			move 0x2 arc 20x12 20 20 45 sweep arc 20x13 2 2 360 sweep large arc 0x22 20 20 45 sweep arc 0x2 20 20 60]
		]
		_xor: [fill-pen white rotate 0 12x12 shape [
			move 0x2 arc 20x12 20 20 45 sweep arc 0x22 20 20 45 sweep arc 0x2 20 20 60	move 2x0 arc 2x24 22 22 60 sweep move 0x2]
		]
		_xnor: [fill-pen white rotate 0 12x12 shape [
			move 0x2 arc 20x12 20 20 45 sweep arc 20x13 2 2 360 sweep large arc 0x22 20 20 45 sweep arc 0x2 20 20 60 move 2x0 arc 2x24 22 22 60 sweep move 0x2]
		]
		_join: [fill-pen white rotate 0 12x12 pen gray circle 12x12 3]
		_bulb: [fill-pen white rotate 0 12x12 pen silver fill-pen radial 255.255.0.254 255.255.0.254 12x12 10 circle 12x12 10]
		_clock: [fill-pen snow rotate 0 12x12 circle 12x12 10 line 6x8 6x16 12x16 12x8 18x8 18x16]
		_full-adder: [fill-pen white rotate 0 25x25 box 5x5 45x45]
		_in-gate: [fill-pen white circle 5x5 4]
		_out-gate: [fill-pen white circle 5x5 4]
		_clock-gate: [fill-pen white triangle 0x0 8x4 0x8]
		_adder8: [fill-pen white rotate 0 25x25 box 5x5 45x45]
		_edge-DFF: [fill-pen white rotate 0 25x25 box 5x5 45x45]
		;_HA: [fill-pen white box 0x2 20x22 text 0x0 "HF" fill-pen white shape [move 20x3 arc 20x11 4 4 0 sweep large] fill-pen white shape [move 20x13 arc 20x21 4 4 0 sweep large ]]
		;_FA: []
	]
	;###############
	; Control-panel
	;###############
	set-bits: does [forall bits [bpan/pane/(index? bits)/data: make logic! to-integer to-string bits/1]]
	set-num: function [hx][
		int: to-integer hx 
		num/data: either all [sig/data int > 127] [
			int - 256 									; -1 - to-integer (complement hx)
		][int]
	]
	hexa: charset [#"0" - #"9" #"A" - #"F"]
	bit: bpan: num: bin: bits: hex: bi: sig: none
	hx: #{00000000}
	ctrl: [
		panel loose [
			style bit: check 22x25 [
				hx: debase/base bin/text: rejoin collect [
					foreach-face bpan [
						keep make integer! face/data
					]
				] 2 
				hex/text: enbase/base hx 16
				set-num hx
			] 
			sig: check "Sig" 40 [set-num hx]
			bpan: panel [
				origin 0x0 
				bit "7" bit "6" bit "5" bit "4" bit "3" bit "2" bit "1" bit "0"
			] return 
			text "DEC:" 24 
			num: field 35 "0" on-enter [
				either all [face/data >= -128 face/data <= 255] [
					data: case [
						face/data < 0   [sig/data: true face/data + 256]
						face/data > 127 [sig/data: false face/data]
						true 			[face/data]
					]
					bin/text: bits: take/last/part enbase/base hx: to-binary data 2 8 
					hex/text: take/last/part enbase/base hx 16 2 
					set-bits
				][cause-error 'user 'message reduce [rejoin ["Enter integer " -128 ".." 255]]]
			]
			text "BIN:" 22 
			bin: field 70 "00000000" on-enter [
				either parse face/text [8 [#"1" | #"0"]] [
					bits: face/text 
					hex/text: enbase/base hx: debase/base bits 2 16 
					data: to-integer hx 
					set-num hx
					set-bits
				][cause-error 'user 'message ["Enter 8 bits (1 or 0)"]]
			]
			text "HEX:" 24 
			hex: field 25 "00" on-enter [
				either parse face/text [2 hexa] [
					hx: debase/base face/text 16 
					bin/text: bits: enbase/base hx 2 
					set-num hx
					set-bits
				][cause-error 'user 'message ["Enter hexadecimal 00..FF"]]
			]
		]
		with [
			size: size + 0x5
			draw: compose [box 0x0 (size - 1x6)]
			append pane layout/only compose [at (size / 2x1 - 0x11) out-gate]
		]
		on-drag [
			;face/offset: round/to face/offset - diff + event/offset 5
			foreach edge face/pane/9/extra/out [
				found: find/tail edge/draw 'spline
				print [face/offset face/parent/offset face/offset + face/parent/offset + 5]
				found/1: face/offset + face/pane/9/offset + 5
			]
		]
	]
	;##############
	; Panel-actors
	;##############
	pan-actors: [
		current: box: none 
		on-down: func [face event][
			boxing?: yes
			append face/pane current: first layout/only compose/deep [
				at (pos - 2) box 3x3 loose with [
					extra: #(diff: 0x0 off: 0x0)
					menu: ["Delete" _delete]
				]
					draw [box 2x2 2x2 pen 200.0.0.100 line-width 5 box 2x2 2x2] 
					on-down [face/extra/off: face/offset 'done] 
					on-over ['done]
					on-drag [
						box: face
						box/extra/diff: box/offset - box/extra/off box/extra/off: box/offset
						foreach-face/with pan [
							face/offset: face/offset + box/extra/diff
							foreach edge face/extra/in [edge/draw/5: face/offset + 12x12]
							foreach edge face/extra/out [edge/draw/4: face/offset + 12x12]
						][all [overlap? face box face/extra/type = 'gate]]
					]
					on-menu [expunge face]
			] 'done
		]
		on-over: func [face event][
			if all [event/down? not up? face = event/face] [
				current/size: (current/draw/3: current/draw/10: event/offset - current/offset) + 10
			]
			pos: event/offset
			'done
		]
		on-up: func [face event][current: none boxing?: no]
		on-menu: func [face event /local new][
			switch/default event/picked [
				_name [ask-name 'new if name [
					test/text: name
					append face/pane layout/only compose [
						at (pos) text (size-text test) (name) loose 
						on-drag [face/offset: round/to face/offset 5 'done]
						on-down ['done]
						with [menu: ["Edit" _edit "Delete" _del]]
						on-menu [switch event/picked [
							_edit [attempt [ask-name face]] ;Error -- Invalid syntax at: [_edit] ???
							_del [remove find face/parent/pane face]
						]]
					]
				]]
			][
				switch/default event/picked [
					_ctrl [
						system/view/auto-sync?: off
						new: last append face/pane layout/only copy/deep ctrl
						new/offset: event/offset
						show face
						system/view/auto-sync?: on
					]
				][
					gate-shape: copy gates/(event/picked)
					new: last append face/pane layout/only switch/default event/picked [
						_full-adder _adder8 _edge-DFF [
							big-gate: to-word next to-string event/picked
							compose/only [at (round/to pos 5) (big-gate) draw (gate-shape)]
						]
					][
						compose/only [at (round/to pos 5) gate draw (gate-shape)]
					]
					new/menu: switch/default event/picked [
						_var [["True" _true "False" _false "Delete" _delete]]
						_clock [["Stop" _stop "Go" _go "Rate" _rate "Delete" _delete ]]
					][
						["Delete" _delete "Turn" ["N" _n "E" _e "S" _s "W" _w] "Show" _show] 
					]
					new/extra/type: event/picked
					switch event/picked [
						_clock [new/rate: 1]
						_full-adder [
							new/pane/4/extra/type: '_sum
							repend new/pane/4/extra/in [new/pane/1 new/pane/2 new/pane/3]
							new/pane/5/extra/type: '_cout
							repend new/pane/5/extra/in [new/pane/1 new/pane/2 new/pane/3]
							repend new/pane/1/extra/out [new/pane/4 new/pane/5]
							repend new/pane/2/extra/out [new/pane/4 new/pane/5]
							repend new/pane/3/extra/out [new/pane/4 new/pane/5]
							react/link :calculate2 [new/pane/4 new/pane/5 new/pane/1/extra new/pane/2/extra new/pane/3/extra]
						]
						_edge-DFF [
							repend new/pane/3/extra/in [new/pane/1 new/pane/2]
							repend new/pane/1/extra/out [new/pane/3]
							repend new/pane/2/extra/out [new/pane/3]
							react/link :calculate3 [new/pane/3 new/pane/4 new/pane/1 new/pane/2/extra]
						]
					]
				]
			]
		]
	]
	lay: layout/flags/options [
		size 500x300
		at 0x0 test: text hidden 200 ""
		pan: panel 500x300 [] all-over with [
			menu: [
				;"Insert" [
					"var" _var "and" _and "or" _or "not" _not "nand" _nand 
					"nor" _nor "xor" _xor "xnor" _xnor "join" _join ;"inv" _inv
					"name" _name "bulb" _bulb "clock" _clock
					"full-adder" _full-adder "8-bit adder" _adder8 "edge-DFF" _edge-DFF "panel" _ctrl
				]
			;]; "HA" _HA]]
			actors: object pan-actors
		]
	][resize][
		menu: ["File" ["New" new "Probe" probe "Open.." open "Save" save "Save as.." save-as]]
		actors: object [
			on-resizing: func [face event][
				pan/size: face/size 
				foreach-face/with pan [face/extra face/size: pan/size][face/extra/type = 'connection]
			]
			on-menu: func [face event][
				switch event/picked [
					new []
					probe [probe pan]
					open [if file: request-file [append pan/pane: reduce bind load file ctx]]
					save [if file: request-file/save [save file pan/pane]]
					save-as [if file: request-file/save [save file pan/pane]]
				]
			]
		]
	]
	view lay
]