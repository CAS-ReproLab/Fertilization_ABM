;; V5_Updates to include removal of defined motility 'types'. Instead, only one initial population and individuals are defined by a 'predictor' variable that determines the Markov Transition probabilities for motility state.
;; Used in Figure 6 to explore the 'causes' of selection.


;;;;;;;;;;;;;;;;;;;;;;
;;Turtle Breeds;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;
breed[sperms sperm]
breed [eggs egg]

;;;;;;;;;;;;;;;;;;;;;;
;; global variables ;;
;;;;;;;;;;;;;;;;;;;;;;
globals [time len RMSD patch-data]

;;;;;;;;;;;;;;;;;;;;;;
;; turtle variables ;;
;;;;;;;;;;;;;;;;;;;;;;
turtles-own
[
  motility_state
  step_len
  path_len ; Accumulates the total distance travelled by each sperm
  VSL
  VCL
  VAP
  ALH
  init_x
  init_y
  current_x
  current_y
  previous_x
  previous_y
  last_heading
  sq_dsp ; Stores the squared displacement of the turtles
  intra_Ca ; Represents intracellular Ca2+ concentration; Acts as a predictor of motility state by modifying the state transition probabilities; 0.0-1.0 max; Increased intra_Ca causes transition to hyperactive state.
  freq
  egg_contact_time
]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup the simulation ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup

  clear-all

  load-patch-data ;; loads patch data from a file in the model directory called 'File IO Patch Data'
  show-patch-data
  set-patch-size 10

  create-sperms num_turtles

  ;; Create an egg turtle, though it is non-functional and only serves to cover the egg patch as a circle (for visual appeal)
  create-eggs 1[
    set color gray
    set shape "circle"
    set size 3
    setxy xcor 8
    setxy ycor -13
  ]

  ;; Create the egg patch that the sperm can interact with to record the contacts. It sits directly underneath the egg turtle
  ask patches with [pxcor = 8 and pycor = -13]
  [set pcolor gray]

  ask sperms [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"] ; Choose starting state at random
    set motility_state "progressive" ; Can set motility_state to specified value if desired
    ;set color blue
    set shape "circle"
    set size 0.3
    set color white
    ifelse rand_coordinate = True [ setxy -16 + (random-float 32) -16 + (random-float 32)] ; Can choose starting spatial distribution of sperm within the grid space using the GUI button
    [setxy -16 + (random-float 6) -16 + (random-float 32)] ; Can choose starting spatial distribution of sperm within the defined grid space
    ;[setxy input_xcor input_ycor]  ; Allows input a point starting position from GUI.
    set init_x xcor
    set init_y ycor
    set path_len 0
    set last_heading heading
    set ALH 0
    ;set freq precision (random-normal 3 1) 1 ; These options allow the user to define the statistical distribution from which the freq variable is drawn. Precision allows for limiting the float precision to have fewer bins.
    ;set freq precision (1 + random-float 100) 1 ; Draws from a uniform distribution between 1 and N + 1
    ;set freq precision (random-gamma 1 .5) 1
    ;set freq precision (random-exponential 3) 1
    ;set freq int random-exponential 3 ; int changes the random number to an integer rather than a float.
    set freq precision (random-poisson 3) 1
    set egg_contact_time 0 ; initialize the sperm contact time with the egg at 0.
  ]

  set len 40 ; initialize the length variable
  ;; Sets the length scaling factor-
  ;; each patch has a side length (len) of len in um.
  ;; Everything is scaled to the size of a patch.
  ;; If we change the number of patches, then we change the scaling factor,
  ;; and would need to adjust all other len dependent variables accordingly.
  ;; Example: at len 10 a step_len of 1 is 10 um. At len 20 a step_len of 0.5 is 10 um. At len 40 step_len = .25 is 10 um
  ;; Note: based on starting patch size of 10 pixels. For example, the turtle size is 0.3, parameterized to a pronucleus length of ~ 3um, which is approximately the size of a
  ;; mouse sperm pronucleus.

  set time 0 ; initialize the time variable

  ;; The following lines facilitate creating/writing individual sperm data to a csv file.Uncomment in setup and go loops
  ;; Make sure headings in setup match the variables identified in the function definition

  if record = True [
  let random-extension random 100
  let filename (word "sim_data_" random-extension ".csv")
  file-open filename ; Name of .csv file, will write to current model directory
  file-write "tick, turtle_id, motility_state, xcor, ycor, step_len, path_len, VSL, VCL, VAP, ALH, intra_Ca, freq"  ; Headers for CSV file
  file-print ""  ; Newline
  ]

 reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;
