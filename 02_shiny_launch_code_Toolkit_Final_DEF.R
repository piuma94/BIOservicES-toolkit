## =========================================================
## BIOservicES TOOLKIT
## Shinylive export + loading screen + Cloudflare Analytics
## =========================================================

# Install only once if needed:
# install.packages(c("shinylive", "httpuv"))


## =========================================================
## 1. Define the local GitHub repository folder
## =========================================================

# Local folder tracked by GitHub Desktop.
repo_dir <- paste0(
  "C:/Users/luigi.caopinna/OneDrive - CREA/",
  "Documents/GitHub/BIOservicES-toolkit"
)

# GitHub Pages publishes this folder.
docs_dir <- file.path(repo_dir, "docs")



## =========================================================
## 2. Select only the files required by the online app
## =========================================================

# These are the files that the browser-based Shiny application
# actually needs at runtime.
#
# README.md, License.txt, the launcher itself and df_shiny.Rda
# do not need to be included inside app.json.

runtime_files <- c(
  "app.R",
  "df_shiny.rds",
  "shiny_model_bundle.rds",
  "model_intercepts_region_lu.xlsx",
  "multifunctionality_region_lu_indicator_sign_set.xlsx"
)

# Stop immediately if one of the required files is missing.
missing_files <- runtime_files[
  !file.exists(file.path(repo_dir, runtime_files))
]

if (length(missing_files) > 0) {
  
  stop(
    "Missing required app files:\n- ",
    paste(missing_files, collapse = "\n- ")
  )
}



## =========================================================
## 3. Create a temporary clean app folder
## =========================================================

# Shinylive will export from this temporary folder instead of
# exporting every file stored in the GitHub repository.
#
# Nothing needs to be moved manually.

stage_dir <- file.path(
  tempdir(),
  "BIOservicES_shinylive_app"
)

# Remove an old temporary copy if present.
if (dir.exists(stage_dir)) {
  
  unlink(
    stage_dir,
    recursive = TRUE,
    force = TRUE
  )
}

dir.create(
  stage_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Copy only the files required by the app.
copied <- file.copy(
  from = file.path(repo_dir, runtime_files),
  to = file.path(stage_dir, runtime_files),
  overwrite = TRUE
)

if (!all(copied)) {
  
  stop(
    "Could not copy all required files ",
    "to the temporary Shinylive folder."
  )
}



## =========================================================
## 4. Cloudflare Web Analytics
## =========================================================

# Cloudflare Web Analytics beacon.
#
# This only collects website-traffic analytics.
# It does not modify the Shiny app, statistical models
# or predictions.

cf_snippet <- r"(
<!-- Cloudflare Web Analytics -->
<script
  type="module"
  src="https://static.cloudflareinsights.com/beacon.min.js"
  data-cf-beacon='{"token":"5d1085ae6c254261b597f6320f780dea"}'>
</script>
<!-- End Cloudflare Web Analytics -->
)"



## =========================================================
## 5. Custom loading screen
## =========================================================

# The loading screen is shown immediately.
#
# It remains above the native Shinylive/WebR loader until
# the actual Shiny user interface is detected inside the iframe.
#
# The percentage is indicative. It represents loading stages,
# not an exact percentage of downloaded bytes.

loading_screen <- r"(

<style>

#bioservices-loader {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: Arial, Helvetica, sans-serif;
  opacity: 1;
  transition: opacity 0.40s ease;
}

#bioservices-loader.bioservices-hidden {
  opacity: 0;
  pointer-events: none;
}

#bioservices-loader-box {
  width: min(560px, 84vw);
  text-align: center;
}

#bioservices-loader-title {
  font-size: 28px;
  font-weight: 700;
  color: #263238;
  margin-bottom: 10px;
}

#bioservices-loader-subtitle {
  font-size: 17px;
  color: #5f6368;
  margin-bottom: 25px;
  line-height: 1.45;
}

#bioservices-progress-track {
  width: 100%;
  height: 12px;
  background: #e5e7eb;
  border-radius: 10px;
  overflow: hidden;
}

#bioservices-progress-bar {
  height: 100%;
  width: 12%;
  background: #3c6e71;
  border-radius: 10px;
  transition: width 0.7s ease;
}

