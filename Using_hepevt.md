# Getting hepevt integrated with LArSoft

The purpose of this file is to explain how to get from a HEPevt file to a fully reconstructed overlay event. It is a work in progress, so please let me know if there are any issues, and I will endeavour to update this regularly as I develop the workflow.

This would not have been possible without the tutorial made by Guanqun, [docdb 38163](https://microboone-docdb.fnal.gov/cgi-bin/sso/RetrieveFile?docid=38163), which I will generally follow along with additional things I've learned along the way.

NOTE TO SELF: CMD-K-V gives a markdown preview

## Getting started
You'll first want one or more hepevt files to work with, which I walk through in implementing_NuMI.ipynb. The [darknews repo](https://github.com/mhostert/DarkNews-generator) also has some Example Notebooks which you can adapt and run yourself, if you don't have access to the necessary NuMI flux files and want to get started (Example 4 for instance implements the MicroBooNE geometry for the BNB).

You'll also need an SL7 environment and an instance of uboonecode running. At the time of writing, v08_00_00_84 is the latest production version, and is used here. To setup a basic uboonecode instance, you can:

1. Create an SL7 container `source /cvmfs/uboone.opensciencegrid.org/bin/shell_apptainer.sh`
2. Set up uboone MCC9 `source /grid/fermiapp/products/uboone/setup_uboone_mcc9.sh`
3. Use ups to get a version of uboonecode `setup uboonecode v08_00_00_84 -q e17:prof`. Generally, the stable release always has `e17:prof`, so is fine to default to if in doubt. 

This can also be combined into a single script, such as the one in `./tools/setup_env.sh` (note that SL7 is set up separately).

## Preparing your files

For whatever reason, the formatting of hepevt by darknews does not match how LArSoft is expecting it to be implemented. In `tools/format_hepevt.py`, you can choose your input/output filenames and paths. Its very rudimentary, and assumes each event contains the same number of particles (which is the case for DarkNews) and currently ignores the event weight. This is a feature I want to develop in future.

## Getting grid-ready

Theres one more step to making your hepevt files ready for using in jobs. The file `tools/splitHEPevtfile.sh` splits the HEPevt file into batches, which should match the events per job of your xml. For this example, 10 events are processed in each job, and is consistent between xml/sh/fcl files.

In `splitHEPevtfile.sh`, you specify the batch size, in/out file locations, and how long each event is -  this will be # of particles + 1 (for the header line). Make sure your output location is grid-readable, such as pnfs/uboone/{persistent/resilient/scratch} (note scratch is temporary). 

Once configured, call `. splitHEPevtfile.sh` to move the batched-HEPevt and other files to your desired location and you're nearly ready to go!

# Simple detector simulation/reconstruction

1. One can use `xmls/sim_only_darknews` to get started. This should take minimal configuration, just make sure your `<inputlist>` is pointing to the right place, and `prod_hepevt_LArTPCActive_v1.0.fcl` exists where your specify. 
2. Check the number of jobs and events matches the number of batches/batch size!
    1. Number of events = number of jobs * max files * batch size (specified in `splitHEPevtfile.sh`)
3. You should be ready to submit now! Use the project.py command `project.py --xml sim_only_darknews.xml --stage genall --clean --submit`
    1. The command `--clean` will remove and files in the output folders specified. Make sure to back up anything you don't want to lose before using it. Its not actually necessary as long as the destination folders are empty, so going manual could be more secure!
    2. Once run successfully,  `project.py --xml sim_only_darknews.xml --stage genall --check` can be used to make sure everything worked as expected, and to generate the files.list file. This is used by subsequent xml stages, so its not strictly needed here. 
    3. The tool `tools/filelist_generator.sh` can also generate the files.list file when configured for your xml/stage. You can also use it to move the raw artroot files from scratch to persistent or another location.

# Getting overlay

Unfortunately, getting overlay working is a tad more complicated, and the steps here are more of a work-in-progress.


