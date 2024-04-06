import os
import numpy as np
import matplotlib.pyplot as plt

# Set parameters
choredir = '/Users/alexandremorin/Downloads/GMR_SS01075@UAS_Chrimson/r_LED05_30s2x15s30s#n#n#n@100'
outdir = os.path.join(os.getcwd(), 'figures')

# Exlcusion required
Exclusion_required = True

# Extension to base exclusion on
file_extension = ".midline.dat"

# Exclusion paramters
minimum = 2
maximum = 4

# Exclusion type
method = 1

fileTypes = ['midline', 'curve', 'kink', 'x', 'y', 'bias', 'speed', 'crabspeed', 'cast']
chore = ['midline', 'cast', 'speed085', 'crabspeed']

# Get filelist
line_width = 1
full = os.listdir(choredir)
d = []

# Select directories only
for filename in full:
    if os.path.isdir(os.path.join(choredir, filename)):
        d.append(filename)
        
d.sort()

# Group genotypes
splits = [os.path.join(choredir, dirname).split('/')[-3:] for dirname in d]
for entries in splits:
    del entries[2]
splits = ['/'.join(x) for x in splits]

# Get unique elements and their indices
uname, _, nb = np.unique(splits, return_index=True, return_inverse=True)

# Plot loop
delimiter = ' '
startRow = 0
formatSpec = '%s%f%f%f%[^\n\r]'

subplot_index = 1

# Dictionary to store filenames and corresponding lines where the condition is not met
file_index_removal = dict()

if (Exclusion_required):
    for ii in range(len(uname)):
        idx = np.where(nb == ii)[0]
        for jj in idx:
            dirname = os.path.join(choredir, d[jj])
            matching_file = ""
            indexes_with_invalid_lines = []
                
            for fname in os.listdir(dirname):
                if fname.endswith(file_extension):
                    matching_file = fname
                        
            if matching_file == "":
                continue
            
            fname = os.path.join(dirname, matching_file)
            
            with open(fname, 'r') as fileID:
                dataArray = np.loadtxt(fileID, delimiter=delimiter, skiprows=startRow)
                
            if (method == 1):
                
                _, ia, ic = np.unique(dataArray[:, 1], return_index=True, return_inverse=True)
                
                animal_data = []
                for i in range(len(ia)):
                    if i == len(ia) - 1:
                        animal_data.append(dataArray[ia[i]:])
                    else:
                        animal_data.append(dataArray[ia[i]:ia[i+1]])
                        
                animal_data = np.array(animal_data)
                
                # Calculate nanmean for each animal's fourth values
                for i, animal_data in enumerate(animal_data):
                    fourth_values = animal_data[:, 3]  # Extract the fourth values for each line of information
                    nanmean = np.nanmean(fourth_values)  # Calculate the nanmean for the fourth values
                    if not (minimum <= nanmean <= maximum):  # Check if nanmean is within range
                        if i == len(animal_data) - 1:
                            indexes_with_invalid_lines.extend(range(ia[i], len(dataArray)))  # Add all indices for the last animal
                        else:
                            indexes_with_invalid_lines.extend(range(ia[i], ia[i+1]))  # Add all indices for this animal

     
            if (method == 2): 
                # Iterate through each position array in dataArray
                for idx, position_array in enumerate(dataArray):
                # Check if the 4th value is not within the given range
                    if not (minimum <= position_array[3] <= maximum):
                    # If not, add the index to the list
                        indexes_with_invalid_lines.append(idx)
                        
            file_index_removal[d[jj]] = indexes_with_invalid_lines
                
for i in range(len(chore)):
    for ii in range(len(uname)):
        idx = np.where(nb == ii)[0]
        
        # Increment subplot index in the specified order
        plt.subplot(2, 2, subplot_index)
        subplot_index += 1
                         
        et = []
        dat = []

        for jj in idx:
            dirname = os.path.join(choredir, d[jj])  # Join choredir with the directory name from d[jj]
            filename_pattern = chore[i] + ".dat"   # Construct the filename pattern
            matching_file = ""  # Initialize an empty list to store matching filenames

            # Iterate through all filenames in the directory
            for fname in os.listdir(dirname):
                # Check if the filename ends with '.dat' and starts with chore[i]
                if fname.endswith(filename_pattern):
                    matching_file = fname
                    break
                    
            if matching_file == "":
                continue
            
            fname = os.path.join(dirname, matching_file)
                    
            with open(fname, 'r') as fileID:
                dataArray = np.loadtxt(fileID, delimiter=delimiter, skiprows=startRow)
            
            _, ia, ic = np.unique(dataArray[:, 1], return_index=True, return_inverse=True)
            del_idx = np.concatenate([np.arange(ia[x], min(ia[x]+40, len(ic))) for x in range(len(ia))])
            del_idx = np.unique(del_idx)
            if len(file_index_removal) != 0:
                del_idx = np.union1d(del_idx, file_index_removal[d[jj]])
            dataArray = np.delete(dataArray, del_idx, axis=0)
            
            et.extend(dataArray[:, 2])
            dat.extend(dataArray[:, 3])

        et = np.array(et)
        dat = np.array(dat)
        et = et[dat != 0]
        dat = dat[dat != 0]

        time_bins = np.arange(0, np.ceil(max(et)) + 0.5, 0.5)
        nanarr = np.full(len(time_bins), np.nan)
        y_array = np.digitize(et, time_bins)

        if chore[i] == 'speed':
            time_win = [5, 10]
            ind = np.where((time_bins >= time_win[0]) & (time_bins <= time_win[1]))[0]
            dat_base = dat[np.isin(y_array, ind)]
            baseline = np.nanmean(dat_base)
            dat = dat / baseline
        elif chore[i] == 'speed085':
            time_win = [0, 5]
            ind = np.where((time_bins >= time_win[0]) & (time_bins <= time_win[1]))[0]
            dat_base = [np.nanmean(dat[np.isin(y_array, ind[x])]) for x in range(10)]
            baseline = np.nanmean(dat_base)
            dat = dat / baseline

        seri = np.array([np.nanmean(dat[y_array == i]) for i in range(1, len(time_bins)+1)])
        if np.isnan(seri[0]):
            seri[0] = 0
        nanarr[:len(seri)] = seri
        seri = nanarr

        p = plt.plot(time_bins, seri, linewidth=line_width)
        plt.draw()
        plt.pause(0.001)
        
        sem, _ = np.histogram(et, bins=time_bins, weights=(dat/len(dat))**2)
        sem = np.sqrt(sem)
        
        fileName = uname[ii].replace('/', '@')
        plt.ylabel(chore[i])
        plt.xlabel('Time (s)')
        plt.box(False)
        
        if not os.path.isdir(outdir):
            os.makedirs(outdir)
        
        outname = fileName + '@' + chore[i]
        filepath = os.path.join(outdir, outname)

plt.legend(["attp2", "2064", "918", "863", "883", "660", "1075"], loc='lower right', fontsize=7)
plt.gcf().set_facecolor('lightgrey')  # Set background color of the entire figure
plt.show()

input("Jay is: ")

