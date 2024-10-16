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

1. The file `xmls/overlay_darknews.xml` is the template to get started with. 
    1. You also need to ensure your fcls are where you define them, in this case being `DarkNews_AddOverlay_batch_{LOCAL/TEMPLATE}.fcl`. 
    2. Make sure the timing information matches the beam your simulation uses, such as global offset! 
2. The `splitHEPevtfile.sh` script also creates a .tar version of your hepevt files in the same output directory. This is what you'll use as an input for your workflow, and is specified in `<jobsub>` and `tools/unzip_test_script.sh`.
    1. Make sure the path/names are what you expect!
3. You'll also need to specify the overlay samdef that you want to use! A few are specified in the xml. 
    1. You'll probably want a small file, and some useful tutorials to create your own can be found [here](https://microboone-exp.fnal.gov/at_work/AnalysisTools/data/ub_datasets_optfilter.html) and [here](https://cdcvs.fnal.gov/redmine/projects/uboonecode/wiki/Sam#Making-SAM-dataset-definitions-from-existing-dataset-definitions)
    2. Make sure the EXT you use matches your other configs!
4. To create the initial overlay file, you use project.py again: `project.py --xml overlay_darknews.xml --stage hepevt_art --submit`
    1. This only converts your hepevt into an artroot file with overlay, so you need to subsequent stages to do g4 propagation, detector sim, and reconstruction.
    2. You'll need to run `--check` and/or  `tools/filelist_generator.sh` to create the `files.list` file, and make sure the subsequent stages point to the correct list! This will generally be the name of the previous stage (ie for `reco1`, point to `hepevt_art`, `reco2` looking at `reco1`)
5. Once `files.list` exists, you can submit `project.py --xml overlay_darknews.xml --stage reco1 --submit` to do the first stage of reconstruction. 
    1. The filepath to the list should be defined in `<inputlist>`. 
    1. The specific fcls will depend on whether your using NuMI or BNB, but the stage is shared by WireCell, Pandora and DL reco.
    1. Again, you will need to run `--check` and/or  `tools/filelist_generator.sh`. For the generator, make sure to specify what stage you're looking to move, and be sure where you're moving the artroot files to!
6. For `reco2`, your workflow will depend on the reconstruction paradigm you want to use! Currently, WireCell has not been working for me, but pandora reco2 has run without issue
    1. You may want an additonal `ntuple` stage to convert from artroot to a root file you can use with your analysis. The PeLEE ntuple fcl is very popular, eg `run_neutrinoselectionfilter_run1_data.fcl`.
    2. To check everything has worked as expected, you may want to use these artroot files to check how your workflow has gone. The steps for this are given in the next section.


## Getting an EventDisplay running!
Event displays are really neat to look at, and they can help you work out whats going right/wrong with your workflow.

I have found David's gallery to be the best of the bunch to get working. You'll need to set up a [VNC](https://sbnsoftware.github.io/sbndcode_wiki/Viewing_events_remotely_with_VNC.html) and clone [David's repo](https://github.com/davidc1/gallery-framework)

Additionally, I define a script to do the following in the Gallery directory:

```
source config/setup.sh 
python config/change_ld_library_path.py
source config/change_ld_library_path.sh
alias evd='evd.py -T
```

Once configured, in a new VNC session you should:
1. Open the terminal and set up `SL7`, `uboonecode`, and call `setup.sh` in the Gallery directory.
2. Navigate to the location of the artroot file and use `evd *name of your file*.root` to open the event dispaly. I've found that the gallery runs into issues drawing the file if you don't open the file using evd in the terminal (ie using the "select a file" feature instead lead to errors).