;; recursive model ;;
;;;;;;;;;;;;;;;;;;;;;

to go
  if not any? patches with [pcolor = black] [clear-drawing close-file stop]
  if not any? turtles with [motility_state = "progressive"] [clear-drawing close-file stop]
  set time time + (1 / 25.4) ;; (seconds) Assuming the sperm cross the central path at a frequency of 25.4 Hz, each tick is then 1/25.4 seconds.
  ask sperms [
    ifelse draw = True [pen-down] [pen-up]
    ;if pcolor = 9.9999 [set color black] ; what is this for?
    set intra_Ca (sin (freq * time)) ^ 2
  ]
    markov_move
    state_transition
    update_RMSD
  ;export-view (word ticks ".png") ;; Exports ticks as images for making a Gif saves to directory where the model is loaded from. Uncomment to run..
  ;export-interface (word "interface_" ticks ".png") ; Can be used to save the whole interface as a .png. This can then be cropped to make a gif of specific plots if desired.

  if record = True [
  write-turtle-data ; Uncomment to write turtle data to a .csv for conversion to a data frame
  ]
    tick
end

;;;;;;;;;;;;;;;;
;; Procedures ;;
;;;;;;;;;;;;;;;;

;; Movement Functions ;;

to progressive-motility

  set current_x xcor ; Set current position
  set current_y ycor

  ifelse ticks mod 2 = 0 [rt 15 + (random (90 - 15))] [rt -15 + (random (-90 + 15))]
  set step_len 0.25 + (random-float (0.30 - 0.25))
   set path_len path_len + step_len
  ifelse [pcolor] of patch-ahead step_len = 9.9999 [set heading ( heading - 180) fd 0.01]
  [fd step_len]

  update_sq_dsp ; squared displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
  update_egg_contact_time ; time spent in contact with the egg.

end

to intermediate-motility
  set current_x xcor
  set current_y ycor
  ;set intermediate_angle 85 + (random (200 - 85))
  ifelse ticks mod 2 = 0 [rt 100 + (random (140 - 100))] [rt -100 + (random (-140 + 100))]
  set step_len 0.4 + (random-float (0.425 - 0.4))
    set path_len path_len + step_len
  ifelse [pcolor] of patch-ahead step_len = 9.9999 [set heading ( heading - 180) fd 0.01]
  [fd step_len]
  update_sq_dsp ; squared displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
  update_egg_contact_time ; time spent in contact with the egg.
end

to hyperactive-motility
  set current_x xcor
  set current_y ycor
  ifelse random-float 1.00 < 0.6 [rt 90 + (random (180 - 90))] [lt -90 + (random (-180 + 90))]
  set step_len 0.35 + (random-float (0.45 - 0.35))
    set path_len path_len + step_len
  ifelse [pcolor] of patch-ahead step_len = 9.9999 [set heading ( heading - 180) fd 0.01]
  [fd step_len]

  update_sq_dsp ; squared displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
  update_egg_contact_time ; time spent in contact with the egg.
end

to slow-motility
  set current_x xcor
  set current_y ycor
  ifelse ticks mod 2 = 0 [rt 90 + (random (240 - 90))] [rt -90 + (random (-240 + 90))]
  set step_len 0.1 + (random-float (0.2 - 0.1))
    set path_len path_len + step_len
  ifelse [pcolor] of patch-ahead step_len = 9.9999 [set heading ( heading - 180) fd 0.01]
  [fd step_len]

  update_sq_dsp ; squared displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
  update_egg_contact_time ; time spent in contact with the egg.
end

to weak-motility
  set current_x xcor
  set current_y ycor
  ifelse ticks mod 2 = 0 [rt 90 + (random (270 - 90))] [rt -90 + (random (-270 + 90))]
  set step_len 0.075 + (random-float (0.125 - 0.075))
    set path_len path_len + step_len
  ifelse [pcolor] of patch-ahead step_len = 9.9999 [set heading ( heading - 180) fd 0.01]
  [fd step_len]

  update_sq_dsp ; squared displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
  update_egg_contact_time ; time spent in contact with the egg.
