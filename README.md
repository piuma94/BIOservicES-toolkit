This repository contains the online implementation of the biodiversity indicator toolkit developed within the Horizon Europe BIOservicES project, WP3.3 (https://bioservices-project.eu/).

The toolkit explores relationships between soil biodiversity indicators and ecosystem-service indicators across different Region × Land Use contexts.

The toolkit is organised into four main pages:

**Read me**
Provides a concise description of the toolkit, including how ecosystem-service and biodiversity indicators were constructed, how the statistical models should be interpreted, and the main methodological references. It also allows users to download the main model-result as an excel table.

**What should I measure?**
Allows users to select an ecosystem service and a specific Region × Land Use context. The toolkit then identifies the biodiversity indicators associated with that ecosystem service in the selected context, distinguishing between common-slope and context-specific relationships.

**Where is my indicator relevant?**
Allows users to select an ecosystem service and a biodiversity indicator and explore where the corresponding biodiversity–ecosystem service relationship is supported. Observed data and population-level model predictions are displayed graphically together with the relevant model results.

**Predict condition**
Allows users to enter a measured biodiversity-indicator value for a selected Region × Land Use context and obtain the corresponding model-based expected ecosystem-service condition. The predicted value is compared with the observed reference distribution (33th and 66th quantiles) for that context and classified using the toolkit's relative traffic-light categories.

The statistical relationships implemented in the toolkit are based on fitted beta mixed-effects models, with a specific structure to reflect the sampling structure of our data. The model results are shown in the file and the full pipeline can be accessed on request.

Online toolkit
The toolkit is available online at:

**https://piuma94.github.io/BIOservicES-toolkit/**

The Shiny application is exported as a static Shinylive/WebR website and published online through GitHub Pages.

Repository purpose
This repository mainly contains the files required to develop, maintain, and publish the online version of the toolkit.

The complete user-oriented documentation, including information on indicators, ecosystem-service construction, model interpretation, and prediction outputs, is available directly inside the toolkit under the Read me section.

The docs/ directory contains the Shinylive export used by GitHub Pages.

**Authors**
Main authors and developer
Luigi Cao Pinna
CREA – Council for Agricultural Research and Economics
Email: luigi.caopinna@crea.gov.it

Roberta Farina
CREA – Council for Agricultural Research and Economics
Email: roberta.farina@crea.gov.it

Silvia Vanino
CREA – Council for Agricultural Research and Economics
Email: silvia.vanino@crea.gov.it

Claudia De Santis
CREA – Council for Agricultural Research and Economics
Email: claudia.desantis@crea.gov.it

**Funding**
This toolkit was developed within the BIOservicES Horizon Europe project.

**License**
Creative Commons Attribution 4.0 International

**Project website:**
https://bioservices-project.eu/

################################################################################################################ DEVELOPERS NOTES
These files are linked to the folder "C:\Users\luigi.caopinna\OneDrive - CREA\Documents\GitHub\BIOservicES-toolkit", which is syncronised with the following folder through GitHub desktop.
The toolkit pipeline is not in these files, so when developing the new pipeline, a new file should be developed and the pipeline top put the Toolkit online should be sent again

The idea is that you run the code in "02_shiny_launch_code_Toolkit_Final_DEF" to upload the toolkit online.
First we need to finalise the app, then specify the paths and show it in the correct directories. After running the Shiny launch code, then the toolkit will be converted to html,
this will allow the creation of the app files, will need to be uploaded on github, by using the desktop app.
If everythin is already settled, the .app folder is created in the same toolkit github folder, and this means that when we open github desktop then it directly update the older github online page, and hence push everything online.

This is already settled. After changing the folder files, we will then need to re-push them using the github desktop and then merge the branches, and commit it online.
After this we will be able to see the toolkit online, at the same link