#bioservices-loader-stage {
  margin-top: 14px;
  font-size: 14px;
  font-weight: 600;
  color: #3c6e71;
}

#bioservices-loader-percent {
  margin-top: 5px;
  font-size: 13px;
  color: #5f6368;
}

#bioservices-loader-note {
  margin-top: 12px;
  font-size: 13px;
  line-height: 1.45;
  color: #737373;
}

</style>


<div
  id="bioservices-loader"
  role="status"
  aria-live="polite"
>

  <div id="bioservices-loader-box">

    <div id="bioservices-loader-title">
      BIOservicES biodiversity indicator explorer
    </div>

    <div id="bioservices-loader-subtitle">
      Preparing the interactive toolkit
    </div>

    <div id="bioservices-progress-track">

      <div id="bioservices-progress-bar"></div>

    </div>

    <div id="bioservices-loader-stage">
      Loading Shinylive and WebR...
    </div>

    <div id="bioservices-loader-percent">
      12%
    </div>

    <div id="bioservices-loader-note">
      The first visit may take a little longer.
      The toolkit runs directly in your browser.
    </div>

  </div>

</div>

)"



## =========================================================
## 6. Loading-screen JavaScript
## =========================================================

# IMPORTANT:
#
# The old version removed the custom loader when the Shinylive
# iframe fired its normal "load" event.
#
# However, the iframe can finish loading before WebR, R packages,
# model objects and the Shiny interface are actually ready.
#
# This version therefore:
#
# 1. waits for the Shinylive iframe;
# 2. lets WebR continue loading behind the custom screen;
# 3. periodically inspects the iframe;
# 4. detects the actual BIOservicES Shiny interface;
# 5. removes the loader only when the app UI is available.
#
# If iframe inspection is unavailable in a particular browser,
# a conservative fallback is used after the iframe has loaded.


loader_script <- r"(

<script>