end

;; Markov Models For Subpopulations ;;
to state_transition
ask sperms
  [
  let rand_num (random-float 1.00 * intra_Ca) ; Need to adjust to the Markove table in the Python file!!
     if motility_state = "progressive" [if rand_num < 0.99 [set motility_state "progressive"]]
      if rand_num >= 0.99 and rand_num < 1.00 [set motility_state "intermediate" ]


     if motility_state = "intermediate" [if rand_num < 0.97 [set motility_state "intermediate" ]]
      if rand_num >= 0.97 and rand_num < 0.99 [set motility_state "progressive" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "hyperactive" ]


     if motility_state = "hyperactive" [if rand_num < 0.96 [set motility_state "hyperactive" ]]
      if rand_num >= 0.96 and rand_num < 0.98 [set motility_state "intermediate" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "slow" ]


     if motility_state = "slow" [if rand_num < 0.97 [set motility_state "slow" ]]
      if rand_num >= 0.97 and rand_num < 0.99 [set motility_state "hyperactive" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "weak" [if rand_num <= 1.00 [set motility_state "weak" ]]

  ]
end

;; Function call for markov movement ;;

to markov_move
  ask sperms [
  set color scale-color orange VCL 150 450
  if motility_state = "progressive"
  [
      progressive-motility
      ;set color blue
    ]
  if motility_state = "intermediate"
  [
     intermediate-motility
      ;set color green
  ]
  if motility_state = "hyperactive"
  [
      hyperactive-motility
      ;set color yellow
    ]
  if motility_state = "slow"
  [
      slow-motility
      ;set color orange
    ]
  if motility_state = "weak"
    [
     weak-motility
     ;set color red
    ]
  search_space ; Changes color of curent patch to keep track of space that has been searched
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Additional function calls ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to search_space
  if pcolor != 9.9999 and pcolor != gray [set pcolor 0.1]
end

to update_sq_dsp
  let x_component (current_x - init_x) * len
  let y_component (current_y - init_y) * len
  set sq_dsp ((x_component) ^ 2) + ((y_component) ^ 2)
end

to update_RMSD
  set RMSD (sum [sqrt (sq_dsp) ] of turtles) / (count turtles)
end

to update_VSL
  ; Calculate VSL: Straight-line distance from start to current position divided by time
  if time != 0 [
  let displacement sqrt ((current_x - init_x) ^ 2 + (current_y - init_y) ^ 2)
  set VSL (displacement / time) * len]
end

to update_VCL
   ; Calculate VCL: Total path length divided by time
  if time != 0 [
  set VCL (path_len / time) * len]
end

to update_VAP
  ; Calculate VAP: Average of VSL and VCL
  set VAP (VSL + VCL) / 2
end

to update_ALH
  ; Calculate ALH: Perpendicular distance from the current position to the VAP line (initial to current)
  let A (current_y - init_y) * len
  let B (init_x - current_x) * len
  let C (current_x * init_y - init_x * current_y) * len
  let denominator (sqrt (A ^ 2 + B ^ 2))
  if denominator != 0 [
  let dist (abs (A * xcor + B * ycor + C)) / (sqrt (A ^ 2 + B ^ 2))
  set ALH (ALH * time + dist) / (time + (1 / 25.5))] ; Averaging the ALH over time
end

to update_egg_contact_time
  if pcolor = gray [set egg_contact_time egg_contact_time + 1 / 25]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This procedure loads in patch data from a file.  The format of the file is: pxcor
; pycor pcolor.  You can view the file by opening the file File IO Patch Data.txt
; using a simple text editor.  Note that it automatically loads the file "File IO
; Patch Data.txt". To have the user choose their own file, see load-own-patch-data.
to load-patch-data

  ; We check to make sure the file exists first
  ifelse ( file-exists? "File IO Patch Data.txt" )
  [
    ; We are saving the data into a list, so it only needs to be loaded once.
    set patch-data []

    ; This opens the file, so we can use it.
    file-open "File IO Patch Data.txt"

    ; Read in all the data in the file
    while [ not file-at-end? ]
    [
      ; file-read gives you variables.  In this case numbers.
      ; We store them in a double list (ex [[1 1 9.9999] [1 2 9.9999] ...
      ; Each iteration we append the next three-tuple to the current list
      set patch-data sentence patch-data (list (list file-read file-read file-read))
    ]

    ;user-message "File loading complete!"

    ; Done reading in patch information.  Close the file.
    file-close
  ]
  [ user-message "There is no File IO Patch Data.txt file in current directory!" ]
end

; This procedure will use the loaded in patch data to color the patches.
; The list is a list of three-tuples where the first item is the pxcor, the
; second is the pycor, and the third is pcolor. Ex. [ [ 0 0 5 ] [ 1 34 26 ] ... ]
to show-patch-data
  ;clear-patches
  ;clear-turtles
  ifelse ( is-list? patch-data )
    [ foreach patch-data [ three-tuple -> ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ] ] ]
    [ user-message "You need to load in patch data first!" ]
  display
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This procedure writes individual sperm agent variable values out to a .csv file for import to a dataframe if desired

to write-turtle-data
  ask turtles [
    let data (word ticks "," who ", \"" motility_state "\"," xcor "," ycor "," step_len "," path_len "," VSL "," VCL "," VAP "," ALH "," intra_Ca "," freq) ; list the variables, must match the column headings determined in setup
    file-print data
  ]
end

to close-file
  file-close
end

;; Code below this point on Github is automatically deposited and is related to the configuration of buttons and defaults in the Netlogo environment.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
568
369
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
27
32
82
65
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
138
83
193
116
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
17
82
128
115
draw
draw
1
1
-1000

PLOT
680
10
880
160
Search Progress (% Complete)
Time (AU)
Search Progress
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ((count patches with [pcolor = 0.1]) / (count patches)) * 100"

PLOT
681
163
881
313
Time (secs)
Ticks
Time (secs)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot time"

PLOT
682
326
882
476
VSL (All)
VSL (um/sec)
Count (Agents)
0.0
10.0
0.0
1.0
true
false
"set-plot-x-range 0 300\nset-plot-y-range 0 10 ;(num_sperm_As + num_sperm_Bs)\nset-histogram-num-bars (count turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [VSL] of turtles "

PLOT
902
10
1102
160
Motility_State
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Progressive" 1.0 0 -13345367 true "" "plot count turtles with [motility_state = \"progressive\"]  "
"Intermediate" 1.0 0 -10899396 true "" "plot count turtles with [motility_state = \"intermediate\"]"
"Hyperactive" 1.0 0 -5825686 true "" "plot count turtles with [motility_state = \"hyperactive\"]"
"Slow" 1.0 0 -955883 true "" "plot count turtles with [motility_state = \"slow\"]"
"weak" 1.0 0 -2674135 true "" "plot count turtles with [motility_state = \"weak\"]"

PLOT
901
166
1101
316
VCL (All)
VCL (um/s)
Count Agents
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 500\nset-plot-y-range 0 10 ;(num_sperm_As + num_sperm_Bs)\nset-histogram-num-bars (count turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [VCL] of turtles"

PLOT
903
329
1103
479
VAP (All)
VAP(um/s)
COunt Agents
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 300\nset-plot-y-range 0 10 ;(num_sperm_As + num_sperm_Bs)\nset-histogram-num-bars (count turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [VAP] of turtles"

INPUTBOX
21
217
176
277
input_xcor
0.0
1
0
Number

INPUTBOX
21
285
176
345
input_ycor
0.0
1
0
Number

BUTTON
119
34
193
67
go (50)
ifelse ticks < 50 [go] [close-file]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1114
167
1314
317
RMSD
Ticks
RMSD (um)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot RMSD"

PLOT
1119
332
1319
482
ALH (All)
ALH avg (um)
Count Agents
0.0
10.0
0.0
10.0
true
false
"set-histogram-num-bars sqrt(num_turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ALH] of turtles"

SWITCH
25
350
172
383
rand_coordinate
rand_coordinate
1
1
-1000

PLOT
1341
168
1541
318
Positional Counts
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Progressive_qi" 1.0 0 -14070903 true "" "plot (count turtles with [xcor > lower_bound and xcor < upper_bound])"
"Total" 1.0 0 -7500403 true "" "plot (count turtles with [xcor < 0 and xcor > -16])"

PLOT
1342
336
1542
486
X Posit. Hist
NIL
NIL
0.0
32.0
0.0
10.0
true
false
"" ""
PENS
"Sperm_As" 1.0 1 -13345367 true "" "histogram [max-pxcor + xcor] of turtles"

PLOT
1112
10
1312
160
Count (each segment)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Right" 1.0 0 -13345367 true "" "plot count turtles with [xcor > lower_bound and xcor < upper_bound] "
"Left" 1.0 0 -2674135 true "" "plot count turtles with [xcor < 0 and xcor > -16] "

INPUTBOX
1363
16
1518
76
Lower_bound
1.0
1
0
Number

INPUTBOX
1363
84
1518
144
upper_bound
16.0
1
0
Number

INPUTBOX
21
150
176
210
num_turtles
1000.0
1
0
Number

PLOT
685
508
885
658
Repres. Intra_Ca
NIL
NIL
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [intra_Ca] of turtle 0"
"pen-1" 1.0 0 -7500403 true "" "plot [intra_Ca] of turtle 1"
"pen-2" 1.0 0 -2674135 true "" "plot [intra_Ca] of turtle 2"
"pen-3" 1.0 0 -955883 true "" "plot [intra_Ca] of turtle 3"

PLOT
912
506
1112
656
Init Freq Hist
NIL
NIL
0.0
20.0
0.0
10.0
true
false
"set-histogram-num-bars sqrt(num_turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [freq] of turtles"

PLOT
1333
507
1533
657
Right Freq Hist
NIL
NIL
0.0
20.0
0.0
1.0
true
false
"set-histogram-num-bars sqrt(num_turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [freq] of turtles with [ xcor > lower_bound and xcor <= upper_bound]"

PLOT
1123
507
1323
657
Left Freq Hist
NIL
NIL
0.0
20.0
0.0
10.0
true
false
"set-histogram-num-bars sqrt(num_turtles)" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [freq] of turtles with [ xcor < lower_bound and xcor >= (- upper_bound)]"

BUTTON
329
377
409
410
close-file
close-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
47
390
150
423
record
record
1
1
-1000

PLOT
1549
11
1749
161
Median Osc. Freq
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Right" 1.0 0 -13345367 true "" "plot median [freq] of turtles with [xcor > lower_bound and xcor < upper_bound]"
"Left" 1.0 0 -2674135 true "" "plot median [freq] of turtles with [xcor < 0 and xcor > -16]"

BUTTON
209
376
318
409
clear drawing
clear-drawing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1550
168
1750
318
Max Osc. Freq
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Right" 1.0 0 -13345367 true "" "plot max [freq] of turtles with [xcor > lower_bound and xcor < upper_bound]"
"Left" 1.0 0 -2674135 true "" "plot max [freq] of turtles with [xcor < 0 and xcor > -16]"

PLOT
1555
338
1755
488
Max egg contact time (s)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot max [egg_contact_time] of sperms"

PLOT
1555
506
1755
656
Osc. Freq. Params of Contacting Sperms
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -955883 true "" "plot median [freq] of sperms with [egg_contact_time > 0]"
"Max" 1.0 0 -5825686 true "" "plot max [freq] of sperms with [egg_contact_time > 0]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

sperm
true
0
Circle -7500403 true true 135 135 30
Line -7500403 true 150 165 135 195
Line -7500403 true 135 195 165 225
Line -7500403 true 165 225 150 255

sperm_v1
true
0
Circle -7500403 true true 135 135 30
Line -7500403 true 150 165 135 180
Line -7500403 true 135 180 165 210
Line -7500403 true 165 210 150 240

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>median [VCL] of turtles</metric>
    <metric>median [VAP] of turtles</metric>
    <metric>median [VSL] of turtles</metric>
    <metric>RMSD</metric>
    <metric>time</metric>
    <enumeratedValueSet variable="state_duration">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Ds">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rand_coordinate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Bs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="input_xcor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_As">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Es">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num_sperm_Cs" first="0" step="1" last="80"/>
    <enumeratedValueSet variable="draw">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="input_ycor">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="250" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count Sperm_As with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <metric>count Sperm_Bs with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <metric>count Sperm_Cs with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <metric>count Sperm_Ds with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <metric>count Sperm_Es with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <metric>count turtles with [xcor &gt; lower_bound and xcor &lt; upper_bound]</metric>
    <enumeratedValueSet variable="state_duration">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Ds">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rand_coordinate">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Bs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="input_xcor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_As">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upper_bound">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Es">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_sperm_Cs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="input_ycor">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
