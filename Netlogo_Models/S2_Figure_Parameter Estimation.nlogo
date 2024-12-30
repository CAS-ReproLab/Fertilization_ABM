;; Used in Figure 2 for parameterization of the movement functions.

;;;;;;;;;;;;;;;;;;;;;;
;; types of turtles ;;
;;;;;;;;;;;;;;;;;;;;;;
breed [sperm_As sperm_A] ; stores the sperm subpopulation A agentset
breed [sperm_Bs sperm_B] ; stores the sperm subpopulation B agentset
breed [sperm_Cs sperm_C] ; .. same as above
breed [sperm_Ds sperm_D]
breed [sperm_Es sperm_E]


;;;;;;;;;;;;;;;;;;;;;;
;; global variables ;;
;;;;;;;;;;;;;;;;;;;;;;
globals [time len RMSD deltaT stepT]

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
  direction_changes
  RSD
]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup the simulation ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup

 clear-all

   create-sperm_As num_sperm_As
   ask sperm_As [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"] ; Uncomment to choose starting state at random
    set motility_state "progressive" ; Can change motility_state to specified string if desired
    ;set color blue ; Uncomment to assign distinct color to different motility states

  ]

   create-sperm_Bs num_sperm_Bs
   ask sperm_Bs [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"]
    set motility_state "intermediate"
    ;set color green

  ]

    create-sperm_Cs num_sperm_Cs
   ask sperm_Cs [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"]
    set motility_state "hyperactive"
    ;set color green

  ]

     create-sperm_Ds num_sperm_Ds
   ask sperm_Ds [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"]
    set motility_state "slow"
    ;set color green

  ]

     create-sperm_Es num_sperm_Es
   ask sperm_Es [
    ;set motility_state one-of [ "progressive" "hyperactive" "intermediate" "slow" "weak"]
    set motility_state "weak"
    ;set color blue

  ]

  ask turtles [
    set shape "circle"
    set size 0.3
    set color white
    ifelse rand_coordinate = True [setxy random-xcor random-ycor] ; Can choose starting spatial distribution of sperm within the grid space using the GUI button
    [setxy input_xcor input_ycor]  ; Allows input on starting position from GUI.
    set init_x xcor
    set init_y ycor
    set path_len 0
    set last_heading heading
    set direction_changes 0
    set ALH 0
  ]

  set len 40 ; initialize the length variable
  ;; Sets the length scaling factor-
  ;; each patch has a side length (len) of len in um.
  ;; Everything is scaled to the size of a patch.
  ;; If we change the number of patches, then we change the scaling factor,
  ;; and would need to adjust all other len dependent variables accordingly.
  ;; Example: at len 10 a step_len of 1 is 10 um. At len 20 a step_len of 0.5 is 10 um. At len 40 step_len = .25 is 10 um

  set time 0 ; initialize the time variable

 reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;
;; recursive model ;;
;;;;;;;;;;;;;;;;;;;;;

to go
  if not any? patches with [pcolor = black] [clear-drawing stop]
  ask turtles [
    ifelse draw = True [pen-down] [pen-up]]
    set time time + (1 / 25.4) ;; (seconds) Assuming the sperm cross the central path at a frequency of 25.4 Hz, each tick is then 1/25.4 seconds.
    markov_move
    state_transition_sperm_As
    state_transition_sperm_Bs
    state_transition_sperm_Cs
    state_transition_sperm_Ds
    state_transition_sperm_Es
    update_RMSD
  ;export-view (word ticks ".png") ;; Exports ticks as images for making a Gif saves to directory where the model is loaded from. Uncomment to run..
  tick
end

;;;;;;;;;;;;;;;;
;; Procedures ;;
;;;;;;;;;;;;;;;;

;; Movement Functions ;;

to progressive-motility

  set previous_x current_x ; Store previous position
  set previous_y current_y

  set current_x xcor ; Set current position
  set current_y ycor

  ;ifelse ticks mod 2 = 0 [rt 15 + (random (90 - 15))] [rt -15 + (random (-90 + 15))]
  rt ( (-1) ^ ( ticks mod 2 ) ) * ( 15 + 37.5 + 75.0 / 2.0 / sqrt (3.0) / sqrt(deltaT) * sqrt(stepT) * (random-normal 0 1.0) ) ; MM: this is the Gaussian noise-based integration of algorithm for angle
  ;set step_len 0.25 + (random-float (0.30 - 0.25))
  set step_len (0.25 + 0.025 + 0.05 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0)); MM: this is the Gaussian noise-based integration of algorithm for translation

  set path_len path_len + step_len
  fd step_len

  update_RSD ; Root square displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude

