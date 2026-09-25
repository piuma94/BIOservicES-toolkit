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
  recursive = TRUE
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
cf_snippet <- paste0(
  "<!-- Cloudflare Web Analytics -->",
  "<script type='module' ",
  "src='https://static.cloudflareinsights.com/beacon.min.js' ",
  "data-cf-beacon='{\"token\": ",
  "\"5d1085ae6c254261b597f6320f780dea\"}'>",
  "</script>",
  "<!-- End Cloudflare Web Analytics -->"
)



## =========================================================
## 5. Loading screen
## =========================================================

# This screen is displayed immediately while Shinylive/WebR,
# the required R packages and the model objects are loading.
#
# The progress bar is indicative rather than an exact measure
# of downloaded bytes.

loading_screen <- paste0(
  
  "<style>",
  
  "#bioservices-loader {",
  "position: fixed;",
  "inset: 0;",
  "z-index: 2147483647;",
  "background: white;",
  "display: flex;",
  "align-items: center;",
  "justify-content: center;",
  "font-family: Arial, Helvetica, sans-serif;",
  "opacity: 1;",
  "transition: opacity 0.35s ease;",
  "}",
  
  "#bioservices-loader.bioservices-hidden {",
  "opacity: 0;",
  "pointer-events: none;",
  "}",
  
  "#bioservices-loader-box {",
  "width: min(560px, 84vw);",
  "text-align: center;",
  "}",
  
  "#bioservices-loader-title {",
  "font-size: 28px;",
  "font-weight: 700;",
  "color: #263238;",
  "margin-bottom: 12px;",
  "}",
  
  "#bioservices-loader-subtitle {",
  "font-size: 17px;",
  "color: #5f6368;",
  "margin-bottom: 26px;",
  "line-height: 1.45;",
  "}",
  
  "#bioservices-progress-track {",
  "width: 100%;",
  "height: 12px;",
  "background: #e5e7eb;",
  "border-radius: 10px;",
  "overflow: hidden;",
  "}",
  
  "#bioservices-progress-bar {",
  "height: 100%;",
  "width: 12%;",
  "background: #3c6e71;",
  "border-radius: 10px;",
  "transition: width 0.6s ease;",
  "}",
  
  "#bioservices-loader-stage {",
  "margin-top: 14px;",
  "font-size: 14px;",
  "font-weight: 600;",
  "color: #3c6e71;",
  "}",
  
  "#bioservices-loader-note {",
  "margin-top: 8px;",
  "font-size: 13px;",
  "color: #737373;",
  "}",
  
  "</style>",
  
  "<div id='bioservices-loader' ",
  "role='status' aria-live='polite'>",
  
  "<div id='bioservices-loader-box'>",
  
  "<div id='bioservices-loader-title'>",
  "BIOservicES biodiversity indicator explorer",
  "</div>",
  
  "<div id='bioservices-loader-subtitle'>",
  "Preparing the interactive toolkit",
  "</div>",
  
  "<div id='bioservices-progress-track'>",
  "<div id='bioservices-progress-bar'></div>",
  "</div>",
  
  "<div id='bioservices-loader-stage'>",
  "Loading Shinylive and WebR...",
  "</div>",
  
  "<div id='bioservices-loader-note'>",
  "The first visit may take a little longer. ",
  "The toolkit runs directly in your browser.",
  "</div>",
  
  "</div>",
  "</div>"
)



## =========================================================
## 6. Loading-screen JavaScript
## =========================================================

# Shinylive displays the actual Shiny application inside an iframe.
#
# This script follows real loading milestones:
# - Shinylive starts
# - the app viewer is created
# - packages/models are initialised
# - the Shiny iframe finishes loading
#
# The percentages are therefore indicative, not exact download
# percentages.

