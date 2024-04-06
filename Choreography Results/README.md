Edited the old choreography results code to include the option to exclude data points for analysis based on midline data. 
Also transferred the Matlab code into Python, however this code runs distinguishbly slower than the Matlab code. 
This being said, it could be useful to give to new undergrads coming in the lab if they want to make modifications, 
being that Python is the language used in beginner programming classes. This code can also be changed very easily by changing 
the variable "file_extension" to exclude based on another attribute. Furthermore, there is an option to avoid doing any 
exclusion by changing the variable named "exclusion_required" to false.

There are two options for exclusion of data. These two options are controlled by setting the variable named "exclusion_type" 
to the desired integer. Here are the differences between both.

1: Excludes all data points of a given tracked larvae ID whose average of the selected attribute does not fall within the given range.
2: Excludes all data points whose selected attribute at that given time does not fall within the given range. 

The range that is being investigated by the code can easily be manipulated by changing the variables labelled "minimum" and "maximum."

