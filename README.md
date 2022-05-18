# 2-Stage-BCI
This is the code used to record the data from the 2-Stage-BCI study. 
 
### Introduction
This Document gives a very high level descriptions of the files to be found and file structure.

## Code
This folder contains all scripts.
 
## Assets
This folder contains all assets necessary (Excluding Openvibe Assets) for the scripts to run
 
## EEG BCI Scripts
This folder contains all OpenVibe Scripts necessary to run EEG BCI experiment. For in depth instructions on how to run the experiments please do not hesitate to contact us (csimon@tcd.ie)
 
### 1 EOG Acquisition
This script records 3 min of EEG activity. Two cues (arrow up and arrow down) are presented, each trial has a duration of 1 minute. One trial should record eyeblinks and the other should record eye movement (vertical and horizontal).
 
### 2 EOG Calibration
This script creates a matrix for online reduction of eye-artifacts. It is trained with the recoding from “1 EOG Acquisition”. It is necessary to provide manual input for this script to work (namely press “a” at about 30s and “b” at about 165s).
 
### 3 Restingstate
This script records 3 minutes of eyes open resting state EEG.
 
### 4 BCI Calibration
Thsi script records 30 trials (15 for each cue) of two cues (hand and crossed circle). The trial order is randomized. This is the calibration script for the CSP, LDA and therefore the BCI.
 
### 5 BCI Train CSP
This script trains the CSP for the BCI. It needs the Calibration recording (BCI Calibration) and the Eye artifact reduction matrix (EOG Calibration).
 
### 6 BCI Train LDA
This script trains the LDA for the BCI. It needs the Calibration recording (BCI Calibration) and the Eye artifact reduction matrix (EOG Calibration) and the CSP (BCI Train CSP).
 
### 7 BCI online
This script is the actual BCI, It works like the Calibration but needs the CSP, LDA and Eye artifact reduction matrix to provide Feedback.
 
### 8 BCI Replay
This script can be used to replay the recorded sessions from the online BCI (and needs the same inputs).
 
### Adapted
This script can be used to verify the input from the EEG (both channel names and noise)
 
### Channel name List
This is a text file containing the names of the channels used by the BIOSEMI Mark 2 64 Cap.
 
## TMS Scripts
This folder contains all Scripts to be used during TMS sessions. It differs from the EEG Scripts in important ways. Most significantly the way TMS-pulses are triggered. The TMS scripts trigger pulses via USB connection to the TMS device.
 
### 0 test DAQ
This Script displays live input from EMG channels recorded by the NI instruments board. The average EMG activity is displayed in red or green depending of if the average is above or below a threshold. Both duration and Threshold can be set within the script.
 
### 1 hotspotting
This script gives pulses at a certain intensity every 5-8 seconds. Intensity can be changed. After every pulse the MEPs from the two EMG channels are shown.
 
### 2 recruitment curve
This script gives 60 pulses. 6 pulses at 90, 100, 110, 120, 130, 140, 150, 160, 170, 180% of rMT in a randomized Order. After running it displays a plot of the average MEPs
 
### 3 Pre MEPs
This script delivers 20 pulses at a chosen intensity and displays the average MEPs after running.
 
### 4 MEP UP/DN
This script delivers 20 pulses at a chosen intensity. Each MEP is compared to a chosen baseline and the participant is given positive or negative feedback based on whether the individual MEP was above or below the baseline. The only difference between the up and down script is the comparison to the baseline.
 
### 5 Post MEPs
This script delivers 20 pulses at a chosen intensity and displays the average MEPs after running.
 
### Get TMS onset
This script is needed by most preceeding scripts. It determines when a TMS pulse was sent by the TMS machine. It does this by scanning the input from the machine on the “trigger” channel and gives back an index if there is a value above 4 (microvolt).
 
### Waiting room
This script is needed by the UP and DN script. If lft-ctrl is pressed during certain stages of the execution, this script is activated. This script periodically checks if lft-ctrl is pressed. If it is, the original script (UP or DN) is resumed and a new EMG baseline is taken.

## EEG Scripts
This folder contains scripts that can be used with the TMS-EEG setup. TMS-Pulses are triggered by sending a value of 4 over the NI output channel. This is registered by the EEG and TMS machine, enabling to mask the TMS pulse.
 
### 3 EEG Pre MEPs
This script delivers 20 pulses at a chosen intensity and displays the average MEPs after running.
 
### 4 EEG MEP DOWN/UP
This script delivers 20 pulses at a chosen intensity. Each MEP is compared to a chosen baseline and the participant is given positive or negative feedback based on whether the individual MEP was above or below the baseline. The only difference between the up and down script is the comparison to the baseline.
 
### 5 EEG Post MEPs
This script delivers 20 pulses at a chosen intensity and displays the average MEPs after running.
 
### Get TMS onset
This script is needed by most preceeding scripts. It determines when a TMS pulse was sent by the TMS machine. It does this by scanning the input from the machine on the “trigger” channel and gives back an index if there is a value above 4 (microvolt).
 
### Waiting room
This script is needed by the UP and DN script. If lft-ctrl is pressed during certain stages of the execution, this script is activated. This script periodically checks if lft-ctrl is pressed. If it is, the original script (UP or DN) is resumed, and a new EMG baseline is taken.
 
### Troubleshooting Document
This document contains some helpful tipps on troubleshooting some problems with the scripts.

## Information
This folder contains to logic flows that may help to understand the logic within the more complicated scripts. There is a logic flow for the Recruitement Curve and the MEP UP script.

[Readme.docx](https://github.com/Colinissimo/2-Stage-BCI/files/8716274/Readme.docx)