loader_script <- paste0(
  
  "<script>",
  
  "(function() {",
  
  "const loader = ",
  "document.getElementById('bioservices-loader');",
  
  "const bar = ",
  "document.getElementById('bioservices-progress-bar');",
  
  "const stage = ",
  "document.getElementById('bioservices-loader-stage');",
  
  "const root = document.getElementById('root');",
  
  "if (!loader || !bar || !stage || !root) return;",
  
  "let finished = false;",
  "let frameAttached = false;",
  
  "function setProgress(value, text) {",
  "bar.style.width = value + '%';",
  "if (text) stage.textContent = text;",
  "}",
  
  "function finishLoader() {",
  
  "if (finished) return;",
  "finished = true;",
  
  "setProgress(100, 'Toolkit ready');",
  
  "setTimeout(function() {",
  
  "loader.classList.add('bioservices-hidden');",
  
  "setTimeout(function() {",
  "if (loader.parentNode) loader.remove();",
  "}, 400);",
  
  "}, 250);",
  
  "}",
  
  "setProgress(15, 'Loading Shinylive and WebR...');",
  
  "function attachToFrame() {",
  
  "const frame = ",
  "root.querySelector('iframe.app-frame');",
  
  "if (!frame || frameAttached) return false;",
  
  "frameAttached = true;",
  
  "setProgress(",
  "55, ",
  "'Loading R packages and model components...'",
  ");",
  
  "function inspectFrame() {",
  
  "const src = frame.getAttribute('src') || '';",
  
  "if (src && src !== 'about:blank') {",
  "setProgress(",
  "85, ",
  "'Starting the interactive toolkit...'",
  ");",
  "}",
  
  "}",
  
  "frame.addEventListener('load', function() {",
  
  "const src = frame.getAttribute('src') || '';",
  
  "if (src && src !== 'about:blank') {",
  "finishLoader();",
  "}",
  
  "});",
  
  "const frameObserver = new MutationObserver(",
  "inspectFrame",
  ");",
  
  "frameObserver.observe(",
  "frame, ",
  "{attributes: true, attributeFilter: ['src']}",
  ");",
  
  "inspectFrame();",
  
  "return true;",
  
  "}",
  
  "const rootObserver = new MutationObserver(function() {",
  
  "if (attachToFrame()) {",
  "rootObserver.disconnect();",
  "}",
  
  "});",
  
  "rootObserver.observe(",
  "root, ",
  "{childList: true, subtree: true}",
  ");",
  
  "attachToFrame();",
  
  # If loading takes a long time, reassure the user that
  # the page has not frozen.
  "setTimeout(function() {",
  
  "if (!finished) {",
  "stage.textContent = ",
  "'Still loading — the first visit can take longer.';",
  "}",
  
  "}, 25000);",
  
  "})();",
  
  "</script>"
)



## =========================================================
## 7. Export the app to HTML/Shinylive
## =========================================================

# Shinylive converts the R Shiny application into a static
# browser-based application using WebR/WebAssembly.
#
# GitHub Pages will then serve the contents of docs/.
shinylive::export(
  
  # Use the clean temporary folder instead of the whole repository.
  appdir = stage_dir,
  
  # GitHub Pages output directory.
  destdir = docs_dir,
  
  # Include WebAssembly versions of the required R packages.
  wasm_packages = TRUE,
  
  # Add page title, loading screen, loader JavaScript
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
  file.create(nojekyll_file)
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

cat(
  "\nBIOservicES Shinylive export completed.\n",
  "index.html: OK\n",
  ".nojekyll: OK\n",
  "Cloudflare Analytics: ",
  ifelse(cloudflare_ok, "OK", "NOT FOUND"),
  "\n",
  "Loading screen: ",
  ifelse(loader_ok, "OK", "NOT FOUND"),
  "\n",
  "app.json size: ",
  round(
    file.info(app_json_file)$size / 1024^2,
    1
  ),
  " MB\n\n",
  sep = ""
)

if (!cloudflare_ok) {
  stop("Cloudflare Analytics was not inserted.")
}

if (!loader_ok) {
  stop("The loading screen was not inserted.")
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