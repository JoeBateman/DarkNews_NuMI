import numpy as np

input_file = 'output_files/NuMI/HEPevt.dat'
output_file = 'output_files/NuMI/HEPevt_fmt.txt'

# Read the input file\
with open(input_file, 'r') as f:
    data = f.readlines()
    arr_filted = [list(filter(None, str_list)) for str_list in np.char.split(np.char.strip(data), " ")]

# First split into events
# Define the length condition
length_condition = 3  # Length of the event declaration line in HEPevt files. Eg: E, 0, 7,  for event 0 with 7 particles

# Group arrays into events based on the length condition
events = []
current_event = []

for i, arr in enumerate(arr_filted):
    if len(arr) == length_condition:
        if len(current_event)>0:
            events.append(current_event)
        current_event = []
    current_event.append(arr)
# Catching the last entry!
if len(current_event)>0:
    events.append(current_event)

particle_len = 15 # Len of output array for each particle

events_formatted = []
for event in events:
    
    header = event[0][1:]
    events_formatted.append(header)
    particles = event[1:]
    particles_starts = particles[::2]

    particles_ends = particles[::2]

    for i in range(len(particles_starts)):
        particle_features = particles_starts[i] + particles_ends[i]
        events_formatted.append(particles_starts[i] + particles_ends[i])

with open(output_file, 'w') as f:
    j=0
    for event in events_formatted:
        j+=1
        for line in event:

            f.write(line + '    ')
        if j<len(events_formatted):
            f.write('\n') 