(function () {

  const loader =
    document.getElementById("bioservices-loader");

  const bar =
    document.getElementById("bioservices-progress-bar");

  const stage =
    document.getElementById("bioservices-loader-stage");

  const percent =
    document.getElementById("bioservices-loader-percent");


  if (!loader || !bar || !stage || !percent) {
    return;
  }


  const startTime = Date.now();

  let finished = false;

  let currentProgress = 12;

  let appFrame = null;

  let frameLoadedAt = null;

  let iframeAccessible = true;


  // ---------------------------------------------------------
  // Progress-bar helper
  // ---------------------------------------------------------

  function setProgress(value, text) {

    value = Math.max(
      currentProgress,
      Math.min(100, Math.round(value))
    );

    currentProgress = value;

    bar.style.width = value + "%";

    percent.textContent = value + "%";

    if (text) {
      stage.textContent = text;
    }
  }



  // ---------------------------------------------------------
  // Finish the loading screen
  // ---------------------------------------------------------

  function finishLoader() {

    if (finished) {
      return;
    }

    finished = true;

    setProgress(
      100,
      "Toolkit ready"
    );

    // Keep the 100% state visible briefly.
    setTimeout(function () {

      loader.classList.add(
        "bioservices-hidden"
      );

      // Remove loader from DOM after fade-out.
      setTimeout(function () {

        if (loader.parentNode) {
          loader.remove();
        }

      }, 450);

    }, 500);
  }



  // ---------------------------------------------------------
  // Check whether the real Shiny UI is visible
  // ---------------------------------------------------------

  function checkAppReady(frame) {

    try {

      const frameDocument =
        frame.contentDocument ||
        frame.contentWindow.document;

      if (!frameDocument ||
          !frameDocument.body) {

        return false;
      }


      // Text currently rendered inside the Shiny iframe.
      const bodyText = (
        frameDocument.body.innerText ||
        frameDocument.body.textContent ||
        ""
      )
        .replace(/\s+/g, " ")
        .trim();


      // Very specific markers from the BIOservicES interface.
      //
      // Finding any of these means the actual Shiny UI has
      // been created and we are no longer looking only at
      // Shinylive's native loading animation.

      const bioservicesMarkers = [

        "What should I measure?",

        "Where is my indicator relevant?",

        "Predict condition"

      ];


      const markerFound =
        bioservicesMarkers.some(
          function (marker) {
            return bodyText.includes(marker);
          }
        );


      // Generic Shiny fallback:
      // once Shiny has bound inputs/outputs and substantial
      // page content exists, the UI can also be considered ready.

      const shinyElement =
        frameDocument.querySelector(
          ".shiny-bound-input, " +
          ".shiny-bound-output, " +
          ".nav-tabs, " +
          ".tab-content"
        );


      const genericShinyReady =
        Boolean(shinyElement) &&
        bodyText.length > 200;


      return (
        markerFound ||
        genericShinyReady
      );

    } catch (error) {

      // Some iframe configurations can prevent direct inspection.
      // In that case we use the fallback timing below.

      iframeAccessible = false;

      return false;
    }
  }



  // ---------------------------------------------------------
  // Attach monitoring to the Shinylive iframe
  // ---------------------------------------------------------

  function attachFrame(frame) {

    if (appFrame) {
      return;
    }

    appFrame = frame;

    setProgress(
      45,
      "Preparing the browser-based R environment..."
    );


    // IMPORTANT:
    // iframe "load" no longer means "toolkit ready".
    //
    // It only tells us that the iframe itself has loaded.

    frame.addEventListener(
      "load",
      function () {

        frameLoadedAt = Date.now();

        setProgress(
          65,
          "Loading R packages and model components..."
        );

      }
    );


    // The iframe may already have fired "load" before the
    // event listener was attached. In that situation we still
    // start checking its contents immediately.

    try {

      if (
        frame.contentDocument &&
        frame.contentDocument.readyState === "complete"
      ) {

        frameLoadedAt = Date.now();

        setProgress(
          65,
          "Loading R packages and model components..."
        );
      }

    } catch (error) {

      iframeAccessible = false;
    }



    // -------------------------------------------------------
    // Check app readiness every 400 milliseconds
    // -------------------------------------------------------

    const readinessTimer =
      setInterval(function () {

        if (finished) {

          clearInterval(readinessTimer);

          return;
        }


        const elapsed =
          Date.now() - startTime;


        // Slowly advance the indicative bar while WebR works.
        //
        // It never reaches 100 until the real UI is detected.

        if (elapsed > 3000) {

          setProgress(
            70,
            "Loading R packages and model components..."
          );
        }


        if (elapsed > 7000) {

          setProgress(
            78,
            "Initialising statistical model objects..."
          );
        }


        if (elapsed > 12000) {

          setProgress(
            85,
            "Starting the interactive toolkit..."
          );
        }


        if (elapsed > 20000) {

          setProgress(
            90,
            "Finalising the toolkit..."
          );
        }


        if (elapsed > 35000) {

          setProgress(
            94,
            "Still loading - the first visit can take longer."
          );
        }


        // Actual readiness check.
        if (
          iframeAccessible &&
          checkAppReady(frame)
        ) {

          clearInterval(readinessTimer);

          finishLoader();

          return;
        }


        // ---------------------------------------------------
        // Fallback for browsers where iframe inspection
        // is blocked.
        // ---------------------------------------------------
        //
        // In that case wait 15 seconds after the iframe itself
        // has completed loading before revealing it.
        //
        // Normally this fallback should not be needed on
        // GitHub Pages because the app is served from the same
        // site.

        if (
          !iframeAccessible &&
          frameLoadedAt !== null &&
          Date.now() - frameLoadedAt > 15000
        ) {

          clearInterval(readinessTimer);

          finishLoader();

          return;
        }

      }, 400);

  }



  // ---------------------------------------------------------
  // Search for the Shinylive application iframe
  // ---------------------------------------------------------

  setProgress(
    15,
    "Loading Shinylive and WebR..."
  );


  const frameSearchTimer =
    setInterval(function () {

      if (finished) {

        clearInterval(
          frameSearchTimer
        );

        return;
      }


      const frame =
        document.querySelector(
          "iframe.app-frame"
        ) ||
        document.querySelector(
          "#root iframe"
        );


      if (frame) {

        clearInterval(
          frameSearchTimer
        );

        attachFrame(frame);
      }

    }, 100);



  // ---------------------------------------------------------
  // Long-loading reassurance
  // ---------------------------------------------------------

  setTimeout(function () {

    if (!finished) {

      stage.textContent =
        "Still loading - please keep this page open.";

    }

  }, 45000);


})();