end

to intermediate-motility
  set current_x xcor
  set current_y ycor
  update_RSD
  ;set intermediate_angle 85 + (random (200 - 85))
  ;ifelse ticks mod 2 = 0 [rt 100 + (random (140 - 100))] [rt -100 + (random (-140 + 100))]
  rt ( (-1) ^ ( ticks mod 2 ) ) * ( 100 + 20 + 40.0 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0) )
  ;set step_len 0.4 + (random-float (0.425 - 0.4))
    set step_len (0.4 + 0.0125 + 0.025 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0))
    set path_len path_len + step_len
  fd step_len

  update_RSD ; Root square displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
end

to hyperactive-motility
  set current_x xcor
  set current_y ycor
  update_RSD
  ;ifelse random-float 1.00 < 0.6 [rt 90 + (random (180 - 90))] [lt -90 + (random (-180 + 90))]
  rt ( 180 + 180.0 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0) )
  ;set step_len 0.35 + (random-float (0.45 - 0.35))
  set step_len (0.35 + 0.05 + 0.1 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0))
    set path_len path_len + step_len
  fd step_len

  update_RSD ; Root square displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
end

to slow-motility
  set current_x xcor
  set current_y ycor
  update_RSD
  ;ifelse ticks mod 2 = 0 [rt 90 + (random (240 - 90))] [rt -90 + (random (-240 + 90))]
  rt ( (-1) ^ ( ticks mod 2 ) ) * ( 90 + 75 + 150.0 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0) )
  ;set step_len 0.1 + (random-float (0.2 - 0.1))
  set step_len (0.1 + 0.05 + 0.1 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0))
    set path_len path_len + step_len
  fd step_len

  update_RSD ; Root square displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
end

to weak-motility
  set current_x xcor
  set current_y ycor
  update_RSD
  ;ifelse ticks mod 2 = 0 [rt 90 + (random (270 - 90))] [rt -90 + (random (-270 + 90))]
  rt ( (-1) ^ ( ticks mod 2 ) ) * ( 90 + 90 + 180.0 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0) )
  ;set step_len 0.075 + (random-float (0.125 - 0.075))
  set step_len (0.075 + 0.025 + 0.05 / 2.0 / sqrt (3.0) / sqrt (deltaT) * sqrt(stepT) * (random-normal 0 1.0))
      set path_len path_len + step_len
  fd step_len

  update_RSD ; Root square displacement
  update_VSL ; straight line velocity
  update_VCL ; curvilinear velocity
  update_VAP ; average path velocity
  update_ALH ; average lateral head displacement amplitude
end

;; Markov Models For Subpopulations ;;

to state_transition_sperm_As ; primarily progressive (based on current transition matrix)
  if ticks mod state_duration = 0 [ ; allows setting state transitions that only happen over 'state_duration' number of ticks
  ask sperm_As
  [
  let rand_num random-float 1.00
     if motility_state = "progressive" [if rand_num < 0.95 [set motility_state "progressive"]]
      if rand_num >= 0.95 and rand_num < 0.97 [set motility_state "intermediate" ]
      if rand_num >= 0.97  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "intermediate" [if rand_num < 0.95 [set motility_state "progressive" ]]
      if rand_num >= 0.95 and rand_num < 0.97 [set motility_state "intermediate" ]
      if rand_num >= 0.97  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "hyperactive" [if rand_num < 0.95 [set motility_state "progressive" ]]
      if rand_num >= 0.95 and rand_num < 0.97 [set motility_state "intermediate" ]
      if rand_num >= 0.97  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "slow" [if rand_num < 0.95 [set motility_state "progressive" ]]
      if rand_num >= 0.95 and rand_num < 0.97 [set motility_state "intermediate" ]
      if rand_num >= 0.97  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "weak" [if rand_num < 0.95 [set motility_state "progressive" ]]
      if rand_num >= 0.95 and rand_num < 0.97 [set motility_state "intermediate" ]
      if rand_num >= 0.97  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]
  ]
  ]
end

