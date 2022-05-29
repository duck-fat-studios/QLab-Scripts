-- Cuepoints importer Version b1.0
-- Eric Boxer
-- Duck Fat Studios, LLC
-- eric@duckfatstudios.com

display dialog "This script creates Timeline cues that start an audio track and then fire lighting cues via OSC based on the cues offset time. You have the option for Hog 4, MA 3, or Eos lighting cues. The script should prompt you through the process.

 Please keep in mind this script is in beta, so some things probably will need tweaking.

 if you have any questions please reach out to me at eric@duckfatstudis.com

 Version b1.0"


tell application id "com.figure53.QLab.4" to tell front workspace
	
	set DELIM to {","}
	set lastCueNumber to ""
	set currentGroupID to ""
	set currentCueId to ""
	set lightingOSCPatch to 0
	set lightingCueOSCType to ""
	set addAudioTracksToGroupsDialog to "No"
	set newCuelistName to ""
	
	-- First Prompts
	
	set acsv to choose file with prompt "Please select a Cue Points CSV" of type "csv"
	--set newCuelistName to the text returned of (display dialog "If you would like to create a new cuelist enter a name for it here, otherwise leave it blank to create the groups in the current cuelist" default answer "")
	set addAudioTracksToGroupsDialog to the button returned of (display dialog "Do you want to add audio tracks to each group?" buttons {"Yes", "No"} default button "Yes")
	
	-- If we want to add audio to the groups select the folder where the audio files live
	if addAudioTracksToGroupsDialog = "Yes" then
		set audioFolderPath to the POSIX path of (choose folder with prompt "Please select audio Folder Path")
	end if
	
	
	set csvList to read acsv using delimiter linefeed
	set {TID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, DELIM}
	
	
	
	
	repeat with arow in csvList
		
		set loadAudioFile to true
		set ritems to text items of arow
		if item 1 of ritems is not "Track Number" then
			-- check if this is the current cue number. If not create a group cue and update the last cue
			if item 9 of ritems is not equal to lastCueNumber then
				
				set groupName to item 2 of ritems
				set groupNumber to item 9 of ritems
				
				
				
				
				-- Create the group Cue
				make type "Group"
				set thisCue to last item of (selected as list)
				set q name of thisCue to groupName
				set q number of thisCue to groupNumber
				-- Set to timeline mode
				set mode of thisCue to timeline
				set currentGroupID to uniqueID of thisCue
				set lastCueNumber to item 9 of ritems
				
				
				-- If we want to add Audio files to the group we do that here
				
				if addAudioTracksToGroupsDialog = "Yes" then
					
					try
						set filePathPosix to POSIX file (audioFolderPath & groupName & ".wav") as alias
					on error
						display dialog "Could not assign an audio file to " & groupName
						set loadAudioFile to false
					end try
					
					make type "Audio"
					set newCue to last item of (selected as list)
					set newCueId to uniqueID of newCue
					set q name of newCue to groupName
					
					if loadAudioFile = true then
						set file target of newCue to filePathPosix
					end if
					move cue id newCueId of parent of newCue to end of cue id currentGroupID
				end if
				
			end if
			
			if item 4 of ritems = "Lighting" then
				
				if lightingCueOSCType = "" then
					set lightingCueOSCType to the button returned of (display dialog "Which Lighing Console?" buttons {"Eos", "Hog 4", "MA 3"} default button 1)
				end if
				
				if lightingOSCPatch = 0 then
					set lightingOSCPatch to text returned of (display dialog "What is your Network Patch?" default answer "1") as integer
					
				end if
				
				
				-- We're assuming lighting cues are triggered by OSC
				make type "network"
				set newCue to last item of (selected as list)
				set newCueId to uniqueID of newCue
				set q name of newCue to item 7 of ritems
				
				
				-- Set the network patch. If the patch is invalid it will automatically set it to 1
				try
					set patch of newCue to (lightingOSCPatch)
				on error errStr number errorNumber
					
					display dialog "There was an issue setting the network patch. All lighting cues will be set to patch 1." with icon caution
					set lightingOSCPatch to 1
					
				end try
				
				
				-- Create Eos Lighting Cues
				if lightingCueOSCType = "Eos" then
					set custom message of newCue to "/eos/cue/" & item 9 of ritems & "/" & item 11 of ritems & "/fire"
					
					-- Create The Hog 4 Lighting Cues
				else if lightingCueOSCType = "Hog 4" then
					set custom message of newCue to "/hog/playback/go/0/" & item 9 of ritems & "." & item 11 of ritems
					
					-- Create MA3 Lighting Cues
				else if lightingCueOSCType = "MA 3" then
					set custom message of newCue to "/gma3/cmd \"Go Sequence " & item 9 of ritems & " Cue " & item 11 of ritems & "\""
				end if
				
				-- set the pre wiat of time offset for the q
				set pre wait of newCue to my timeToNumber(item 6 of ritems)
				
				-- move the cue into the timeline group
				move cue id newCueId of parent of newCue to end of cue id currentGroupID
			end if
		end if
	end repeat
	
	
	set AppleScript's text item delimiters to TID
	
	
	
end tell

on timeToNumber(tme)
	--set timeArray to 
	set myTime to split(tme, ":")
	set timeHours to item 1 of myTime as number
	set timeMinutes to item 2 of myTime as number
	set timeSeconds to item 3 of myTime as number
	
	return (timeSeconds + (timeMinutes * 60) + (timeHours * 60 * 60))
end timeToNumber


on split(textString, theDelim)
	set oldDelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelim
	set theArray to every text item of textString
	set AppleScript's text item delimiters to oldDelim
	return theArray
end split
