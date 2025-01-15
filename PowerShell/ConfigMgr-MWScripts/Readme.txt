NOTE: This is a collection of scripts and work from different locations/people.
If you identify one as your script, and wish it taken down, please send me a message.

Window_Source.csv:
This holds the "master" data that will be used throughout the process.  


CollectionID:
The Unique collection ID


Patch_Bucket: 
This is only used to name to maintenance windows.


PlusDays: 
Based on Patch Tuesday.  
+6 = Monday, +11 = Saturday, etc… 
Negative values do work: -1 = Monday before Patch Tuesday.


StartHour:
24 hour format. Cannot exceed a value of 23.


StartMinute:
Limited to 59 minutes. Anything over will add one hour and all else will be ignored.  
Ex: 61 = 1 hour, no minutes.


HourDuration: 
Number of hours to open the window.  24 limitation imposed by SCCM
MinuteDuration - Limited to 59 minutes.  Anything over will add one hour and all else will be ignored.  
Ex: 61 = 1 hour, no minutes.


The resultant maintenance window will be in this format:
Window Name - $CollectionName $Month $Year
Description – Occurs on mm/dd/yyyy  at HH:MM AM/PM