</script>

)"



## =========================================================
## 7. Export the app to HTML/Shinylive
## =========================================================

# Shinylive converts the R Shiny application into a static
# browser-based application using WebR/WebAssembly.
#
# GitHub Pages then serves the contents of docs/.

shinylive::export(
  
  # Use the clean temporary folder instead of the whole repository.
  appdir = stage_dir,
  
  # GitHub Pages output directory.
  destdir = docs_dir,
  
  # Include WebAssembly versions of the required R packages.
  wasm_packages = TRUE,
  
  # Add page title, loading screen, loading JavaScript
  # and Cloudflare analytics to the generated index.html.
  template_params = list(
    
    title =
      "BIOservicES biodiversity indicator explorer",
    
    include_before_body =
      loading_screen,
    
    include_after_body =
      paste0(
        loader_script,
        cf_snippet
      )
  )
)



## =========================================================
## 8. Remove temporary app folder
## =========================================================

# Everything needed has now been written to docs/,
# so the temporary folder is no longer needed.

unlink(
  stage_dir,
  recursive = TRUE,
  force = TRUE
)



## =========================================================
## 9. Create the .nojekyll file for GitHub Pages
## =========================================================

nojekyll_file <- file.path(
  docs_dir,
  ".nojekyll"
)

if (!file.exists(nojekyll_file)) {
  
  file.create(
    nojekyll_file
  )
}



## =========================================================
## 10. Final checks
## =========================================================

index_file <- file.path(
  docs_dir,
  "index.html"
)

app_json_file <- file.path(
  docs_dir,
  "app.json"
)


# Essential files.
stopifnot(
  
  file.exists(index_file),
  
  file.exists(nojekyll_file),
  
  file.exists(app_json_file)
  
)


# Read generated HTML.
index_html <- paste(
  
  readLines(
    index_file,
    warn = FALSE
  ),
  
  collapse = "\n"
)


# Check Cloudflare.
cloudflare_ok <- grepl(
  
  "static.cloudflareinsights.com/beacon.min.js",
  
  index_html,
  
  fixed = TRUE
)


# Check loading screen.
loader_ok <- grepl(
  
  "bioservices-loader",
  
  index_html,
  
  fixed = TRUE
)


# Check the new readiness-detection code.
readiness_check_ok <- grepl(
  
  "What should I measure?",
  
  index_html,
  
  fixed = TRUE
)


cat(
  
  "\nBIOservicES Shinylive export completed.\n",
  
  "index.html: OK\n",
  
  ".nojekyll: OK\n",
  
  "Cloudflare Analytics: ",
  ifelse(
    cloudflare_ok,
    "OK",
    "NOT FOUND"
  ),
  
  "\n",
  
  "Custom loading screen: ",
  ifelse(
    loader_ok,
    "OK",
    "NOT FOUND"
  ),
  
  "\n",
  
  "App readiness detection: ",
  ifelse(
    readiness_check_ok,
    "OK",
    "NOT FOUND"
  ),
  
  "\n",
  
  "app.json size: ",
  round(
    file.info(app_json_file)$size /
      1024^2,
    1
  ),
  
  " MB\n\n",
  
  sep = ""
)


if (!cloudflare_ok) {
  
  stop(
    "Cloudflare Analytics was not inserted."
  )
}


if (!loader_ok) {
  
  stop(
    "The loading screen was not inserted."
  )
}


if (!readiness_check_ok) {
  
  stop(
    "The application-readiness detection code was not inserted."
  )
}



## =========================================================
## 11. Test locally
## =========================================================

# Open the generated GitHub Pages website locally.
#
# The R console remains occupied until the server is stopped.
# Press Esc or Ctrl+C to stop it.
#
# Cloudflare statistics should be checked using the PUBLIC
# GitHub Pages URL rather than localhost.

httpuv::runStaticServer(
  docs_dir
)