to state_transition_sperm_Bs ; primarily intermediate
  if ticks mod state_duration = 0 [ ; allows setting state transitions that only happen ever 'state_duration' number of ticks
  ask sperm_Bs
  [
  let rand_num random-float 1.00
      if motility_state = "progressive" [if rand_num < 0.05 [set motility_state "progressive" ]]
      if rand_num >= 0.05 and rand_num < 0.95 [set motility_state "intermediate" ]
      if rand_num >= 0.95  and rand_num < 0.97 [set motility_state "hyperactive" ]
      if rand_num >= 0.97 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

       if motility_state = "intermediate" [if rand_num < 0.05 [set motility_state "progressive" ]]
      if rand_num >= 0.05 and rand_num < 0.95 [set motility_state "intermediate" ]
      if rand_num >= 0.95  and rand_num < 0.97 [set motility_state "hyperactive" ]
      if rand_num >= 0.97 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "hyperactive" [if rand_num < 0.05 [set motility_state "progressive" ]]
      if rand_num >= 0.05 and rand_num < 0.95 [set motility_state "intermediate" ]
      if rand_num >= 0.95  and rand_num < 0.97 [set motility_state "hyperactive" ]
      if rand_num >= 0.97 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "slow" [if rand_num < 0.05 [set motility_state "progressive" ]]
      if rand_num >= 0.05 and rand_num < 0.95 [set motility_state "intermediate" ]
      if rand_num >= 0.95  and rand_num < 0.97 [set motility_state "hyperactive" ]
      if rand_num >= 0.97 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "weak" [if rand_num < 0.05 [set motility_state "progressive" ]]
      if rand_num >= 0.05 and rand_num < 0.95 [set motility_state "intermediate" ]
      if rand_num >= 0.95  and rand_num < 0.97 [set motility_state "hyperactive" ]
      if rand_num >= 0.97 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]
  ]
  ]
end

