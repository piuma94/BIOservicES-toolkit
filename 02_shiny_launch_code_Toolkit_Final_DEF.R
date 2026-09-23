#install.packages(c("shinylive", "httpuv")) ## pacchetti per convertire il tutto in html

repo_dir <- "C:/Users/luigi.caopinna/OneDrive - CREA/Documents/GitHub/BIOservicES-toolkit"

####### export the files 
shinylive::export(
  appdir = repo_dir,
  destdir = file.path(repo_dir, "docs"),
  wasm_packages = TRUE ## this is to have the possibility of reading R packages in the browser
)



## 2. Add Cloudflare Web Analytics
index_file <- file.path(repo_dir, "docs", "index.html")

cf_snippet <- paste0(
  "<!-- Cloudflare Web Analytics -->",
  "<script type='module' ",
  "src='https://static.cloudflareinsights.com/beacon.min.js' ",
  "data-cf-beacon='{\"token\": \"5d1085ae6c254261b597f6320f780dea\"}'>",
  "</script>",
  "<!-- End Cloudflare Web Analytics -->"
)

html <- paste(
  readLines(index_file, warn = FALSE),
  collapse = "\n"
)

if (!grepl(
  "static.cloudflareinsights.com/beacon.min.js",
  html,
  fixed = TRUE
)) {
  
  html <- sub(
    "</body>",
    paste0(cf_snippet, "\n</body>"),
    html,
    fixed = TRUE
  )
  
  writeLines(
    html,
    index_file,
    useBytes = TRUE
  )
}

####### github page files 
# crea .nojekyll DOPO l'export
file.create(file.path(repo_dir, "docs", ".nojekyll")) # these are some needed file to be read by the github online

# controlli
file.exists(file.path(repo_dir, "docs", "index.html"))
file.exists(file.path(repo_dir, "docs", ".nojekyll"))

# test locale - questa riga blocca R finché non chiudi il server
httpuv::runStaticServer(
  file.path(repo_dir, "docs")
)
