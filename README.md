# DarkNews - NuMI
This repo collect the work I've done to implement NuMI into the DarkNews generator framework, and how output HEPevt files can be incorporated into the standard LArSoft/MicroBooNE reconstruction/analysis chain.

The notebook implementing_NuMI.ipynb details the workflow from generator to creating an HEPevt/hepmc3 file.

format_hepevt.ipynb and format_hepevt.py change the formatting to be readable by LArSoft and the grid. It needs to be updated to grab the weights and store the separately, added back to the analysis chain later.