to state_transition_sperm_Cs ; primarily hyperactive
  if ticks mod state_duration = 0 [ ; allows setting state transitions that only happen ever 'state_duration' number of ticks
  ask sperm_Cs
  [
  let rand_num random-float 1.00
      if motility_state = "progressive" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "intermediate" [if rand_num < 0.02 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "hyperactive" [if rand_num < 0.02 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "slow" [if rand_num < 0.02 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "weak" [if rand_num < 0.02 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.98 [set motility_state "hyperactive" ]
      if rand_num >= 0.98 and rand_num < 0.99 [set motility_state "slow" ]
      if rand_num >= 0.99  and rand_num < 1.00 [set motility_state "weak" ]
  ]
  ]
end

  to state_transition_sperm_Ds ; primarily slow
  if ticks mod state_duration = 0 [ ; allows setting state transitions that only happen ever 'state_duration' number of ticks
  ask sperm_Ds
  [
  let rand_num random-float 1.00
      if motility_state = "progressive" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.03 [set motility_state "intermediate" ]
      if rand_num >= 0.03  and rand_num < 0.05 [set motility_state "hyperactive" ]
      if rand_num >= 0.05 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "intermediate" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.03 [set motility_state "intermediate" ]
      if rand_num >= 0.03  and rand_num < 0.05 [set motility_state "hyperactive" ]
      if rand_num >= 0.05 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "hyperactive" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.03 [set motility_state "intermediate" ]
      if rand_num >= 0.03  and rand_num < 0.05 [set motility_state "hyperactive" ]
      if rand_num >= 0.05 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "slow" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.03 [set motility_state "intermediate" ]
      if rand_num >= 0.03  and rand_num < 0.05 [set motility_state "hyperactive" ]
      if rand_num >= 0.05 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "weak" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.03 [set motility_state "intermediate" ]
      if rand_num >= 0.03  and rand_num < 0.05 [set motility_state "hyperactive" ]
      if rand_num >= 0.05 and rand_num < 0.98 [set motility_state "slow" ]
      if rand_num >= 0.98  and rand_num < 1.00 [set motility_state "weak" ]
  ]
  ]
end

  to state_transition_sperm_Es ; primarily slow
  if ticks mod state_duration = 0 [ ; allows setting state transitions that only happen ever 'state_duration' number of ticks
  ask sperm_Es
  [
  let rand_num random-float 1.00
      if motility_state = "progressive" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.03 [set motility_state "hyperactive" ]
      if rand_num >= 0.03 and rand_num < 0.04 [set motility_state "slow" ]
      if rand_num >= 0.04  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "intermediate" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.03 [set motility_state "hyperactive" ]
      if rand_num >= 0.03 and rand_num < 0.04 [set motility_state "slow" ]
      if rand_num >= 0.04  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "hyperactive" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.03 [set motility_state "hyperactive" ]
      if rand_num >= 0.03 and rand_num < 0.04 [set motility_state "slow" ]
      if rand_num >= 0.04  and rand_num < 1.00 [set motility_state "weak" ]

     if motility_state = "slow" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.03 [set motility_state "hyperactive" ]
      if rand_num >= 0.03 and rand_num < 0.04 [set motility_state "slow" ]
      if rand_num >= 0.04  and rand_num < 1.00 [set motility_state "weak" ]

      if motility_state = "weak" [if rand_num < 0.01 [set motility_state "progressive" ]]
      if rand_num >= 0.01 and rand_num < 0.02 [set motility_state "intermediate" ]
      if rand_num >= 0.02  and rand_num < 0.03 [set motility_state "hyperactive" ]
      if rand_num >= 0.03 and rand_num < 0.04 [set motility_state "slow" ]
      if rand_num >= 0.04  and rand_num < 1.00 [set motility_state "weak" ]
  ]
  ]
end

;; Function call for markov movement ;;

to markov_move
  ask turtles [
  ;set color scale-color orange VCL 150 450 ; uncomment to set color scale to curvilinear velocity (VCL)
  if motility_state = "progressive"
  [
      progressive-motility
      ;set color blue ; uncomment to set color by motility state.
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

;; Additional function calls ;;

to search_space
  if pcolor != 9.9999 [set pcolor 0.1]
end

to update_RSD
  let x_component (current_x - init_x) * len
  let y_component (current_y - init_y) * len
  set RSD sqrt (((x_component) ^ 2) + ((y_component) ^ 2))
end

to update_RMSD
  set RMSD (sum [RSD] of turtles) / (count turtles)
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

;; Code below this point on Github is automatically deposited and is related to the configuration of buttons and defaults in the Netlogo environment.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
673
474
-1
-1
13.0
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
5
10
60
43
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
65
10
120
43
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
183
481
294
514
draw
draw
1
1
-1000

SLIDER
4
77
206
110
num_sperm_As
num_sperm_As
0
1000
0.0
1
1
cells
HORIZONTAL

SLIDER
5
130
203
163
num_sperm_Bs
num_sperm_Bs
0
1000
0.0
1
1
cells
HORIZONTAL

SLIDER
5
186
205
219
num_sperm_Cs
num_sperm_Cs
0
1000
0.0
1
1
cells
HORIZONTAL

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

SLIDER
2
341
201
374
state_duration
state_duration
1
1000
1.0
1
1
ticks
HORIZONTAL

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
10.0
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
Motility State
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
"Progressive" 1.0 0 -13345367 true "" "plot count turtles with [motility_state = \"progressive\"]"
"Intermediate" 1.0 0 -10899396 true "" "plot count turtles with [motility_state = \"intermediate\"]"
"Hyperactive" 1.0 0 -1184463 true "" "plot count turtles with [motility_state = \"hyperactive\"]"
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
18
387
173
447
input_xcor
0.0
1
0
Number

INPUTBOX
18
455
173
515
input_ycor
0.0
1
0
Number

BUTTON
124
10
198
43
go (50)
if ticks < 50 [go]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
236
205
269
num_sperm_Ds
num_sperm_Ds
0
1000
0.0
1
1
cells
HORIZONTAL

SLIDER
3
284
205
317
num_sperm_Es
num_sperm_Es
0
1000
20.0
1
1
cells
HORIZONTAL

PLOT
1115
10
1315
160
RSD (All)
NIL
NIL
0.0
100.0
0.0
20.0
false
false
"" ""
PENS
"default" 1.0 1 -13345367 true "set-histogram-num-bars count sperm_As" "histogram [RSD] of sperm_As"
"pen-1" 1.0 1 -10899396 true "set-histogram-num-bars count sperm_Bs" "histogram [RSD] of sperm_Bs"
"pen-2" 1.0 1 -1184463 true "set-histogram-num-bars count sperm_Cs" "histogram [RSD] of sperm_Cs"
"pen-3" 1.0 1 -955883 true "set-histogram-num-bars count sperm_Ds" "histogram [RSD] of sperm_Ds"
"pen-4" 1.0 1 -2674135 true "set-histogram-num-bars count sperm_Es" "histogram [RSD] of sperm_Es"

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
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ALH] of turtles"

SWITCH
322
483
469
516
rand_coordinate
rand_coordinate
0
1
-1000

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
