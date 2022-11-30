;; Defines the different types of agents
breed [spermAs spermA]
breed [spermBs spermB]
breed [spermCs spermC]
breed [eggs egg]
breed [halos halo]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Defines the global variables used by the procedures
globals[init-probability-spermA init-probability-spermB init-probability-spermC contactsA contactsB contactsC total-contacts
  probability-spermA-success probability-spermA-unsuccess probability-spermB-success probability-spermB-unsuccess probability-spermC-success probability-spermC-unsuccess
  marginalY-success marginalY-unsuccess patch-data sperm-init-entropy fertilization-entropy mutual-information
  joint-entropy-spermA-success joint-entropy-spermA-unsuccess joint-entropy-spermB-success joint-entropy-spermB-unsuccess joint-entropy-spermC-success joint-entropy-spermC-unsuccess
  condprob-spermA-contactA condprob-spermA-contactB condprob-spermB-contactA condprob-spermB-contactB condprob-spermAC-contactA condprob-spermC-contactB  cond-entropy]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  This procedure sets up the patches and turtles
to setup

  clear-all ;; Clear everything.

load-patch-data ;; loads patch data from a file in the model directory called 'File IO Patch Data'
show-patch-data

  ;;  This will create sperms in the bottom left quadrant. All located at the same starting position
  create-spermAs initial-number-spermA [
    set color 3
    set shape "sperm_v1"
    set size 3
    setxy xcor  -14
    setxy ycor -14
  ]
  create-spermBs initial-number-spermB [
    set color 3
    set shape "sperm_v1"
    set size 3
    setxy xcor  -14
    setxy ycor -14
  ]

    create-spermCs initial-number-spermC [
    set color 3
    set shape "sperm_v1"
    set size 3
    setxy xcor  -14
    setxy ycor -14
  ]

  ;; This will create an egg turtle, though it is non-functional and only serves to cover the egg patch as a circle (for visual appeal)
  create-eggs 1[
    set color gray
    set shape "circle"
    set size 3
    setxy xcor 0
    setxy ycor 0
  ]

  ;; This will create the egg patch that the sperm can interact with to record the contacts. It sits directly underneath the egg turtle
  ask patches with [pxcor = 0 and pycor = 0]
  [set pcolor gray]

  set-default-shape halos "thin ring" ; Makes the halos circular rather than a default arrow shape

  ;; This will initialize the values at 0 for several variables.
  set contactsA (0)
  set contactsB (0)
  set contactsC (0)
  set probability-spermA-success (0)
  set probability-spermA-unsuccess (0)
  set probability-spermB-success (0)
  set probability-spermB-unsuccess (0)
  set probability-spermC-success (0)
  set probability-spermC-unsuccess (0)
  set marginalY-success (0)
  set marginalY-unsuccess (0)

  ;; This will update the reported sperm subpopulation probabilities and the accompanying marginal probability distribution
  report-init-probability-spermA

  report-init-probability-spermB

  report-init-probability-spermC

  report-sperm-init-entropy

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go ;;  This procedure makes the turtles move

  ;; Stops the simulation after a cumulative number of contacts with the egg patch is reached
  if total-contacts >=  threshold [stop]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Sets the rules for sperm behavior
  ask spermAs
  [
    update-contactsA
    rt random wiggle-angleA
    lt random wiggle-angleA
    ;;  This important conditional determines if they are about to walk into a blue
    ;;  patch.  It lets us make a decision about what to do BEFORE the turtle walks
    ;;  into a blue patch.  This is a good way to simulate a wall or barrier that turtles
    ;;  cannot move onto.  Notice that we don't use any information on the turtle's
    ;;  heading or position.  Remember, patch-ahead 1 is the patch the turtle would be on
    ;;  if it moved forward 1 in its current heading.
    (ifelse [pcolor] of patch-left-and-ahead 30 0.5 = 9.9999
      [ rt random-float attract-angleA ]   ;; We see a pcolor value of 9.9999 in front or to the slight left of us. Turn an input random amount to the right.
      [pcolor] of patch-right-and-ahead 30 0.5 = 9.9999
      [ lt random-float attract-angleA]
      [ fd 0.5 ])                  ;; Otherwise, it is safe to move forward.

  ]

   ask spermBs
  [
    update-contactsB
    rt random wiggle-angleB
    lt random wiggle-angleB
     (ifelse [pcolor] of patch-left-and-ahead 30 0.5 = 9.9999
      [ rt random-float attract-angleB ]
      [pcolor] of patch-right-and-ahead 30 0.5 = 9.9999
      [ lt random-float attract-angleB]
      [ fd 0.5 ])
  ]

       ask spermCs
  [
    update-contactsC
    rt random wiggle-angleC
    lt random wiggle-angleC
     (ifelse [pcolor] of patch-left-and-ahead 30 0.5 = 9.9999
      [ rt random-float attract-angleC ]
      [pcolor] of patch-right-and-ahead 30 0.5 = 9.9999
      [ lt random-float attract-angleC]
      [ fd 0.5 ])
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Reports the values used for analysis of the simulation

  report-total-contacts

  report-marginalY-success

  report-marginalY-unsuccess

  report-probability-spermA-success

  report-probability-spermA-unsuccess

  report-probability-spermB-success

  report-probability-spermB-unsuccess

  report-probability-spermC-success

  report-probability-spermC-unsuccess

  report-fertilization-entropy

  report-cond-entropy

  report-mutual-information

  report-joint-entropy-spermA-success

  report-joint-entropy-spermB-success

  report-joint-entropy-spermC-success

  report-joint-entropy-spermA-unsuccess

  report-joint-entropy-spermB-unsuccess

  report-joint-entropy-spermC-unsuccess

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  tick


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;export-view (word ticks ".png") ;; Exports ticks as images for making a Gif saves to directory where the model is loaded from. Uncomment to run..
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-contactsA ; counts # of contacts made by sperm X with the egg during the simulation
  if [pcolor] of patch-ahead 0.5 = gray [set contactsA (1 + contactsA)
  set color orange
    make-halo
    ;pen-down
  rt random-float attract-angleA]
end

to update-contactsB
  if [pcolor] of patch-ahead 0.5 = gray [set contactsB (1 + contactsB)
  set color sky
    make-halo
    ;pen-down
  rt random-float attract-angleB]
end

to update-contactsC
  if [pcolor] of patch-ahead 0.5 = gray [set contactsC (1 + contactsC)
  set color magenta
    make-halo
    ;pen-down
  rt random-float attract-angleC]
end

to report-total-contacts ;; Sums the total number of contacts from all sperm subpopulations
  set total-contacts (contactsA + contactsB + contactsC)
end

to report-probability-spermA-success
  set probability-spermA-success ((count turtles with [color = orange])/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-probability-spermA-unsuccess
  set probability-spermA-unsuccess ((initial-number-spermA - count turtles with [color = orange])/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-probability-spermB-success
  set probability-spermB-success (count turtles with [color = sky]/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-probability-spermB-unsuccess
  set probability-spermB-unsuccess ((initial-number-spermB - (count turtles with [color = sky]))/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-probability-spermC-success
  set probability-spermC-success (count turtles with [color = magenta]/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-probability-spermC-unsuccess
  set probability-spermC-unsuccess ((initial-number-spermC - (count turtles with [color = magenta]))/(initial-number-spermA + initial-number-spermB + initial-number-spermC))
end

to report-init-probability-spermA
  if initial-number-spermA > 0 [set init-probability-spermA (initial-number-spermA / (initial-number-spermA + initial-number-spermB + initial-number-spermC))]
  ;set init-probability-spermA precision init-probability-spermA 2
end

to report-init-probability-spermB
  if initial-number-spermB > 0 [set init-probability-spermB (initial-number-spermB / (initial-number-spermA + initial-number-spermB + initial-number-spermC))]
  ;set init-probability-spermB precision init-probability-spermB 2
end

to report-init-probability-spermC
  if initial-number-spermC > 0 [set init-probability-spermC (initial-number-spermC / (initial-number-spermA + initial-number-spermB + initial-number-spermC))]
  ;set init-probability-spermB precision init-probability-spermB 2
end

to report-marginalY-success
  set marginalY-success (probability-spermA-success + probability-spermB-success + probability-spermC-success)
end

to report-marginalY-unsuccess
  set marginalY-unsuccess (probability-spermA-unsuccess + probability-spermB-unsuccess + probability-spermC-unsuccess)
end

to report-sperm-init-entropy ; Let P(X=x) be the initial sperm phenotype expressed as a discrete random variable, this is the entropy H(X)= -p(x)log2(p(x) of the probability distribution
 set sperm-init-entropy ( - ((init-probability-spermA * (log init-probability-spermA 2) + (init-probability-spermB * (log init-probability-spermB 2) + (init-probability-spermC * (log init-probability-spermC 2))))))
  ;set sperm-init-entropy precision sperm-init-entropy 2
end

to report-fertilization-entropy ; Let P(X=x) be the contact frequency from each sperm type expressed as a discrete random variable, this is the entropy H(Y) of the probability distribution
  if marginalY-success * marginalY-unsuccess != 0 [set fertilization-entropy ( - ((marginalY-success * (log marginalY-success 2) + (marginalY-unsuccess * (log marginalY-unsuccess 2)))))]
  ;set fertilization-entropy precision fertilization-entropy 2
end

to report-joint-entropy-spermA-success
  ifelse probability-spermA-success = 0 OR marginalY-success = 0 [set joint-entropy-spermA-success (0)]
  [set joint-entropy-spermA-success (probability-spermA-success * (log (probability-spermA-success / marginalY-success) 2))]
end

to report-joint-entropy-spermB-success
  ifelse probability-spermB-success = 0 OR marginalY-success = 0 [set joint-entropy-spermB-success (0)]
  [set joint-entropy-spermB-success (probability-spermB-success * (log (probability-spermB-success / marginalY-success) 2))]
end

to report-joint-entropy-spermC-success
  ifelse probability-spermC-success = 0 OR marginalY-success = 0 [set joint-entropy-spermC-success (0)]
  [set joint-entropy-spermC-success (probability-spermC-success * (log (probability-spermC-success / marginalY-success) 2))]
end

to report-joint-entropy-spermA-unsuccess
  ifelse probability-spermA-unsuccess = 0 OR marginalY-unsuccess = 0 [set joint-entropy-spermA-unsuccess (0)]
  [set joint-entropy-spermA-unsuccess (probability-spermA-unsuccess * (log (probability-spermA-unsuccess / marginalY-unsuccess) 2))]
end

to report-joint-entropy-spermB-unsuccess
  ifelse probability-spermB-unsuccess = 0 OR marginalY-unsuccess = 0 [set joint-entropy-spermB-unsuccess (0)]
  [set joint-entropy-spermB-unsuccess (probability-spermB-unsuccess * (log (probability-spermB-unsuccess / marginalY-unsuccess) 2))]
end

to report-joint-entropy-spermC-unsuccess
  ifelse probability-spermC-unsuccess = 0 OR marginalY-unsuccess = 0 [set joint-entropy-spermC-unsuccess (0)]
  [set joint-entropy-spermC-unsuccess (probability-spermC-unsuccess * (log (probability-spermC-unsuccess / marginalY-unsuccess) 2))]
end

to report-cond-entropy
  set cond-entropy (- (joint-entropy-spermA-success + joint-entropy-spermB-success + joint-entropy-spermC-success +
    joint-entropy-spermA-unsuccess + joint-entropy-spermB-unsuccess + joint-entropy-spermC-unsuccess))
  ;set cond-entropy precision cond-entropy 2
end

to report-mutual-information ; Calculated mutual information I(X;Y) = H(X) - H(X|Y)
  if marginalY-success * marginalY-unsuccess != 0 [(set mutual-information (sperm-init-entropy - cond-entropy))]
  ;set mutual-information precision mutual-information 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-halo  ;; procedure to make a halo around sperm that contact the egg. Aids visual tracking
  ;; when you use HATCH, the new turtle inherits the
  ;; characteristics of the parent.  so the halo will
  ;; be the same color as the turtle it encircles (unless
  ;; you add code to change it
  hatch-halos 1
  [ set size 7
    ;; Use an RGB color to make halo two-thirds transparent
    set color lput 64 extract-rgb color
    ;; set thickness of halo to half a patch
    __set-line-thickness 0.1
    ;; We create an invisible directed link from the runner
    ;; to the halo.  Using tie means that whenever the
    ;; runner moves, the halo moves with it.
    create-link-from myself
    [ tie
      hide-link ] ]
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

;; Code below this point on Github is automatically deposited and is related to the configuration of buttons and defaults in the Netlogo environment.
@#$#@#$#@
GRAPHICS-WINDOW
217
10
645
439
-1
-1
12.0
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
26
16
186
55
NIL
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
25
67
187
108
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
964
14
1059
47
NIL
pen-down
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

SLIDER
19
115
191
148
wiggle-angleA
wiggle-angleA
0
360
57.0
1
1
degree
HORIZONTAL

SLIDER
658
15
877
48
initial-number-spermA
initial-number-spermA
1
100
50.0
1
1
particles
HORIZONTAL

PLOT
664
172
1099
322
Contacts Vs. Time (X-Bearing Sperm)
Time
Contacts
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"ContactsA" 1.0 0 -955883 true "" "plot contactsA"
"ContactsB" 1.0 0 -13791810 true "" "plot contactsB"
"ContactsC" 1.0 0 -5825686 true "" "plot contactsC"
"Total Contacts" 1.0 0 -16777216 true "" "plot total-contacts"

SLIDER
18
161
192
194
wiggle-angleB
wiggle-angleB
0
360
360.0
1
1
degrees
HORIZONTAL

INPUTBOX
16
264
171
324
attract-angleA
180.0
1
0
Number

INPUTBOX
16
340
171
400
attract-angleB
180.0
1
0
Number

MONITOR
696
200
812
245
Cumulative Contacts
total-contacts
17
1
11

INPUTBOX
887
15
952
75
threshold
50.0
1
0
Number

MONITOR
665
337
760
382
P(Y) = success
marginalY-success
2
1
11

MONITOR
789
339
898
384
P(Y) = unsuccess
marginalY-unsuccess
2
1
11

SLIDER
661
69
877
102
initial-number-spermB
initial-number-spermB
1
100
50.0
1
1
sperm
HORIZONTAL

MONITOR
666
393
760
438
P(X) = spermA
init-probability-spermA
2
1
11

MONITOR
789
396
882
441
P(X) = spermB
init-probability-spermB
2
1
11

MONITOR
944
341
1014
386
H(X) (bits)
sperm-init-entropy
2
1
11

TEXTBOX
221
458
652
556
Sperm phenotype is considered a random variable X. \n\nProbability of being fertilized is considered a random variable Y.
11
0.0
1

MONITOR
1050
342
1120
387
H(Y) (bits)
fertilization-entropy
2
1
11

MONITOR
1066
400
1123
445
I(X;Y)
mutual-information
2
1
11

MONITOR
998
400
1055
445
H(X|Y)
cond-entropy
2
1
11

SLIDER
663
118
879
151
initial-number-spermC
initial-number-spermC
1
100
50.0
1
1
sperm
HORIZONTAL

INPUTBOX
19
413
174
473
attract-angleC
180.0
1
0
Number

SLIDER
17
214
192
247
wiggle-angleC
wiggle-angleC
0
360
360.0
1
1
degrees
HORIZONTAL

MONITOR
890
398
984
443
P(X) = spermC
init-probability-spermC
2
1
11

@#$#@#$#@
## WHAT IS IT?

This program simulates fertilization of an egg by sperm. The model assumes that sperm move randomly about their environment and the initial population consists of distinct subpopulations that may have functional differences in: number, motility pattern, or interaction with microenvironmental structures meant to simulate the epithelial surface of the female reproductive tract. 

Created: Nov 2022 by Cameron A. Schmidt; Integrative Cellular Bioenergetics Lab; East Carolina University Dept. of Biology.

##  HOW TO RUN IT?

The model requires an additional file named 'File IO Patch Data'. This file is created by an accompanying Netlogo ABM 'Maze Draw 001' and contains the patch coordinates for the simulation. In the simplest form, the patches only surround the outer edge to contain the simulation. Sperm cannot cross the patches, and they will act as a barrier. Sperm can be parameterized to interact with the patches they encounter in different ways through the variable 'Attract-Angle'. Initial sperm number for each population can be adjusted as well as the motility pattern ('wiggle angle'). 

## WHAT DOES IT COMPUTE?

The model determines the information entropy for the phenotypic variance in the initial population of sperm. An increase in entropy indicates that the phenotypes are more uniformly distributed within the initial population. During simulation, the number of sperm of each subpopulation that make contact with the egg are recorded, and the conditional entropy of sperm-egg contact is calculated. This value represents the relatedness between initial sperm variance and sperm-egg contact. Mutual information (I(X;Y)) is determined from the calculated entropy and joint entropy values respectively.

## HOW TO INTERPRET IT?

Mutual information quantitates how much knowing the value of a jointly distributed random variable tells us about the other random variable in question. If the mutual information is zero, then the two random variables are independent. For example, if a particular type of sperm (say strongly progressively motile) is one third of the initial population but makes more contacts with the egg than the other sperm types, the I(X;Y) will be relatively greater than if all three sperm types made an equal number of contacts. Mutual information is commutative, so we can also interpret this the other way.    

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

sperm_v1
true
0
Line -7500403 true 150 150 135 180
Circle -7500403 true true 135 120 30
Line -7500403 true 135 180 150 210
Line -7500403 true 150 210 150 240

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

thin ring
true
0
Circle -7500403 false true 86 86 127

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 10000</exitCondition>
    <metric>mutual-information</metric>
    <enumeratedValueSet variable="attract-angleB">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiggle-angleA">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiggle-angleB">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-spermA">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attract-angleA">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initial-number-spermB" first="1" step="1" last="100"/>
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
